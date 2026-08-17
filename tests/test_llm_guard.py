from __future__ import annotations

from datetime import date

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import Base
from app.core.errors import ConflictError
from app.core.llm_guard import claim_request, mark_request
from app.core.rate_limit import rate_limit, rate_limit_llm, reset_rate_limits
from app.models import LlmRequest


def make_db() -> Session:
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


def test_claim_is_once_per_request_id() -> None:
    db = make_db()
    assert claim_request(db, "rid-1", "route", "resource") is True
    with pytest.raises(ConflictError):
        claim_request(db, "rid-1", "route", "resource")
    row = db.query(LlmRequest).filter_by(request_id="rid-1").one()
    assert row.status == "claimed"


def test_failed_claim_can_be_retried_with_same_id() -> None:
    db = make_db()
    claim_request(db, "rid-2", "route", "resource")
    mark_request(db, "rid-2", "failed")
    assert claim_request(db, "rid-2", "route", "resource") is True
    mark_request(db, "rid-2", "done")
    with pytest.raises(ConflictError):
        claim_request(db, "rid-2", "route", "resource")


def test_claim_without_request_id_is_a_noop() -> None:
    db = make_db()
    assert claim_request(db, None, "route", "resource") is False
    assert db.query(LlmRequest).count() == 0


def test_rate_limit_throttles_llm_bucket() -> None:
    reset_rate_limits()
    for _ in range(10):
        rate_limit_llm()
    with pytest.raises(HTTPException) as excinfo:
        rate_limit_llm()
    assert excinfo.value.status_code == 429
    assert excinfo.value.headers["Retry-After"]
    reset_rate_limits()


def test_rate_limit_throttles_settings_bucket() -> None:
    reset_rate_limits()
    for _ in range(20):
        rate_limit("settings")
    with pytest.raises(HTTPException) as excinfo:
        rate_limit("settings")
    assert excinfo.value.status_code == 429
    reset_rate_limits()
