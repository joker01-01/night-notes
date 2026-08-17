from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
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
