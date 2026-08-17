from __future__ import annotations

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.errors import ConflictError
from app.services.settings_service import get_or_create_settings, update_settings
from app.schemas import SettingsUpdate


def test_partial_settings_update_preserves_omitted_values() -> None:
    db = sessionmaker(bind=create_engine("sqlite:///:memory:"))()
    Base.metadata.create_all(db.bind)
    settings = get_or_create_settings(db)
    original_url = settings.llm_base_url
    updated = update_settings(db, SettingsUpdate(question_templates=["只改这个"]))
    assert updated.llm_base_url == original_url
    assert updated.question_templates == '["只改这个"]'


def test_concurrent_settings_updates_conflict(tmp_path) -> None:
    """两条并发会话以同一 version 写入：恰一个成功，另一个得到 ConflictError。"""
    import threading

    engine = create_engine(
        f"sqlite:///{tmp_path / 'settings.db'}", connect_args={"check_same_thread": False}
    )
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine)
    version = get_or_create_settings(factory()).version
    outcomes: list[str] = []

    def write(value: str) -> None:
        db = factory()
        try:
            update_settings(
                db, SettingsUpdate(version=version, question_templates=[value])
            )
            outcomes.append("ok")
        except ConflictError:
            outcomes.append("conflict")
        except Exception:
            outcomes.append("error")
        finally:
            db.close()

    for _ in range(8):
        outcomes.clear()
        threads = [threading.Thread(target=write, args=(f"t-{i}",)) for i in range(2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        assert "error" not in outcomes
        assert outcomes.count("ok") == 1 and outcomes.count("conflict") == 1
        version = get_or_create_settings(factory()).version


def test_stale_version_is_rejected() -> None:
    db = sessionmaker(bind=create_engine("sqlite:///:memory:"))()
    Base.metadata.create_all(db.bind)
    settings = get_or_create_settings(db)
    v1 = settings.version
    updated = update_settings(db, SettingsUpdate(version=v1, llm_model="x"))
    assert updated.version == v1 + 1
    with pytest.raises(ConflictError):
        update_settings(db, SettingsUpdate(version=v1, llm_model="y"))
