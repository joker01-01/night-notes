"""本地设置的读取与写入。"""

from __future__ import annotations

import json

from typing import Any

from sqlalchemy import select
from sqlalchemy import update as sa_update
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session

from app.core.config import get_config
from app.core.errors import ConflictError
from app.core.llm_security import validate_llm_base_url
from app.core.secrets import decrypt_secret, encrypt_secret, is_encrypted
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
        if settings.llm_api_key and not is_encrypted(settings.llm_api_key):
            settings.llm_api_key = encrypt_secret(settings.llm_api_key)
            db.commit()
            db.refresh(settings)
        # 自动修复曾被错误编码写成 ???? 的问题模板，避免设置页与降级提问继续乱码。
        if _templates_look_corrupted(settings.question_templates):
            settings.question_templates = json.dumps(defaults.question_templates, ensure_ascii=False)
            db.commit()
            db.refresh(settings)
        return settings
    settings = Settings(
        id=1,
        llm_provider=defaults.llm_provider,
        llm_api_key=encrypt_secret(defaults.llm_api_key),
        llm_base_url=defaults.llm_base_url,
        llm_model=defaults.llm_model,
        question_time=defaults.question_time,
        context_days=defaults.context_days,
        question_templates=json.dumps(defaults.question_templates, ensure_ascii=False),
        version=1,
    )
    db.add(settings)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.scalar(select(Settings).where(Settings.id == 1))
        if existing is not None:
            return existing
        raise
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
        version=settings.version,
        api_key_configured=bool(settings.llm_api_key),
    )


def update_settings(db: Session, update: SettingsUpdate) -> Settings:
    settings = get_or_create_settings(db)
    if update.version is not None and update.version != settings.version:
        raise ConflictError("设置已被另一处修改，请先重新读取后再保存。")
    fields = update.model_fields_set
    provider = update.llm_provider if "llm_provider" in fields else settings.llm_provider
    base_url = update.llm_base_url if "llm_base_url" in fields else settings.llm_base_url
    validate_llm_base_url(base_url, provider)
    changes: dict[str, Any] = {}
    if "llm_provider" in fields:
        changes["llm_provider"] = update.llm_provider
    # 设置页面留空时保持原密钥，避免读取接口泄漏并防止误清除。
    if "llm_api_key" in fields and update.llm_api_key:
        changes["llm_api_key"] = encrypt_secret(update.llm_api_key)
    if "llm_base_url" in fields:
        changes["llm_base_url"] = update.llm_base_url
    if "llm_model" in fields:
        changes["llm_model"] = update.llm_model
    if "question_time" in fields:
        changes["question_time"] = update.question_time
    if "context_days" in fields:
        changes["context_days"] = update.context_days
    if "question_templates" in fields:
        changes["question_templates"] = json.dumps(update.question_templates, ensure_ascii=False)
    changes["version"] = settings.version + 1
    # 单条条件 UPDATE：并发写入只有一个能成功，另一个得到 409。
    try:
        claimed = db.execute(
            sa_update(Settings)
            .where(Settings.id == 1, Settings.version == settings.version)
            .values(**changes)
        )
    except OperationalError as exc:
        # WAL 读快照升级冲突表现为 database is locked（busy_timeout 不覆盖），
        # 对调用方等同于“已被另一处修改”。
        db.rollback()
        if "locked" in str(exc).lower():
            raise ConflictError("设置已被另一处修改，请先重新读取后再保存。") from exc
        raise
    if claimed.rowcount != 1:
        db.rollback()
        raise ConflictError("设置已被另一处修改，请先重新读取后再保存。")
    db.commit()
    db.refresh(settings)
    return settings


def get_templates(settings: Settings) -> list[str]:
    return json.loads(settings.question_templates)


def get_provider(db: Session):
    settings = get_or_create_settings(db)
    validate_llm_base_url(settings.llm_base_url, settings.llm_provider)
    return create_provider(
        ProviderConfig(
            provider=settings.llm_provider,
            api_key=decrypt_secret(settings.llm_api_key),
            base_url=settings.llm_base_url,
            model=settings.llm_model,
        )
    )
