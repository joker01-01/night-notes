from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import extract, select
from sqlalchemy.orm import Session

from app.core.auth import bootstrap_token as issue_bootstrap_token, require_auth
from app.core.database import get_db
from app.core.errors import ConflictError
from app.llm.providers import LLMRequestError
from app.models import DailySession
from app.scheduler import review_scheduler
from app.schemas import (
    AnswersUpdate,
    CalendarDay,
    FollowupAnswerIn,
    RecoachIn,
    SessionOut,
    SettingsOut,
    SettingsUpdate,
    SummarizeIn,
    WeekAnswersUpdate,
    WeekCloseIn,
    WeekFollowupAnswerIn,
    WeekFollowupIn,
    WeekTopicUpdate,
    WeekTopicsIn,
    WeekOut,
)
from app.services.report_service import aggregate_summaries
from app.services.review_service import (
    answer_followup,
    create_session_if_needed,
    deepen_followup,
    get_session,
    reset_for_recoach,
    save_answers,
    session_to_schema,
    start_followup,
    summarize_session,
)
from app.services.settings_service import (
    as_settings_out,
    get_or_create_settings,
    get_provider,
    update_settings,
)
from app.services.week_service import (
    close_week,
    generate_week_followup,
    generate_week_topics,
    get_or_create_week,
    save_week_answers,
    save_week_followup_answer,
    save_week_topic,
    summarize_week,
    week_start_for,
    week_to_payload,
)


public_router = APIRouter(prefix="/api")
router = APIRouter(prefix="/api", dependencies=[Depends(require_auth)])


def _llm_http(exc: Exception) -> HTTPException:
    if isinstance(exc, ConflictError):
        return HTTPException(status_code=409, detail=str(exc))
    if isinstance(exc, LLMRequestError):
        return HTTPException(status_code=502, detail="模型服务暂时不可用，请稍后重试。")
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    if isinstance(exc, RuntimeError):
        return HTTPException(status_code=400, detail=str(exc))
    return HTTPException(status_code=500, detail="服务器内部错误")


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/settings", response_model=SettingsOut)
def read_settings(db: Session = Depends(get_db)) -> SettingsOut:
    return as_settings_out(get_or_create_settings(db))


@router.put("/settings", response_model=SettingsOut)
def write_settings(update: SettingsUpdate, db: Session = Depends(get_db)) -> SettingsOut:
    settings = update_settings(db, update)
    review_scheduler.refresh(settings.question_time)
    return as_settings_out(settings)


@router.post("/sessions/today/open", response_model=SessionOut)
def open_today(db: Session = Depends(get_db)) -> SessionOut:
    """供用户手动开始，未配置 API 时会直接用问题模板。"""
    try:
        provider = get_provider(db)
    except Exception:
        provider = None
    return session_to_schema(create_session_if_needed(db, date.today(), provider))


@router.get("/sessions/{day}", response_model=SessionOut)
def read_session(day: date, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘记录")
    return session_to_schema(session)


@router.put("/sessions/{day}/answers", response_model=SessionOut)
def write_answers(day: date, payload: AnswersUpdate, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    try:
        return session_to_schema(
            save_answers(
                db,
                session,
                {item.qa_id: item.answer for item in payload.answers},
                emotion=payload.emotion,
            )
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/sessions/{day}/followup/start", response_model=SessionOut)
def followup_start(day: date, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    try:
        return session_to_schema(start_followup(db, session, get_provider(db)))
    except Exception as exc:
        raise _llm_http(exc) from exc


@router.post("/sessions/{day}/followup/answer", response_model=SessionOut)
def followup_answer(day: date, payload: FollowupAnswerIn, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    try:
        return session_to_schema(answer_followup(db, session, payload.qa_id, payload.answer))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/sessions/{day}/followup/deeper", response_model=SessionOut)
def followup_deeper(day: date, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    try:
        return session_to_schema(deepen_followup(db, session, get_provider(db)))
    except Exception as exc:
        raise _llm_http(exc) from exc


@router.post("/sessions/{day}/recoach", response_model=SessionOut)
def recoach(day: date, db: Session = Depends(get_db)) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    return session_to_schema(reset_for_recoach(db, session))


@router.post("/sessions/{day}/summarize", response_model=SessionOut)
def make_summary(
    day: date, payload: SummarizeIn | None = None, db: Session = Depends(get_db)
) -> SessionOut:
    session = get_session(db, day)
    if session is None:
        raise HTTPException(status_code=404, detail="当天尚无复盘会话")
    skip = bool(payload.skip) if payload else False
    try:
        return session_to_schema(summarize_session(db, session, get_provider(db), skip=skip))
    except Exception as exc:
        raise _llm_http(exc) from exc


@router.get("/calendar", response_model=list[CalendarDay])
def calendar_days(
    year: int = Query(ge=2000, le=2100),
    month: int = Query(ge=1, le=12),
    db: Session = Depends(get_db),
) -> list[CalendarDay]:
    sessions = db.scalars(
        select(DailySession).where(
            extract("year", DailySession.date) == year, extract("month", DailySession.date) == month
        )
    ).all()
    return [CalendarDay(day=item.date.day, status=item.status) for item in sessions]


@router.get("/reports/context")
def report_context(
    days: int = Query(default=7, ge=1, le=90), db: Session = Depends(get_db)
) -> dict[str, str | int]:
    """近 N 日痕迹：优先 Summary，其次未收束日正文。"""
    return {"days": days, "context": aggregate_summaries(db, date.today(), days)}


@router.get("/weeks/current", response_model=WeekOut)
def read_current_week(db: Session = Depends(get_db)) -> WeekOut:
    week = get_or_create_week(db, week_start_for(date.today()))
    return WeekOut.model_validate(week_to_payload(db, week))


@router.get("/weeks/{week_start}", response_model=WeekOut)
def read_week(week_start: date, db: Session = Depends(get_db)) -> WeekOut:
    week = get_or_create_week(db, week_start_for(week_start))
    # 若传入的不是周日，仍归一到该日所在周
    return WeekOut.model_validate(week_to_payload(db, week))


@router.put("/weeks/{week_start}/answers", response_model=WeekOut)
def write_week_answers(
    week_start: date, payload: WeekAnswersUpdate, db: Session = Depends(get_db)
) -> WeekOut:
    try:
        week = save_week_answers(
            db,
            week_start_for(week_start),
            [item.model_dump() for item in payload.answers],
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.post("/weeks/{week_start}/followup", response_model=WeekOut)
def generate_week_followup_route(
    week_start: date,
    payload: WeekFollowupIn | None = None,
    db: Session = Depends(get_db),
) -> WeekOut:
    """生成【一个】周问。无 Key / 失败时降级模板轻问（见 CHANGELOG 默认策略）。"""
    use_llm = True if payload is None else bool(payload.use_llm)
    provider = None
    if use_llm:
        try:
            provider = get_provider(db)
        except Exception:
            provider = None
    try:
        week = generate_week_followup(
            db,
            week_start_for(week_start),
            provider=provider,
            use_llm=use_llm and provider is not None,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise _llm_http(exc) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.post("/weeks/{week_start}/topics", response_model=WeekOut)
def generate_week_topics_route(
    week_start: date,
    payload: WeekTopicsIn | None = None,
    db: Session = Depends(get_db),
) -> WeekOut:
    """生成 2～3 个可选周场主题；无 Key 时使用本地可解释兜底。"""
    use_llm = True if payload is None else bool(payload.use_llm)
    provider = None
    if use_llm:
        try:
            provider = get_provider(db)
        except Exception:
            provider = None
    try:
        week = generate_week_topics(
            db,
            week_start_for(week_start),
            provider=provider,
            use_llm=use_llm and provider is not None,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise _llm_http(exc) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.put("/weeks/{week_start}/topic", response_model=WeekOut)
def write_week_topic(
    week_start: date, payload: WeekTopicUpdate, db: Session = Depends(get_db)
) -> WeekOut:
    try:
        week = save_week_topic(
            db,
            week_start_for(week_start),
            payload.topic,
            emotion=payload.emotion,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.put("/weeks/{week_start}/followup", response_model=WeekOut)
def write_week_followup_answer(
    week_start: date, payload: WeekFollowupAnswerIn, db: Session = Depends(get_db)
) -> WeekOut:
    try:
        week = save_week_followup_answer(
            db, week_start_for(week_start), payload.answer
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.post("/weeks/{week_start}/close", response_model=WeekOut)
def close_week_route(
    week_start: date,
    payload: WeekCloseIn | None = None,
    db: Session = Depends(get_db),
) -> WeekOut:
    """基于周问+回答做极短收束；无 Key / 失败时本地短收束。"""
    use_llm = True if payload is None else bool(payload.use_llm)
    provider = None
    if use_llm:
        try:
            provider = get_provider(db)
        except Exception:
            provider = None
    try:
        week = close_week(
            db,
            week_start_for(week_start),
            provider=provider,
            use_llm=use_llm and provider is not None,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return WeekOut.model_validate(week_to_payload(db, week))


@router.post("/weeks/{week_start}/summarize", response_model=WeekOut)
def summarize_week_route(week_start: date, db: Session = Depends(get_db)) -> WeekOut:
    """兼容旧路由：对已有周问+回答重新做极短收束（非大周报）。"""
    try:
        provider = get_provider(db)
    except Exception:
        provider = None
    try:
        week = summarize_week(db, week_start_for(week_start), provider=provider)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise _llm_http(exc) from exc
    return WeekOut.model_validate(week_to_payload(db, week))
