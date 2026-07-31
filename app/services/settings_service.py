"""本地设置的读取与写入。"""

from __future__ import annotations

import json

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_config
from app.llm import ProviderConfig, create_provider
from app.models import Settings
from app.schemas import SettingsOut, SettingsUpdate


def _templates_look_corrupted(raw: str) -> bool:
    """检测历史错误代码页写入后只剩问号的模板。空列表合法（四问已废案）。"""
    try:
        items = json.loads(raw)
    except (TypeError, ValueError, json.JSONDecodeError):
        return True
    if not isinstance(items, list):
        return True
    if not items:
        return False
    return all(isinstance(item, str) and item and set(item) <= {"?"} for item in items)


def get_or_create_settings(db: Session) -> Settings:
    settings = db.scalar(select(Settings).where(Settings.id == 1))
    defaults = get_config()
    if settings is not None:
        # 自动修复曾被错误编码写成 ???? 的问题模板，避免设置页与降级提问继续乱码。
        if _templates_look_corrupted(settings.question_templates):
            settings.question_templates = json.dumps(defaults.question_templates, ensure_ascii=False)
            db.commit()
            db.refresh(settings)
        return settings
    settings = Settings(
        id=1,
        llm_provider=defaults.llm_provider,
        llm_api_key=defaults.llm_api_key,
        llm_base_url=defaults.llm_base_url,
        llm_model=defaults.llm_model,
        question_time=defaults.question_time,
        context_days=defaults.context_days,
        question_templates=json.dumps(defaults.question_templates, ensure_ascii=False),
    )
    db.add(settings)
    db.commit()
    db.refresh(settings)
    return settings


def as_settings_out(settings: Settings) -> SettingsOut:
    return SettingsOut(
        llm_provider=settings.llm_provider,
        # 不把已保存的密钥回传给浏览器；空值代表不修改已有密钥。
        llm_api_key="",
        llm_base_url=settings.llm_base_url,
        llm_model=settings.llm_model,
        question_time=settings.question_time,
        context_days=settings.context_days,
        question_templates=json.loads(settings.question_templates),
        api_key_configured=bool(settings.llm_api_key),
    )


def update_settings(db: Session, update: SettingsUpdate) -> Settings:
    settings = get_or_create_settings(db)
    settings.llm_provider = update.llm_provider
    # 设置页面留空时保持原密钥，避免读取接口泄漏并防止误清除。
    if update.llm_api_key:
        settings.llm_api_key = update.llm_api_key
    settings.llm_base_url = update.llm_base_url
    settings.llm_model = update.llm_model
    settings.question_time = update.question_time
    settings.context_days = update.context_days
    settings.question_templates = json.dumps(update.question_templates, ensure_ascii=False)
    db.commit()
    db.refresh(settings)
    return settings


def get_templates(settings: Settings) -> list[str]:
    return json.loads(settings.question_templates)


def get_provider(db: Session):
    settings = get_or_create_settings(db)
    return create_provider(
        ProviderConfig(
            provider=settings.llm_provider,
            api_key=settings.llm_api_key,
            base_url=settings.llm_base_url,
            model=settings.llm_model,
        )
    )

