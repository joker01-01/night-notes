"""周/日痕迹聚合：优先 Summary，其次未收束日正文。"""

from __future__ import annotations

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models import DailySession, QAType, Summary


def _fixed_body(session: DailySession) -> str:
    parts = [
        qa.answer.strip()
        for qa in session.qas
        if (qa.qa_type or QAType.FIXED.value) == QAType.FIXED.value and qa.answer.strip()
    ]
    return "\n\n".join(parts)


def day_has_trace(session: DailySession) -> bool:
    if session.summary is not None and str(session.summary.raw_markdown or "").strip():
        return True
    return bool(_fixed_body(session))


def format_day_trace(session: DailySession) -> str | None:
    """单日痕迹块；无 Summary 且无正文时返回 None。"""
    day = session.date.isoformat()
    if session.summary is not None and str(session.summary.raw_markdown or "").strip():
        return f"## {day}\n{session.summary.raw_markdown.strip()}"
    body = _fixed_body(session)
    if not body:
        return None
    return f"## {day}\n（未收束的夜记）\n{body}"


def sessions_in_range(db: Session, start: date, end: date) -> list[DailySession]:
    return list(
        db.scalars(
            select(DailySession)
            .options(joinedload(DailySession.summary), joinedload(DailySession.qas))
            .where(DailySession.date >= start, DailySession.date <= end)
            .order_by(DailySession.date.asc())
        )
        .unique()
        .all()
    )


def aggregate_day_traces(db: Session, start: date, end: date) -> tuple[str, int]:
    """返回 (痕迹文本, 有痕迹天数)。缺日自动跳过。"""
    blocks: list[str] = []
    count = 0
    for session in sessions_in_range(db, start, end):
        block = format_day_trace(session)
        if block:
            blocks.append(block)
            count += 1
    return "\n\n".join(blocks), count


def aggregate_summaries(db: Session, end_day: date, days: int) -> str:
    """兼容旧接口：近 N 天痕迹（含未收束日正文）。"""
    start = end_day - timedelta(days=days - 1)
    text, _ = aggregate_day_traces(db, start, end_day)
    return text


def aggregate_summaries_legacy_only(db: Session, end_day: date, days: int) -> str:
    """仅 Summary.raw_markdown（测试对照用）。"""
    summaries = db.scalars(
        select(Summary)
        .join(DailySession)
        .where(DailySession.date >= end_day - timedelta(days=days - 1), DailySession.date <= end_day)
        .order_by(DailySession.date.asc())
    ).all()
    return "\n\n".join(summary.raw_markdown for summary in summaries)
