"""日报相关的 SQLite 数据模型。"""

from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class SessionStatus(str, Enum):
    PENDING = "pending"
    ANSWERED = "answered"
    FOLLOWING_UP = "following_up"
    SUMMARIZED = "summarized"
    FOLLOWUP_GENERATING = "followup_generating"
    DEEPENING = "deepening"
    SUMMARIZING = "summarizing"


class QAType(str, Enum):
    FIXED = "fixed"
    FOLLOWUP = "followup"


class DailySession(Base):
    __tablename__ = "daily_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    date: Mapped[date] = mapped_column(Date, unique=True, index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=SessionStatus.PENDING.value, nullable=False)
    # 非诊断性的轻量情绪标记；只选情绪也算一条痕迹。
    emotion: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    qas: Mapped[list[QA]] = relationship(
        back_populates="session", cascade="all, delete-orphan", order_by="QA.order"
    )
    summary: Mapped[Summary | None] = relationship(
        back_populates="session", cascade="all, delete-orphan", uselist=False
    )


class QA(Base):
    __tablename__ = "qas"
    __table_args__ = (UniqueConstraint("session_id", "order", name="uq_qa_session_order"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("daily_sessions.id"), nullable=False)
    question: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, default="", nullable=False)
    order: Mapped[int] = mapped_column(Integer, nullable=False)
    # fixed=今晚正文（或旧四问废案条目）；followup=可选自问。旧库缺列时由 ensure_schema 补齐。
    qa_type: Mapped[str] = mapped_column(String(20), default=QAType.FIXED.value, nullable=False)
    round: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    session: Mapped[DailySession] = relationship(back_populates="qas")


class Summary(Base):
    __tablename__ = "summaries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("daily_sessions.id"), unique=True, nullable=False)
    overview: Mapped[str] = mapped_column(Text, nullable=False)
    # V1 字段保留：新复盘写入时做兼容映射，旧记录展示仍可读。
    learnings: Mapped[str] = mapped_column(Text, nullable=False)
    blockers: Mapped[str] = mapped_column(Text, nullable=False)
    next_plan: Mapped[str] = mapped_column(Text, nullable=False)
    # V2 追问式复盘字段；旧行为空字符串。
    attribution: Mapped[str] = mapped_column(Text, default="", nullable=False)
    next_action: Mapped[str] = mapped_column(Text, default="", nullable=False)
    lesson: Mapped[str] = mapped_column(Text, default="", nullable=False)
    raw_markdown: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now, nullable=False)
    # 重开不抹除历史收束；恢复入口只需清除此时间戳。
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    session: Mapped[DailySession] = relationship(back_populates="summary")
