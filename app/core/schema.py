"""SQLite 轻量补列：旧库无 Alembic 时在启动补齐 V2 字段。"""

from __future__ import annotations

import logging

from sqlalchemy import text
from sqlalchemy.engine import Engine

logger = logging.getLogger(__name__)

# table -> [(column, sqlite_type_with_default)]
_REQUIRED_COLUMNS: dict[str, list[tuple[str, str]]] = {
    "daily_sessions": [
        ("emotion", "VARCHAR(40) NOT NULL DEFAULT ''"),
    ],
    "qas": [
        ("qa_type", "VARCHAR(20) NOT NULL DEFAULT 'fixed'"),
        ("round", "INTEGER NOT NULL DEFAULT 0"),
    ],
    "summaries": [
        ("attribution", "TEXT NOT NULL DEFAULT ''"),
        ("next_action", "TEXT NOT NULL DEFAULT ''"),
        ("lesson", "TEXT NOT NULL DEFAULT ''"),
    ],
    "weekly_reviews": [
        ("candidate_topics_json", "TEXT NOT NULL DEFAULT '[]'"),
        ("selected_topic", "TEXT NOT NULL DEFAULT ''"),
        ("followup_emotion", "VARCHAR(40) NOT NULL DEFAULT ''"),
        ("followup_question", "TEXT NOT NULL DEFAULT ''"),
        ("followup_answer", "TEXT NOT NULL DEFAULT ''"),
        ("next_focus", "TEXT NOT NULL DEFAULT ''"),
        ("note", "TEXT NOT NULL DEFAULT ''"),
    ],
    "settings": [
        ("version", "INTEGER NOT NULL DEFAULT 1"),
    ],
    "summaries": [
        ("deleted_at", "DATETIME"),
    ],
}


def ensure_schema(engine: Engine) -> None:
    """检测并 ADD COLUMN；已存在则跳过。仅覆盖本项目已知的增量列。"""
    with engine.begin() as conn:
        for table, columns in _REQUIRED_COLUMNS.items():
            existing = {
                row[1]
                for row in conn.execute(text(f"PRAGMA table_info({table})")).fetchall()
            }
            if not existing:
                # 表尚未创建时由 create_all 负责，这里不处理。
                continue
            for name, ddl in columns:
                if name in existing:
                    continue
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {name} {ddl}"))
                logger.info("ensure_schema: added %s.%s", table, name)
