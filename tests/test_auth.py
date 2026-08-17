from __future__ import annotations

from fastapi.testclient import TestClient

from app.core import auth
from app.main import app


def test_api_requires_a_local_token(monkeypatch, tmp_path) -> None:
    """Every private API route rejects missing and incorrect bearer tokens."""
    monkeypatch.setattr(auth, "TOKEN_PATH", tmp_path / ".app-token")
    monkeypatch.setattr(auth, "BOOTSTRAP_MARKER_PATH", tmp_path / ".app-token-consumed")
    token = auth.ensure_app_token()
    with TestClient(app, base_url="http://localhost") as client:
        assert client.get("/api/settings").status_code == 401
        assert client.get("/api/settings", headers={"Authorization": "Bearer wrong"}).status_code == 401
        assert client.get("/api/settings", headers={"X-Night-Token": token}).status_code == 200


def test_host_rebinding_is_rejected() -> None:
    with TestClient(app, base_url="http://localhost") as client:
        assert client.get("/api/health", headers={"Host": "evil.example"}).status_code == 400
