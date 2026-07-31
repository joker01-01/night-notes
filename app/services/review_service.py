"""日场会话：自由书写、可选自问与可选短收束。"""

from __future__ import annotations

import json
import logging
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.llm import LLMProvider
from app.llm.prompts import (
    MAX_FOLLOWUP_ROUNDS,
    build_followup_messages,
    build_review_messages,
)
from app.models import DailySession, QA, QAType, SessionStatus, Summary
from app.schemas import QAOut, SessionOut, SummaryOut

logger = logging.getLogger(__name__)

# 新会话唯一占位题；旧库多条 fixed QA 仅作兼容读取
FREE_WRITE_QUESTION = "今晚正文"


def get_session(db: Session, day: date) -> DailySession | None:
    return db.scalar(
        select(DailySession)
        .options(selectinload(DailySession.qas), selectinload(DailySession.summary))
        .where(DailySession.date == day)
    )


def recent_summary_context(db: Session, day: date, days: int) -> str:
    """限制为最近 N 天已完成总结；供创建当日问题时使用，追问/复盘 Prompt 不注入。"""
    start = day - timedelta(days=days)
    summaries = db.scalars(
        select(Summary)
        .join(DailySession)
        .where(DailySession.date < day, DailySession.date >= start)
        .order_by(DailySession.date.desc())
    ).all()
    if not summaries:
        return "（暂无历史总结）"
    return "\n\n".join(
        f"### {summary.session.date.isoformat()}\n{summary.raw_markdown}" for summary in summaries
    )


def _fixed_qas(session: DailySession) -> list[QA]:
    return [qa for qa in session.qas if qa.qa_type == QAType.FIXED.value]


def _followup_qas(session: DailySession) -> list[QA]:
    return sorted(
        (qa for qa in session.qas if qa.qa_type == QAType.FOLLOWUP.value),
        key=lambda item: item.round,
    )


def _pending_followup(session: DailySession) -> QA | None:
    for qa in _followup_qas(session):
        if not qa.answer.strip():
            return qa
    return None


def _next_order(session: DailySession) -> int:
    return max((qa.order for qa in session.qas), default=0) + 1


def _fixed_material_lines(session: DailySession) -> list[str]:
    """供日自问/收束：新路径只喂自由写正文；旧四问会话拼成多段。"""
    fixed = _fixed_qas(session)
    if not fixed:
        return ["（今晚还没写）"]
    if len(fixed) == 1:
        body = fixed[0].answer.strip() or "（今晚还没写）"
        return [body]
    lines: list[str] = []
    for index, qa in enumerate(fixed, 1):
        answer = qa.answer.strip() or "（未写）"
        lines.append(f"{index}. {qa.question}\n{answer}")
    return lines


def _clean_followup_question(text: str) -> str:
    cleaned = text.strip().strip('"').strip("'")
    for prefix in ("追问：", "问题：", "问："):
        if cleaned.startswith(prefix):
            cleaned = cleaned[len(prefix) :].strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`").strip()
    return cleaned.splitlines()[0].strip() if cleaned else ""


def create_session_if_needed(
    db: Session, day: date, provider: LLMProvider | None = None
) -> DailySession:
    """建当日会话：仅一条「今晚正文」占位。不再按四问模板/智能出题。

    ``provider`` 保留以兼容调度与 API 签名，建会话时不再调用模型出题。
    """
    del provider  # 废案：每日四问 / 智能出四题
    existing = get_session(db, day)
    if existing is not None:
        return existing
    session = DailySession(date=day, status=SessionStatus.PENDING.value)
    session.qas = [
        QA(
            question=FREE_WRITE_QUESTION,
            order=1,
            qa_type=QAType.FIXED.value,
            round=0,
        )
    ]
    db.add(session)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = get_session(db, day)
        if existing is not None:
            return existing
        raise
    return get_session(db, day) or session


def save_answers(db: Session, session: DailySession, answers: dict[int, str]) -> DailySession:
    if session.status in {SessionStatus.FOLLOWING_UP.value, SessionStatus.SUMMARIZED.value}:
        raise ValueError("正在自问或已收过一收时，今晚正文暂不可改。可先「再写一遍」。")
    fixed_ids = {qa.id for qa in _fixed_qas(session)}
    unknown = set(answers) - fixed_ids
    if unknown:
        raise ValueError("答案不属于今晚这条记录。")
    for qa in _fixed_qas(session):
        if qa.id in answers:
            qa.answer = answers[qa.id].strip()
    if any(qa.answer for qa in _fixed_qas(session)):
        session.status = SessionStatus.ANSWERED.value
    else:
        session.status = SessionStatus.PENDING.value
    db.commit()
    return get_session(db, session.date) or session


def reset_for_recoach(db: Session, session: DailySession) -> DailySession:
    """清除收束与自问，保留今晚正文，供重开。"""
    for qa in list(_followup_qas(session)):
        db.delete(qa)
    if session.summary is not None:
        db.delete(session.summary)
        session.summary = None
    if any(qa.answer for qa in _fixed_qas(session)):
        session.status = SessionStatus.ANSWERED.value
    else:
        session.status = SessionStatus.PENDING.value
    db.commit()
    return get_session(db, session.date) or session


def start_followup(db: Session, session: DailySession, provider: LLMProvider) -> DailySession:
    if session.status == SessionStatus.SUMMARIZED.value:
        raise ValueError("今晚已收过一收。如需重来，请先「再写一遍」。")
    if session.status == SessionStatus.FOLLOWING_UP.value:
        pending = _pending_followup(session)
        if pending is not None:
            return get_session(db, session.date) or session
        answered = [qa for qa in _followup_qas(session) if qa.answer.strip()]
        if answered and max(qa.round for qa in answered) >= MAX_FOLLOWUP_ROUNDS:
            raise ValueError("自问已达上限，可以收一收了。")
        raise ValueError("当前自问已回答，可再深入一句，或直接收一收。")
    fixed = _fixed_qas(session)
    if not any(qa.answer.strip() for qa in fixed):
        raise ValueError("先写一点今晚的内容，再问自己一句。")
    session.status = SessionStatus.ANSWERED.value
    db.commit()
    messages = build_followup_messages(
        fixed_qa_lines=_fixed_material_lines(session),
        prior_followups=[],
        round_number=1,
    )
    question = _clean_followup_question(provider.chat(messages))
    if not question:
        raise ValueError("模型这次没给出可用问句，请重试或先这样。")
    session.qas.append(
        QA(
            question=question,
            answer="",
            order=_next_order(session),
            qa_type=QAType.FOLLOWUP.value,
            round=1,
        )
    )
    session.status = SessionStatus.FOLLOWING_UP.value
    db.commit()
    return get_session(db, session.date) or session


def answer_followup(db: Session, session: DailySession, qa_id: int, answer: str) -> DailySession:
    if session.status != SessionStatus.FOLLOWING_UP.value:
        raise ValueError("当前不在自问阶段。")
    target = next((qa for qa in _followup_qas(session) if qa.id == qa_id), None)
    if target is None:
        raise ValueError("这句自问不存在。")
    pending = _pending_followup(session)
    if pending is not None and pending.id != qa_id:
        raise ValueError("请先回答当前这句。")
    cleaned = answer.strip()
    if not cleaned:
        raise ValueError("回答不能为空。")
    target.answer = cleaned
    db.commit()
    return get_session(db, session.date) or session


def deepen_followup(db: Session, session: DailySession, provider: LLMProvider) -> DailySession:
    if session.status != SessionStatus.FOLLOWING_UP.value:
        raise ValueError("当前不在自问阶段。")
    if _pending_followup(session) is not None:
        raise ValueError("请先回答当前这句，或跳过。")
    answered = [qa for qa in _followup_qas(session) if qa.answer.strip()]
    if not answered:
        raise ValueError("还没有已完成的自问。")
    current_round = max(qa.round for qa in answered)
    if current_round >= MAX_FOLLOWUP_ROUNDS:
        raise ValueError("自问最多两轮，可以收一收了。")
    next_round = current_round + 1
    messages = build_followup_messages(
        fixed_qa_lines=_fixed_material_lines(session),
        prior_followups=[(qa.question, qa.answer) for qa in answered],
        round_number=next_round,
    )
    question = _clean_followup_question(provider.chat(messages))
    if not question:
        raise ValueError("模型这次没给出可用问句，请重试或直接收一收。")
    session.qas.append(
        QA(
            question=question,
            answer="",
            order=_next_order(session),
            qa_type=QAType.FOLLOWUP.value,
            round=next_round,
        )
    )
    db.commit()
    return get_session(db, session.date) or session


def _extract_review_json(text: str) -> dict[str, str]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
    try:
        parsed = json.loads(cleaned)
        keys = ("overview", "attribution", "next_action", "lesson")
        if isinstance(parsed, dict) and all(key in parsed for key in keys):
            return {key: str(parsed[key]).strip() for key in keys}
    except json.JSONDecodeError:
        pass
    raise ValueError("模型未返回预期 JSON 格式，请重试或更换模型。")


def summarize_session(
    db: Session,
    session: DailySession,
    provider: LLMProvider,
    *,
    skip: bool = False,
) -> DailySession:
    fixed = _fixed_qas(session)
    if not any(qa.answer.strip() for qa in fixed):
        raise ValueError("先写一点今晚的内容，再收一收。")

    pending = _pending_followup(session)
    if not skip and pending is not None:
        raise ValueError("还有一句自问没答完；可先答，或跳过直接收一收。")

    if skip and pending is not None:
        db.delete(pending)
        db.flush()

    answered_followups = [
        (qa.round, qa.question, qa.answer) for qa in _followup_qas(session) if qa.answer.strip()
    ]
    # 没有任何已答自问 → 视为跳过，归因不得硬编。
    skipped = len(answered_followups) == 0
    if skipped and skip:
        skip_note = "用户未进行自问，直接收束。"
    elif skipped:
        skip_note = "用户本次跳过了自问。"
    elif skip:
        skip_note = f"已完成 {len(answered_followups)} 轮自问后结束并收束。"
    else:
        skip_note = ""

    messages = build_review_messages(
        fixed_qa_lines=_fixed_material_lines(session),
        answered_followups=answered_followups,
        skipped=skipped,
        skip_note=skip_note,
    )
    parts = _extract_review_json(provider.chat(messages))
    raw = "\n\n".join(
        [
            "# 今日概要\n" + parts["overview"],
            "# 归因分析\n" + parts["attribution"],
            "# 具体下一步\n" + parts["next_action"],
            "# 今日一句话教训\n" + parts["lesson"],
        ]
    )
    # V1 字段兼容映射（非第二套真相来源）。
    legacy = {
        "overview": parts["overview"],
        "learnings": "",
        "blockers": parts["attribution"],
        "next_plan": parts["next_action"],
        "attribution": parts["attribution"],
        "next_action": parts["next_action"],
        "lesson": parts["lesson"],
    }
    if session.summary is None:
        session.summary = Summary(**legacy, raw_markdown=raw)
    else:
        for key, value in legacy.items():
            setattr(session.summary, key, value)
        session.summary.raw_markdown = raw
    session.status = SessionStatus.SUMMARIZED.value
    db.commit()
    return get_session(db, session.date) or session


def session_to_schema(session: DailySession) -> SessionOut:
    summary = None
    if session.summary is not None:
        summary = SummaryOut(
            overview=session.summary.overview,
            learnings=session.summary.learnings,
            blockers=session.summary.blockers,
            next_plan=session.summary.next_plan,
            attribution=getattr(session.summary, "attribution", "") or "",
            next_action=getattr(session.summary, "next_action", "") or "",
            lesson=getattr(session.summary, "lesson", "") or "",
            raw_markdown=session.summary.raw_markdown,
            created_at=session.summary.created_at,
        )
    return SessionOut(
        date=session.date,
        status=session.status,
        qas=[
            QAOut(
                id=qa.id,
                question=qa.question,
                answer=qa.answer,
                order=qa.order,
                qa_type=getattr(qa, "qa_type", QAType.FIXED.value) or QAType.FIXED.value,
                round=int(getattr(qa, "round", 0) or 0),
            )
            for qa in session.qas
        ],
        summary=summary,
        max_followup_rounds=MAX_FOLLOWUP_ROUNDS,
    )
