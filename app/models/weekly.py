"""周场（重）会话与归档模型。"""

from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from sqlalchemy import Date, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class WeekStatus(str, Enum):
    DRAFT = "draft"
    CLOSED = "closed"
    TOPICS_GENERATING = "topics_generating"
    FOLLOWUP_GENERATING = "followup_generating"
    CLOSING = "closing"
    SUMMARIZING = "summarizing"


# 可选热身提纲（非主菜）；主资产是 followup_question + followup_answer
DEFAULT_WEEK_OUTLINE = [
    "最近最想搞清楚的一件事（起步时可选）",
    "这一周实际推进了什么",
    "反复出现的卡住",
    "下周只做一件",
]

COLD_START_QUESTION = DEFAULT_WEEK_OUTLINE[0]

# 无 Key / LLM 失败时的模板式轻问（承认材料有限，不编造「反复主题」）
TEMPLATE_WEEK_FOLLOWUP = (
    "这周你留下痕迹的那件事，当时对你更像期待、负担，还是别的什么分量？"
)


class WeeklyReview(Base):
    __tablename__ = "weekly_reviews"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    week_start: Mapped[date] = mapped_column(Date, unique=True, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=WeekStatus.DRAFT.value, nullable=False)
    # JSON 数组：[{"question": "...", "answer": "..."}, ...] — 可选提纲热身
    answers_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    # 核心资产：周问 + 回答
    candidate_topics_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    selected_topic: Mapped[str] = mapped_column(Text, default="", nullable=False)
    followup_emotion: Mapped[str] = mapped_column(String(40), default="", nullable=False)
    followup_question: Mapped[str] = mapped_column(Text, default="", nullable=False)
    followup_answer: Mapped[str] = mapped_column(Text, default="", nullable=False)
    # 极短收束：echo 存 overview；另两键独立列
    overview: Mapped[str] = mapped_column(Text, default="", nullable=False)
    next_focus: Mapped[str] = mapped_column(Text, default="", nullable=False)
    note: Mapped[str] = mapped_column(Text, default="", nullable=False)
    raw_markdown: Mapped[str] = mapped_column(Text, default="", nullable=False)
    trace_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.now, onupdate=datetime.now, nullable=False
    )
