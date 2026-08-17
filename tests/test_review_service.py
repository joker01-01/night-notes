from __future__ import annotations

from datetime import date, timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import Base
from app.llm.providers import ChatMessage
from app.models import DailySession, QA, QAType, SessionStatus
from app.services.review_service import (
    FREE_WRITE_QUESTION,
    answer_followup,
    create_session_if_needed,
    deepen_followup,
    recent_summary_context,
    reset_for_recoach,
    restore_summary,
    save_answers,
    session_to_schema,
    start_followup,
    summarize_session,
    _fixed_material_lines,
)
from app.services.report_service import aggregate_day_traces


class FakeProvider:
    """不联网的 Provider，用于验证自问与收束流程。"""

    def __init__(self) -> None:
        self.prompts: list[str] = []
        self.systems: list[str] = []

    def chat(self, messages: list[ChatMessage]) -> str:
        system = next((item["content"] for item in messages if item["role"] == "system"), "")
        user = messages[-1]["content"]
        self.systems.append(system)
        self.prompts.append(user)
        if "把今晚没说清的话问回自己" in system:
            if "第 2 轮" in user:
                return "你说『挂出商品』——今晚具体先整理哪 3 件旧物的标题和定价？"
            return "你写『继续推进闲鱼』——明天 30 分钟内你要完成的第一个可验证动作是什么？"
        return (
            '{"overview":"完成了核心工作",'
            '"attribution":"卡在动作未拆解，停留在意向层",'
            '"next_action":"明天挂出3个测试商品并记录是否有人咨询",'
            '"lesson":"空泛计划要立刻改成可验证的小动作"}'
        )


def make_db() -> Session:
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


def test_create_session_is_single_free_write_slot() -> None:
    db = make_db()
    provider = FakeProvider()
    session = create_session_if_needed(db, date(2026, 7, 28), provider)
    assert len(session.qas) == 1
    assert session.qas[0].question == FREE_WRITE_QUESTION
    assert session.qas[0].qa_type == "fixed"
    # 建会话不再调用模型出题
    assert provider.prompts == []


def test_free_write_optional_ask_and_close_are_persisted() -> None:
    db = make_db()
    provider = FakeProvider()
    session = create_session_if_needed(db, date(2026, 7, 28), provider)
    saved = save_answers(db, session, {session.qas[0].id: "继续推进闲鱼副业"})
    following = start_followup(db, saved, provider)
    assert following.status == "following_up"
    pending = next(qa for qa in following.qas if qa.qa_type == "followup")
    answered = answer_followup(db, following, pending.id, "先整理书桌抽屉里的电子产品")
    result = summarize_session(db, answered, provider, skip=False)
    assert result.status == "summarized"
    assert result.summary is not None
    assert "挂出3个测试商品" in result.summary.next_action
    assert result.summary.blockers == result.summary.attribution
    assert "归因分析" in result.summary.raw_markdown
    assert any("继续推进闲鱼副业" in prompt for prompt in provider.prompts)


def test_skip_followup_annotates_review_prompt() -> None:
    db = make_db()
    provider = FakeProvider()
    session = create_session_if_needed(db, date(2026, 7, 28))
    session = save_answers(db, session, {session.qas[0].id: "写了点代码"})
    result = summarize_session(db, session, provider, skip=True)
    assert result.status == "summarized"
    assert any("跳过了自问" in prompt or "未进行自问" in prompt for prompt in provider.prompts)


def test_deepen_and_recoach() -> None:
    db = make_db()
    provider = FakeProvider()
    session = create_session_if_needed(db, date(2026, 7, 28))
    session = save_answers(db, session, {session.qas[0].id: "继续推进项目"})
    session = start_followup(db, session, provider)
    pending = next(qa for qa in session.qas if qa.qa_type == "followup")
    session = answer_followup(db, session, pending.id, "其实不知道从哪开始")
    session = deepen_followup(db, session, provider)
    assert sum(1 for qa in session.qas if qa.qa_type == "followup") == 2
    pending2 = next(qa for qa in session.qas if qa.qa_type == "followup" and not qa.answer)
    session = answer_followup(db, session, pending2.id, "先写三件商品标题")
    session = summarize_session(db, session, provider, skip=False)
    reset = reset_for_recoach(db, session)
    assert reset.status == "answered"
    assert reset.summary is not None
    assert reset.summary.deleted_at is not None
    # 自问与收束都保留在库中，便于后续恢复昨日收束。
    assert any(qa.qa_type == "followup" for qa in reset.qas)
    assert reset.qas[0].answer == "继续推进项目"


def test_recoach_then_restore_brings_back_summary() -> None:
    db = make_db()
    provider = FakeProvider()
    session = create_session_if_needed(db, date(2026, 7, 28))
    session = save_answers(db, session, {session.qas[0].id: "继续推进项目"})
    session = start_followup(db, session, provider)
    pending = next(qa for qa in session.qas if qa.qa_type == "followup")
    session = answer_followup(db, session, pending.id, "其实不知道从哪开始")
    session = summarize_session(db, session, provider, skip=False)
    reset = reset_for_recoach(db, session)
    assert reset.summary.deleted_at is not None
    restored = restore_summary(db, reset)
    assert restored.status == "summarized"
    assert restored.summary.deleted_at is None
    out = session_to_schema(restored)
    assert out.summary is not None and out.summary_soft_deleted is False
    # 重复恢复没有可恢复对象时应报错
    with pytest.raises(ValueError):
        restore_summary(db, restored)


def test_recent_summaries_still_readable_for_context() -> None:
    db = make_db()
    provider = FakeProvider()
    yesterday = date(2026, 7, 27)
    old = create_session_if_needed(db, yesterday)
    old = save_answers(db, old, {old.qas[0].id: "完成数据库"})
    summarize_session(db, old, provider, skip=True)
    context = recent_summary_context(db, yesterday + timedelta(days=1), 7)
    assert "完成了核心工作" in context


def test_legacy_four_qa_material_still_readable() -> None:
    """旧四问会话：材料拼成多段，供自问/收束与回看兼容。"""
    db = make_db()
    session = DailySession(date=date(2026, 7, 20), status=SessionStatus.ANSWERED.value)
    session.qas = [
        QA(question="今天完成了什么？", answer="写了接口", order=1, qa_type=QAType.FIXED.value, round=0),
        QA(question="学到了什么？", answer="少做正确废话", order=2, qa_type=QAType.FIXED.value, round=0),
        QA(question="卡点？", answer="", order=3, qa_type=QAType.FIXED.value, round=0),
        QA(question="明天？", answer="只做一件", order=4, qa_type=QAType.FIXED.value, round=0),
    ]
    db.add(session)
    db.commit()
    lines = _fixed_material_lines(session)
    assert len(lines) == 4
    assert "写了接口" in lines[0]
    assert "少做正确废话" in lines[1]


def test_clearing_answers_reverts_pending_status() -> None:
    db = make_db()
    session = create_session_if_needed(db, date(2026, 7, 28))
    answered = save_answers(db, session, {session.qas[0].id: "有内容"})
    assert answered.status == "answered"
    cleared = save_answers(db, answered, {answered.qas[0].id: "  "})
    assert cleared.status == "pending"
    assert cleared.qas[0].answer == ""


def test_emotion_only_is_a_trace_but_does_not_trigger_ai() -> None:
    db = make_db()
    session = create_session_if_needed(db, date(2026, 7, 28))
    saved = save_answers(db, session, {session.qas[0].id: ""}, emotion="犹豫")
    assert saved.status == "answered"
    assert saved.emotion == "犹豫"
    traces, count = aggregate_day_traces(db, date(2026, 7, 28), date(2026, 7, 28))
    assert count == 1
    assert "情绪：犹豫" in traces
    with pytest.raises(ValueError, match="先写一点"):
        start_followup(db, saved, FakeProvider())


def test_create_session_is_idempotent_for_same_day() -> None:
    db = make_db()
    first = create_session_if_needed(db, date(2026, 7, 28))
    second = create_session_if_needed(db, date(2026, 7, 28))
    assert first.id == second.id
    assert len(second.qas) == 1


def test_question_time_and_base_url_validators() -> None:
    from app.schemas import SettingsUpdate

    settings = SettingsUpdate(
        question_time="21:00:30",
        llm_base_url="https://api.deepseek.com/",
        question_templates=[],
    )
    assert settings.question_time == "21:00"
    assert settings.llm_base_url == "https://api.deepseek.com"
    assert settings.question_templates == []


def test_legacy_summary_display_fields_remain_readable() -> None:
    """旧四段字段仍可构造 SummaryOut（缺新字段时前端回退）。"""
    from datetime import datetime

    from app.schemas import SummaryOut

    legacy = SummaryOut(
        overview="进展",
        learnings="收获",
        blockers="卡点",
        next_plan="计划",
        raw_markdown="# 旧",
        created_at=datetime.now(),
    )
    assert legacy.attribution == ""
    assert legacy.lesson == ""
