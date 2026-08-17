"""周场：可选提纲热身 → 生成周问 → 作答 → 极短收束。核心资产是问句+回答。"""

from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.llm.prompts import (
    build_week_close_messages,
    build_week_followup_messages,
    build_week_topics_messages,
)
from app.core.errors import ConflictError
from app.llm.providers import LLMProvider
from app.models.weekly import (
    COLD_START_QUESTION,
    DEFAULT_WEEK_OUTLINE,
    TEMPLATE_WEEK_FOLLOWUP,
    WeekStatus,
    WeeklyReview,
)
from app.services.report_service import aggregate_day_traces

logger = logging.getLogger(__name__)


def week_start_for(day: date) -> date:
    """周日为一周之始（与前端七日格一致）。"""
    offset = (day.weekday() + 1) % 7
    return day - timedelta(days=offset)


def week_end_for(week_start: date) -> date:
    return week_start + timedelta(days=6)


def _default_answers() -> list[dict[str, str]]:
    return [{"question": q, "answer": ""} for q in DEFAULT_WEEK_OUTLINE]


def _parse_answers(raw: str) -> list[dict[str, str]]:
    try:
        data = json.loads(raw or "[]")
    except json.JSONDecodeError:
        return _default_answers()
    if not isinstance(data, list) or not data:
        return _default_answers()
    out: list[dict[str, str]] = []
    for item in data:
        if not isinstance(item, dict):
            continue
        q = str(item.get("question") or "").strip()
        a = str(item.get("answer") or "")
        if q:
            out.append({"question": q, "answer": a})
    return out or _default_answers()


def _dump_answers(answers: list[dict[str, str]]) -> str:
    return json.dumps(answers, ensure_ascii=False)


def _parse_topics(raw: str) -> list[str]:
    cleaned = (raw or "").strip()
    fence = chr(96) * 3
    if cleaned.startswith(fence):
        cleaned = re.sub(r"^" + fence + r"(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*" + fence + r"$", "", cleaned)
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        data = []
    if isinstance(data, dict):
        data = data.get("topics") or data.get("items") or []
    if not isinstance(data, list):
        return []
    topics: list[str] = []
    for item in data:
        topic = re.sub(r"\s+", " ", str(item or "")).strip().strip('"\'')
        if topic and topic not in topics:
            topics.append(topic[:500])
    return topics[:3]


def _dump_topics(topics: list[str]) -> str:
    return json.dumps(topics[:3], ensure_ascii=False)


def _local_candidate_topics(traces: str, bootstrap_topic: str = "") -> list[str]:
    if bootstrap_topic.strip():
        return [bootstrap_topic.strip()[:500]]
    topics: list[str] = []
    for raw_line in (traces or "").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("（") or line.startswith("情绪："):
            continue
        line = re.sub(r"^\d+[.、]\s*", "", line)
        line = re.sub(r"\s+", " ", line).strip()
        if line and line not in topics:
            topics.append(line[:120])
    if not topics and "情绪：" in (traces or ""):
        topics.append("这周反复出现的情绪")
    return topics[:3]


def _bootstrap_topic(answers: list[dict[str, str]]) -> str:
    for item in answers:
        if item.get("question") == COLD_START_QUESTION:
            return (item.get("answer") or "").strip()
    return ""


def _require_trace_days(
    db: Session,
    week_start: date,
    *,
    answers: list[dict[str, str]] | None = None,
    selected_topic: str = "",
) -> tuple[str, int, str]:
    end = week_end_for(week_start)
    traces, trace_days = aggregate_day_traces(db, week_start, end)
    bootstrap_topic = _bootstrap_topic(answers or []) or (selected_topic or "").strip()
    if trace_days == 0 and bootstrap_topic:
        return (
            "（起步模式：用户最近最想搞清楚的一件事）\n"
            f"{bootstrap_topic}",
            0,
            bootstrap_topic,
        )
    if trace_days < 1:
        raise ValueError("还几乎没有日痕迹。先写一点，或在下方填一件最近最想搞清楚的事。")
    return traces, trace_days, ""


def _previous_week_signal(db: Session, week_start: date) -> str:
    previous = db.scalar(
        select(WeeklyReview)
        .where(
            WeeklyReview.week_start < week_start,
            WeeklyReview.status == WeekStatus.CLOSED.value,
        )
        .order_by(WeeklyReview.week_start.desc())
    )
    if previous is None:
        return ""
    parts = [
        f"上周周问：{(previous.followup_question or '').strip()}",
        f"上周回答：{(previous.followup_answer or '').strip()}",
        f"上周下一步：{(previous.next_focus or '').strip()}",
    ]
    return "\n".join(line for line in parts if line.split("：", 1)[1])


def get_or_create_week(db: Session, week_start: date) -> WeeklyReview:
    existing = db.scalar(select(WeeklyReview).where(WeeklyReview.week_start == week_start))
    if existing is not None:
        return existing
    row = WeeklyReview(
        week_start=week_start,
        status=WeekStatus.DRAFT.value,
        answers_json=_dump_answers(_default_answers()),
    )
    db.add(row)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.scalar(select(WeeklyReview).where(WeeklyReview.week_start == week_start))
        if existing is not None:
            return existing
        raise
    db.refresh(row)
    return row


def get_week(db: Session, week_start: date) -> WeeklyReview | None:
    return db.scalar(select(WeeklyReview).where(WeeklyReview.week_start == week_start))


def generate_week_topics(
    db: Session,
    week_start: date,
    *,
    provider: LLMProvider | None = None,
    use_llm: bool = True,
) -> WeeklyReview:
    """生成 2～3 个可选主题；没有模型时从用户原话提取可解释候选。"""
    week = get_or_create_week(db, week_start)
    if week.status != WeekStatus.DRAFT.value:
        raise ValueError("这一周已经收好了，不能再换主题。")
    answers = _parse_answers(week.answers_json)
    try:
        traces, trace_days, bootstrap_topic = _require_trace_days(
            db, week_start, answers=answers, selected_topic=week.selected_topic
        )
    except Exception:
        db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.FOLLOWUP_GENERATING.value).values(status=WeekStatus.DRAFT.value))
        db.commit()
        raise
    claimed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value).values(status=WeekStatus.TOPICS_GENERATING.value))
    if claimed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再试。")
    db.commit()
    topics = _local_candidate_topics(traces, bootstrap_topic)
    if use_llm and provider is not None:
        messages = build_week_topics_messages(
            week_start=week_start.isoformat(),
            week_end=week_end_for(week_start).isoformat(),
            traces=traces,
            trace_days=trace_days,
            prior_signal=_previous_week_signal(db, week_start),
            bootstrap_topic=bootstrap_topic,
        )
        try:
            parsed = _parse_topics(provider.chat(messages))
            if parsed:
                topics = parsed
        except Exception:
            logger.exception("周场候选主题 LLM 失败，降级本地候选")
    if not topics:
        raise ValueError("还没找到可谈的主题。可以先写一条日痕迹，或自己填一件事。")
    claimed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.TOPICS_GENERATING.value).values(candidate_topics_json=_dump_topics(topics), trace_days=trace_days, status=WeekStatus.DRAFT.value, updated_at=datetime.now()))
    if claimed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再试。")
    db.commit()
    db.refresh(week)
    return week


def save_week_topic(
    db: Session,
    week_start: date,
    topic: str,
    *,
    emotion: str = "",
) -> WeeklyReview:
    week = get_or_create_week(db, week_start)
    if week.status != WeekStatus.DRAFT.value:
        raise ValueError("这一周已经收好了，不能再换主题。")
    cleaned = (topic or "").strip()
    if not cleaned:
        raise ValueError("先选一件事，或自己写一个想谈的主题。")
    changed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value).values(selected_topic=cleaned[:500], followup_emotion=(emotion or "").strip()[:40], updated_at=datetime.now()))
    if changed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再保存。")
    db.commit()
    db.refresh(week)
    return week


def save_week_answers(
    db: Session, week_start: date, answers: list[dict[str, str]]
) -> WeeklyReview:
    week = get_or_create_week(db, week_start)
    if week.status != WeekStatus.DRAFT.value:
        raise ValueError("这一周已经收好了，不能再改提纲。")
    current = {item["question"]: item["answer"] for item in _parse_answers(week.answers_json)}
    merged: list[dict[str, str]] = []
    for item in answers:
        q = str(item.get("question") or "").strip()
        if not q:
            continue
        merged.append({"question": q, "answer": str(item.get("answer") or "")})
        current[q] = merged[-1]["answer"]
    if not merged:
        merged = _default_answers()
    ordered: list[dict[str, str]] = []
    for q in DEFAULT_WEEK_OUTLINE:
        ordered.append({"question": q, "answer": current.get(q, "")})
    for item in merged:
        if item["question"] not in DEFAULT_WEEK_OUTLINE:
            ordered.append(item)
    replacement = _dump_answers(ordered)
    changed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value, WeeklyReview.answers_json == week.answers_json).values(answers_json=replacement, updated_at=datetime.now()))
    if changed.rowcount != 1:
        db.rollback()
        raise ConflictError("答案已被另一处修改，请刷新后再保存。")
    db.commit()
    db.refresh(week)
    return week


def _clean_question(text: str) -> str:
    q = (text or "").strip().strip('"\'')
    q = re.sub(r"^(问|问题|周问)[：:]\s*", "", q)
    return q.strip()


def generate_week_followup(
    db: Session,
    week_start: date,
    *,
    provider: LLMProvider | None = None,
    use_llm: bool = True,
) -> WeeklyReview:
    """生成【一个】周问并落库。无 Key / 失败时降级为模板轻问。"""
    week = get_or_create_week(db, week_start)
    if week.status != WeekStatus.DRAFT.value:
        raise ValueError("这一周已经收好了，不能再问。")

    claimed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value).values(status=WeekStatus.FOLLOWUP_GENERATING.value))
    if claimed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再试。")
    db.commit()
    answers = _parse_answers(week.answers_json)
    try:
        traces, trace_days, bootstrap_topic = _require_trace_days(
            db, week_start, answers=answers, selected_topic=week.selected_topic
        )
    except Exception:
        db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.FOLLOWUP_GENERATING.value).values(status=WeekStatus.DRAFT.value))
        db.commit()
        raise
    selected_topic = (week.selected_topic or "").strip()
    if not selected_topic:
        fallback_topics = _local_candidate_topics(traces, bootstrap_topic)
        if fallback_topics:
            selected_topic = fallback_topics[0]
            week.selected_topic = selected_topic
    outline_lines = [
        f"问：{item['question']}\n答：{(item.get('answer') or '').strip() or '（未写）'}"
        for item in answers
    ]

    question = TEMPLATE_WEEK_FOLLOWUP
    prior_signal = _previous_week_signal(db, week_start)
    if use_llm and provider is not None:
        messages = build_week_followup_messages(
            week_start=week_start.isoformat(),
            week_end=week_end_for(week_start).isoformat(),
            outline_lines=outline_lines,
            traces=traces,
            trace_days=trace_days,
            prior_signal=prior_signal,
            bootstrap_topic=bootstrap_topic,
            selected_topic=selected_topic,
            followup_emotion=week.followup_emotion or "",
        )
        try:
            raw = _clean_question(provider.chat(messages))
            if raw:
                question = raw
        except Exception:
            logger.exception("周追问 LLM 失败，降级模板轻问")

    changed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.FOLLOWUP_GENERATING.value).values(followup_question=question, followup_answer="", trace_days=trace_days, status=WeekStatus.DRAFT.value, updated_at=datetime.now()))
    if changed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再试。")
    db.commit()
    db.refresh(week)
    return week


def save_week_followup_answer(
    db: Session, week_start: date, answer: str
) -> WeeklyReview:
    week = get_or_create_week(db, week_start)
    if week.status != WeekStatus.DRAFT.value:
        raise ValueError("这一周已经收好了，不能再改回答。")
    if not (week.followup_question or "").strip():
        raise ValueError("还没有本周问句。先点「问自己一句（本周）」。")
    changed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value).values(followup_answer=(answer or "").strip(), updated_at=datetime.now()))
    if changed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再保存。")
    db.commit()
    db.refresh(week)
    return week


def _parse_week_close_json(text: str) -> dict[str, str] | None:
    raw = text.strip()
    if raw.startswith("```"):
        raw = re.sub(r"^```(?:json)?\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        match = re.search(r"\{[\s\S]*\}", raw)
        if not match:
            return None
        try:
            data = json.loads(match.group(0))
        except json.JSONDecodeError:
            return None
    if not isinstance(data, dict):
        return None
    keys = ("echo", "next_focus", "note")
    if not any(str(data.get(k) or "").strip() for k in keys):
        return None
    return {k: str(data.get(k) or "").strip() for k in keys}


def build_local_week_close(
    *,
    week_start: date,
    followup_question: str,
    followup_answer: str,
    answers: list[dict[str, str]],
    traces: str,
    trace_days: int,
    selected_topic: str = "",
    followup_emotion: str = "",
) -> dict[str, str]:
    answer = (followup_answer or "").strip()
    echo = answer[:160] if answer else "这一周你坐下来答了一句。"
    if len(answer) > 160:
        echo = echo.rstrip() + "…"
    return {
        "echo": echo,
        "next_focus": "本周先不硬定下一件",
        "note": "问过自己，就算过完了。",
        "raw_markdown": _format_week_archive(
            week_start=week_start,
            followup_question=followup_question,
            followup_answer=followup_answer,
            answers=answers,
            traces=traces,
            trace_days=trace_days,
            selected_topic=selected_topic,
            followup_emotion=followup_emotion,
            echo=echo,
            next_focus="本周先不硬定下一件",
            note="问过自己，就算过完了。",
        ),
    }


def _format_week_archive(
    *,
    week_start: date,
    followup_question: str,
    followup_answer: str,
    answers: list[dict[str, str]],
    traces: str,
    trace_days: int,
    selected_topic: str = "",
    followup_emotion: str = "",
    echo: str,
    next_focus: str,
    note: str,
) -> str:
    week_end = week_end_for(week_start)
    lines = [
        f"# 周场 {week_start.isoformat()} — {week_end.isoformat()}",
        "",
        f"本周有痕迹的日子：{trace_days} 天。",
        "",
        "## 这周想谈的事",
        selected_topic.strip() or "（未选择）",
        "",
        "## 周场情绪",
        followup_emotion.strip() or "（未选择）",
        "",
        "## 本周问自己",
        (followup_question or "").strip() or "（未生成）",
        "",
        "## 我的回答",
        (followup_answer or "").strip() or "（未写）",
        "",
        "## 收束",
        echo or "（未写）",
        "",
        f"下一步：{next_focus or '（未写）'}",
        "",
        f"留给自己：{note or '（未写）'}",
        "",
    ]
    written = [item for item in answers if (item.get("answer") or "").strip()]
    if written:
        lines.append("## 提纲热身")
        for item in written:
            lines.extend([f"### {item['question']}", item["answer"].strip(), ""])
    lines.append("## 近七日痕迹")
    lines.append(traces.strip() or "（本周几乎没有日痕迹）")
    return "\n".join(lines).strip() + "\n"


def _generate_week_close_content(
    *,
    week_start: date,
    followup_question: str,
    followup_answer: str,
    answers: list[dict[str, str]],
    traces: str,
    trace_days: int,
    selected_topic: str = "",
    followup_emotion: str = "",
    provider: LLMProvider | None,
    use_llm: bool,
) -> tuple[str, str, str, str, bool]:
    """返回 echo, next_focus, note, raw_markdown, used_ai。"""
    local = build_local_week_close(
        week_start=week_start,
        followup_question=followup_question,
        followup_answer=followup_answer,
        answers=answers,
        traces=traces,
        trace_days=trace_days,
        selected_topic=selected_topic,
        followup_emotion=followup_emotion,
    )
    if not use_llm or provider is None:
        return local["echo"], local["next_focus"], local["note"], local["raw_markdown"], False

    messages = build_week_close_messages(
        week_start=week_start.isoformat(),
        week_end=week_end_for(week_start).isoformat(),
        followup_question=followup_question,
        followup_answer=followup_answer,
        traces=traces,
        trace_days=trace_days,
        selected_topic=selected_topic,
        followup_emotion=followup_emotion,
    )
    try:
        parsed = _parse_week_close_json(provider.chat(messages))
        if not parsed:
            logger.warning("周收束 LLM 返回无法解析，降级本地短收束")
            return local["echo"], local["next_focus"], local["note"], local["raw_markdown"], False
        raw = _format_week_archive(
            week_start=week_start,
            followup_question=followup_question,
            followup_answer=followup_answer,
            answers=answers,
            traces=traces,
            trace_days=trace_days,
            selected_topic=selected_topic,
            followup_emotion=followup_emotion,
            echo=parsed["echo"],
            next_focus=parsed["next_focus"],
            note=parsed["note"],
        )
        return parsed["echo"], parsed["next_focus"], parsed["note"], raw, True
    except Exception:
        logger.exception("周收束 LLM 失败，降级本地短收束")
        return local["echo"], local["next_focus"], local["note"], local["raw_markdown"], False


def close_week(
    db: Session,
    week_start: date,
    *,
    provider: LLMProvider | None = None,
    use_llm: bool = True,
) -> WeeklyReview:
    week = get_or_create_week(db, week_start)
    if week.status == WeekStatus.CLOSED.value:
        raise ConflictError("这一周已经收好了。")
    if week.status != WeekStatus.DRAFT.value:
        raise ConflictError("状态已变化，请刷新后再收周。")

    answers = _parse_answers(week.answers_json)
    traces, trace_days, _ = _require_trace_days(
        db, week_start, answers=answers, selected_topic=week.selected_topic
    )
    question = (week.followup_question or "").strip()
    answer = (week.followup_answer or "").strip()
    if not question:
        raise ValueError("还没有本周问句。先点「问自己一句（本周）」，再作答后收周。")
    if not answer:
        raise ValueError("还没写下回答。这句回答是本周最要紧的资产，写完再收。")

    claimed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.DRAFT.value).values(status=WeekStatus.CLOSING.value))
    if claimed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再收周。")
    db.commit()
    echo, next_focus, note, raw, _ = _generate_week_close_content(
        week_start=week_start,
        followup_question=question,
        followup_answer=answer,
        answers=answers,
        traces=traces,
        trace_days=trace_days,
        selected_topic=week.selected_topic or "",
        followup_emotion=week.followup_emotion or "",
        provider=provider,
        use_llm=use_llm,
    )

    changed = db.execute(update(WeeklyReview).where(WeeklyReview.id == week.id, WeeklyReview.status == WeekStatus.CLOSING.value).values(overview=echo, next_focus=next_focus, note=note, raw_markdown=raw, trace_days=trace_days, status=WeekStatus.CLOSED.value, updated_at=datetime.now()))
    if changed.rowcount != 1:
        db.rollback()
        raise ConflictError("状态已变化，请刷新后再收周。")
    db.commit()
    db.refresh(week)
    return week


def summarize_week(
    db: Session,
    week_start: date,
    *,
    provider: LLMProvider | None = None,
) -> WeeklyReview:
    """对已有周问+回答重新做极短收束（兼容旧 summarize 路由）。"""
    week = get_or_create_week(db, week_start)
    if week.status == WeekStatus.CLOSED.value:
        raise ConflictError("这一周已经收好了。")
    question = (week.followup_question or "").strip()
    answer = (week.followup_answer or "").strip()
    if not question or not answer:
        raise ValueError("需要先有本周问句和回答，才能再收束。")
    if provider is None:
        raise ValueError("还没配置模型密钥。可先在设置里填好，再请 AI 收一下。")

    answers = _parse_answers(week.answers_json)
    traces, trace_days, _ = _require_trace_days(
        db, week_start, answers=answers, selected_topic=week.selected_topic
    )
    echo, next_focus, note, raw, used_ai = _generate_week_close_content(
        week_start=week_start,
        followup_question=question,
        followup_answer=answer,
        answers=answers,
        traces=traces,
        trace_days=trace_days,
        selected_topic=week.selected_topic or "",
        followup_emotion=week.followup_emotion or "",
        provider=provider,
        use_llm=True,
    )
    if not used_ai:
        raise ValueError("模型这次没给出可用收束，请稍后再试。")

    week.overview = echo
    week.next_focus = next_focus
    week.note = note
    week.raw_markdown = raw
    week.trace_days = trace_days
    week.status = WeekStatus.CLOSED.value
    week.updated_at = datetime.now()
    db.commit()
    db.refresh(week)
    return week


def week_to_payload(db: Session, week: WeeklyReview) -> dict:
    end = week_end_for(week.week_start)
    traces, live_trace_days = aggregate_day_traces(db, week.week_start, end)
    answers = _parse_answers(week.answers_json)
    bootstrap_topic = _bootstrap_topic(answers) or (week.selected_topic or "").strip()
    trace_days = week.trace_days if week.status == WeekStatus.CLOSED.value else live_trace_days
    if trace_days == 0 and bootstrap_topic:
        traces = (
            "（起步模式：用户最近最想搞清楚的一件事）\n"
            f"{bootstrap_topic}"
        )
    echo = week.overview or ""
    return {
        "week_start": week.week_start,
        "week_end": end,
        "status": week.status,
        "answers": answers,
        "candidate_topics": _parse_topics(week.candidate_topics_json),
        "selected_topic": week.selected_topic or "",
        "followup_emotion": week.followup_emotion or "",
        "followup_question": week.followup_question or "",
        "followup_answer": week.followup_answer or "",
        "overview": echo,
        "echo": echo,
        "next_focus": getattr(week, "next_focus", "") or "",
        "note": getattr(week, "note", "") or "",
        "raw_markdown": week.raw_markdown,
        "trace_days": trace_days,
        "empty_days": max(0, 7 - live_trace_days),
        "bootstrap_topic": bootstrap_topic,
        "bootstrap_mode": bool(bootstrap_topic and live_trace_days == 0),
        "traces": traces,
        "created_at": week.created_at,
        "updated_at": week.updated_at,
    }
