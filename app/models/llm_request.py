"""LLM 触发请求的幂等占位记录：同一 X-Request-Id 只允许执行一次。"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class LlmRequest(Base):
    __tablename__ = "llm_requests"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    request_id: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    route: Mapped[str] = mapped_column(String(120), nullable=False)
    resource: Mapped[str] = mapped_column(String(40), nullable=False)
    # claimed -> done | failed（failed 允许同一 request_id 重新占位）
    status: Mapped[str] = mapped_column(String(20), default="claimed", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now, nullable=False)
