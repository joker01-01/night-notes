"""单行设置表；所有个人设置默认只落在本机 SQLite。"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Settings(Base):
    __tablename__ = "settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    llm_provider: Mapped[str] = mapped_column(String(40), nullable=False)
    llm_api_key: Mapped[str] = mapped_column(Text, default="", nullable=False)
    llm_base_url: Mapped[str] = mapped_column(Text, nullable=False)
    llm_model: Mapped[str] = mapped_column(String(120), nullable=False)
    question_time: Mapped[str] = mapped_column(String(5), nullable=False)
    context_days: Mapped[int] = mapped_column(Integer, nullable=False)
    question_templates: Mapped[str] = mapped_column(Text, nullable=False)  # JSON 字符串
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.now, onupdate=datetime.now, nullable=False
    )
