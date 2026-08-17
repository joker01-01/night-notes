from __future__ import annotations

import json
from datetime import date, timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import Base
from app.models import DailySession, QA, QAType, SessionStatus, Summary
from app.models.weekly import COLD_START_QUESTION, TEMPLATE_WEEK_FOLLOWUP
from app.llm.prompts import build_week_followup_messages
from app.services.report_service import aggregate_day_traces, aggregate_summaries
from app.services.week_service import (
    close_week,
    generate_week_followup,
    generate_week_topics,
    get_or_create_week,
    save_week_answers,
    save_week_topic,
    save_week_followup_answer,
    week_start_for,
    week_to_payload,
)


def make_db() -> Session:
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


def _add_day(
    db: Session,
    day: date,
    *,
    body: str = "",
    with_summary: bool = False,
) -> DailySession:
    session = DailySession(date=day, status=SessionStatus.ANSWERED.value)
    session.qas = [
        QA(
            question="今晚随手记",
            answer=body,
            order=1,
            qa_type=QAType.FIXED.value,
            round=0,
        )
    ]
    if with_summary:
        session.status = SessionStatus.SUMMARIZED.value
        session.summary = Summary(
            overview="概要",
            learnings="",
            blockers="",
            next_plan="",
            attribution="",
            next_action="",
            lesson="",
            raw_markdown=f"## {day.isoformat()}\n已收束：{body or '空'}",
        )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def _ask_and_answer(db: Session, week_start: date, answer: str = "当时更像负担，但还不想放下。"):
    generate_week_followup(db, week_start, provider=None, use_llm=False)
    return save_week_followup_answer(db, week_start, answer)


def test_week_start_is_sunday() -> None:
    assert week_start_for(date(2026, 7, 29)) == date(2026, 7, 26)  # Wed -> Sun
    assert week_start_for(date(2026, 7, 26)) == date(2026, 7, 26)
    assert week_start_for(date(2026, 8, 1)) == date(2026, 7, 26)  # Sat


def test_close_with_two_days_and_gap() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 26), body="周日写了一点")
    _add_day(db, date(2026, 7, 28), body="周二又写一点", with_summary=True)
    week_start = date(2026, 7, 26)
    save_week_answers(
        db,
        week_start,
        [
            {"question": "这一周实际推进了什么", "answer": "测了周场闭环"},
            {"question": "反复出现的卡住", "answer": "文档太多"},
            {"question": "下周只做一件", "answer": "只推一个接口"},
        ],
    )
    week = _ask_and_answer(db, week_start, "测闭环那天其实有点慌")
    assert week.status == "draft"
    assert week.followup_question
    closed = close_week(db, week_start, use_llm=False)
    assert closed.status == "closed"
    assert closed.trace_days == 2
    assert "测闭环那天其实有点慌" in closed.raw_markdown
    assert "本周问自己" in closed.raw_markdown
    assert "周日写了一点" in closed.raw_markdown


def test_zero_trace_days_reject_followup_and_close() -> None:
    db = make_db()
    week_start = week_start_for(date(2026, 7, 29))
    get_or_create_week(db, week_start)
    with pytest.raises(ValueError, match="还几乎没有日痕迹"):
        generate_week_followup(db, week_start, use_llm=False)
    with pytest.raises(ValueError, match="还几乎没有日痕迹"):
        close_week(db, week_start, use_llm=False)


def test_bootstrap_week_can_start_without_day_traces() -> None:
    db = make_db()
    week_start = week_start_for(date(2026, 7, 29))
    save_week_answers(
        db,
        week_start,
        [{"question": COLD_START_QUESTION, "answer": "我到底还想不想继续做这个 App？"}],
    )
    week = generate_week_followup(db, week_start, use_llm=False)
    assert week.followup_question == TEMPLATE_WEEK_FOLLOWUP
    assert week.trace_days == 0
    save_week_followup_answer(db, week_start, "我还想做，但害怕没人用。")
    closed = close_week(db, week_start, use_llm=False)
    assert closed.status == "closed"
    assert "我到底还想不想继续做这个 App？" in closed.raw_markdown


def test_selected_topic_can_start_a_cold_week_without_daily_traces() -> None:
    db = make_db()
    week_start = week_start_for(date(2026, 7, 29))
    save_week_topic(db, week_start, "我到底还想不想继续做这个 App？", emotion="犹豫")
    week = generate_week_followup(db, week_start, use_llm=False)
    assert week.selected_topic == "我到底还想不想继续做这个 App？"
    assert week.followup_emotion == "犹豫"
    save_week_followup_answer(db, week_start, "我还想做，但害怕没人用。")
    closed = close_week(db, week_start, use_llm=False)
    assert closed.status == "closed"
    assert "这周想谈的事" in closed.raw_markdown
    assert "我到底还想不想继续做这个 App？" in closed.raw_markdown


def test_local_week_topics_are_bounded_and_use_original_trace() -> None:
    db = make_db()
    week_start = date(2026, 7, 26)
    _add_day(db, date(2026, 7, 27), body="准备发布一个小 App")
    _add_day(db, date(2026, 7, 29), body="总觉得还没准备好")
    week = generate_week_topics(db, week_start, provider=None, use_llm=False)
    assert 1 <= len(json.loads(week.candidate_topics_json)) <= 3
    assert any("准备发布一个小 App" in topic for topic in json.loads(week.candidate_topics_json))


def test_week_prompt_includes_prior_signal_and_bootstrap_topic() -> None:
    messages = build_week_followup_messages(
        week_start="2026-08-02",
        week_end="2026-08-08",
        outline_lines=["问：下周只做一件\n答：完成真实用户验证"],
        traces="（起步模式）\n我想知道产品是否值得继续",
        trace_days=0,
        prior_signal="上周回答：我害怕没人用\n上周下一步：找 10 个用户",
        bootstrap_topic="我想知道产品是否值得继续",
    )
    user_content = messages[-1]["content"]
    assert "我害怕没人用" in user_content
    assert "找 10 个用户" in user_content
    assert "我想知道产品是否值得继续" in user_content


def test_unsaved_body_appears_in_traces() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 28), body="只存未收的正文", with_summary=False)
    text, count = aggregate_day_traces(db, date(2026, 7, 26), date(2026, 8, 1))
    assert count == 1
    assert "只存未收的正文" in text
    assert "未收束的夜记" in text
    ctx = aggregate_summaries(db, date(2026, 7, 29), 7)
    assert "只存未收的正文" in ctx


def test_cross_month_week_traces() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 31), body="月末")
    _add_day(db, date(2026, 8, 1), body="月初")
    text, count = aggregate_day_traces(db, date(2026, 7, 26), date(2026, 8, 1))
    assert count == 2
    assert "月末" in text and "月初" in text
    _ask_and_answer(db, date(2026, 7, 26))
    closed = close_week(db, date(2026, 7, 26), use_llm=False)
    assert closed.trace_days == 2


def test_followup_without_llm_uses_template() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 27), body="一天就够")
    week = generate_week_followup(db, date(2026, 7, 26), provider=None, use_llm=True)
    assert week.followup_question == TEMPLATE_WEEK_FOLLOWUP


def test_close_requires_answer() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 27), body="x")
    generate_week_followup(db, date(2026, 7, 26), use_llm=False)
    with pytest.raises(ValueError, match="还没写下回答"):
        close_week(db, date(2026, 7, 26), use_llm=False)


class WeekFollowupFakeProvider:
    def chat(self, messages):
        system = next((m["content"] for m in messages if m["role"] == "system"), "")
        if "和自己谈谈" in system or "当时" in system:
            return "发布那个 App 的晚上，对你来说更像期待，还是怕被看见？"
        return (
            '{"echo":"你说发布更像怕被看见。",'
            '"next_focus":"本周先不硬定下一件",'
            '"note":"怕被看见也没关系。"}'
        )


class RecordingFollowupProvider:
    def __init__(self) -> None:
        self.messages = []

    def chat(self, messages):
        self.messages.append(messages)
        return "这件事现在的分量，和上周相比有没有变化？"


def test_followup_carries_forward_previous_closed_week_signal() -> None:
    db = make_db()
    previous_start = date(2026, 7, 26)
    _add_day(db, date(2026, 7, 27), body="上周一直担心发布")
    _ask_and_answer(db, previous_start, "我害怕没人会用")
    close_week(db, previous_start, use_llm=False)

    current_start = date(2026, 8, 2)
    _add_day(db, date(2026, 8, 3), body="这周准备找真实用户")
    provider = RecordingFollowupProvider()
    generate_week_followup(db, current_start, provider=provider, use_llm=True)

    user_content = provider.messages[-1][-1]["content"]
    assert "我害怕没人会用" in user_content
    assert "本周准备找真实用户" not in user_content
    assert "找真实用户" in user_content


def test_two_day_traces_gentle_followup_then_close() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 26), body="在磨一个小 App")
    _add_day(db, date(2026, 7, 28), body="差点发布")
    provider = WeekFollowupFakeProvider()
    week = generate_week_followup(db, date(2026, 7, 26), provider=provider, use_llm=True)
    assert "App" in week.followup_question or "发布" in week.followup_question
    assert "反复" not in week.followup_question  # 材料少时不硬造反复主题文案
    save_week_followup_answer(db, date(2026, 7, 26), "更像怕被看见")
    closed = close_week(db, date(2026, 7, 26), provider=provider, use_llm=True)
    assert closed.status == "closed"
    assert "怕被看见" in closed.overview
    assert closed.next_focus
    assert "本周问自己" in closed.raw_markdown
    assert "pattern" not in closed.raw_markdown.lower() or "反复出现的" not in closed.raw_markdown


def test_summarize_week_requires_provider() -> None:
    from app.services.week_service import summarize_week

    db = make_db()
    _add_day(db, date(2026, 7, 27), body="x")
    _ask_and_answer(db, date(2026, 7, 26))
    close_week(db, date(2026, 7, 26), use_llm=False)
    with pytest.raises(Exception, match="已经收好"):
        summarize_week(db, date(2026, 7, 26), provider=None)


def test_payload_counts_empty_days() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 26), body="仅一天")
    week = get_or_create_week(db, date(2026, 7, 26))
    payload = week_to_payload(db, week)
    assert payload["trace_days"] == 1
    assert payload["empty_days"] == 6
    assert "followup_question" in payload


def test_cannot_edit_after_close() -> None:
    db = make_db()
    _add_day(db, date(2026, 7, 26), body="x")
    _ask_and_answer(db, date(2026, 7, 26))
    close_week(db, date(2026, 7, 26))
    with pytest.raises(ValueError, match="已经收好"):
        save_week_answers(
            db,
            date(2026, 7, 26),
            [{"question": "这一周实际推进了什么", "answer": "改不动"}],
        )
    with pytest.raises(ValueError, match="已经收好"):
        save_week_followup_answer(db, date(2026, 7, 26), "也不能改")
