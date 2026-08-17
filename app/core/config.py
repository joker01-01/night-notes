"""配置加载：config.yaml 提供默认值，.env / 环境变量覆盖它。"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


ROOT_DIR = Path(__file__).resolve().parents[2]


class AppConfig(BaseSettings):
    """非敏感默认项可放 YAML，密钥应优先放在 .env。"""

    model_config = SettingsConfigDict(
        env_file=ROOT_DIR / ".env",
        env_file_encoding="utf-8",
        env_prefix="AI_REVIEW_",
        extra="ignore",
    )

    database_url: str = "sqlite:///./data/ai_daily_review.db"
    llm_provider: str = "deepseek"
    llm_api_key: str = ""
    llm_base_url: str = "https://api.deepseek.com"
    llm_model: str = "deepseek-v4-pro"
    question_time: str = "21:00"
    context_days: int = Field(default=7, ge=1, le=90)
    question_templates: list[str] = Field(default_factory=list)
    bind_host: str = "127.0.0.1"
    allow_lan: bool = False
    llm_allowed_hosts: list[str] = Field(default_factory=lambda: ["api.deepseek.com"])


def _yaml_defaults() -> dict[str, Any]:
    path = ROOT_DIR / "config.yaml"
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as stream:
        return yaml.safe_load(stream) or {}


@lru_cache(maxsize=1)
def get_config() -> AppConfig:
    """合并 YAML 与 pydantic-settings 解析到的环境变量。

    model_fields_set 只包含用户明确提供的环境/.env 值，因而不会用代码
    默认值意外覆盖 config.yaml。
    """
    from_environment = AppConfig()
    values = _yaml_defaults()
    for field in from_environment.model_fields_set:
        values[field] = getattr(from_environment, field)
    return AppConfig.model_validate(values)
