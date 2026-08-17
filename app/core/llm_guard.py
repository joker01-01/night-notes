"""LLM 触发路由的幂等占位与结果标记。

同一 `X-Request-Id` 只允许执行一次付费 LLM 操作：
占位发生在触发 LLM 之前（独立 commit），因此并发重复请求会撞到
UNIQUE(request_id) 或已存在的 claimed/done 记录，被 409 挡下。
失败（LLM 不可用等）会释放占位，允许同一 request_id 显式重试。
"""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import ConflictError
from app.models import LlmRequest

REQUEST_TTL_SECONDS = 24 * 3600


def claim_request(db: Session, request_id: str | None, route: str, resource: str) -> bool:
    """占位一次 LLM 触发；重复占位抛 ConflictError（409）。返回是否成功占位。"""
    cleaned = (request_id or "").strip()
    if not cleaned:
        return False  # 未带标识的旧客户端不受幂等保护，但受状态机与限流保护
    if len(cleaned) > 64:
        raise ConflictError("请求标识无效。")
    existing = db.scalar(select(LlmRequest).where(LlmRequest.request_id == cleaned))
    if existing is not None:
        if existing.status == "failed":
            existing.status = "claimed"
            existing.route = route
            existing.resource = resource
            existing.created_at = datetime.now()
            db.commit()
            return True
        raise ConflictError("该操作已提交过，请勿重复点击；可刷新查看结果。")
    db.add(LlmRequest(request_id=cleaned, route=route, resource=resource, status="claimed"))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise ConflictError("该操作已提交过，请勿重复点击；可刷新查看结果。") from None
    cutoff = datetime.now() - timedelta(seconds=REQUEST_TTL_SECONDS)
    db.execute(delete(LlmRequest).where(LlmRequest.created_at < cutoff))
    db.commit()
    return True


def mark_request(db: Session, request_id: str | None, outcome: str) -> None:
    """占位结束后标记 done / failed。"""
    cleaned = (request_id or "").strip()
    if not cleaned:
        return
    existing = db.scalar(select(LlmRequest).where(LlmRequest.request_id == cleaned))
    if existing is not None:
        existing.status = "done" if outcome == "done" else "failed"
        db.commit()
