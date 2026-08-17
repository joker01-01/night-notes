"""API 输入输出模型。"""

from __future__ import annotations

from datetime import date, datetime
from typing import Annotated

from pydantic import BaseModel, Field, ValidationInfo, field_validator

from app.core.llm_security import validate_llm_base_url


BoundedText = Annotated[str, Field(max_length=2000)]


class QAOut(BaseModel):
    id: int
    question: str
    answer: str
    order: int
    qa_type: str = "fixed"
    round: int = 0


class SummaryOut(BaseModel):
    overview: str
    learnings: str = ""
    blockers: str = ""
    next_plan: str = ""
    attribution: str = ""
    next_action: str = ""
    lesson: str = ""
    raw_markdown: str
    created_at: datetime


class SessionOut(BaseModel):
    date: date
    status: str
    emotion: str = ""
    qas: list[QAOut]
    summary: SummaryOut | None = None
    summary_soft_deleted: bool = False
    max_followup_rounds: int = 2


class AnswerInput(BaseModel):
    qa_id: int
    answer: str = Field(max_length=20000)


class AnswersUpdate(BaseModel):
    answers: list[AnswerInput] = Field(max_length=24)
    emotion: str = Field(default="", max_length=40)


class FollowupAnswerIn(BaseModel):
    qa_id: int
    answer: str = Field(min_length=1, max_length=20000)


class SummarizeIn(BaseModel):
    skip: bool = False


class RecoachIn(BaseModel):
    confirm: bool = False


class SettingsUpdate(BaseModel):
    llm_provider: str = Field(default="deepseek", max_length=40)
    llm_api_key: str = Field(default="", max_length=500)
    llm_base_url: str = Field(default="https://api.deepseek.com", max_length=500)
    llm_model: str = Field(default="deepseek-v4-pro", max_length=120)
    question_time: str = Field(default="21:00", max_length=8)
    context_days: int = Field(default=7, ge=1, le=90)
    # 可选自问参考种子；允许空。每日四问已废案，不驱动建会话出题。
    question_templates: list[BoundedText] = Field(default_factory=list, max_length=24)
    version: int | None = Field(default=None, ge=0)

    @field_validator("question_time")
    @classmethod
    def normalize_question_time(cls, value: str) -> str:
        # 浏览器 <input type="time"> 可能提交 HH:MM:SS，统一存为 HH:MM。
        parts = value.strip().split(":")
        if len(parts) not in {2, 3}:
            raise ValueError("提问时间格式应为 HH:MM")
        try:
            hour, minute = int(parts[0]), int(parts[1])
        except ValueError as exc:
            raise ValueError("提问时间格式应为 HH:MM") from exc
        if not (0 <= hour <= 23 and 0 <= minute <= 59):
            raise ValueError("提问时间格式应为 HH:MM")
        return f"{hour:02d}:{minute:02d}"

    @field_validator("llm_base_url")
    @classmethod
    def validate_base_url(cls, value: str, info: ValidationInfo) -> str:
        provider = str(info.data.get("llm_provider") or "deepseek")
        return validate_llm_base_url(value, provider)

    @field_validator("question_templates")
    @classmethod
    def validate_templates(cls, values: list[str]) -> list[str]:
        return [item.strip() for item in values if item.strip()]


class SettingsOut(SettingsUpdate):
    version: int = 1
    api_key_configured: bool


class CalendarDay(BaseModel):
    day: int
    status: str


class WeekAnswerItem(BaseModel):
    question: str = Field(min_length=1, max_length=500)
    answer: str = Field(default="", max_length=20000)


class WeekAnswersUpdate(BaseModel):
    answers: list[WeekAnswerItem] = Field(min_length=1, max_length=24)


class WeekFollowupIn(BaseModel):
    use_llm: bool = True


class WeekTopicsIn(BaseModel):
    use_llm: bool = True


class WeekTopicUpdate(BaseModel):
    topic: str = Field(default="", max_length=500)
    emotion: str = Field(default="", max_length=40)


class WeekFollowupAnswerIn(BaseModel):
    answer: str = Field(default="", max_length=20000)


class WeekCloseIn(BaseModel):
    use_llm: bool = True


class WeekOut(BaseModel):
    week_start: date
    week_end: date
    status: str
    answers: list[WeekAnswerItem]
    candidate_topics: list[str] = Field(default_factory=list)
    selected_topic: str = ""
    followup_emotion: str = ""
    followup_question: str = ""
    followup_answer: str = ""
    overview: str = ""  # 收束 echo
    echo: str = ""
    next_focus: str = ""
    note: str = ""
    raw_markdown: str = ""
    trace_days: int = 0
    empty_days: int = 0
    bootstrap_topic: str = ""
    bootstrap_mode: bool = False
    traces: str = ""
    created_at: datetime
    updated_at: datetime
