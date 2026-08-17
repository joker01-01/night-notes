"""Local-only bearer token used to protect the web API.

The application is designed for one user on one machine.  The token is not
an account system; it is a small boundary that prevents a browser on the LAN
or a DNS-rebinding page from calling the local API without the user's browser
having bootstrapped it first.
"""

from __future__ import annotations

import hmac
import ipaddress
import os
import secrets
from pathlib import Path

from fastapi import HTTPException, Request

from app.core.config import ROOT_DIR


TOKEN_PATH = ROOT_DIR / "data" / ".app-token"
BOOTSTRAP_MARKER_PATH = ROOT_DIR / "data" / ".app-token-consumed"


def _write_private(path: Path, value: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    try:
        descriptor = os.open(path, flags, 0o600)
    except FileExistsError:
        return False
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(value)
    finally:
        try:
            path.chmod(0o600)
        except OSError:
            # Windows ACLs, rather than POSIX mode bits, control the file.
            pass
    return True


def ensure_app_token() -> str:
    """Create the token once and return it without ever logging its value."""

    TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not TOKEN_PATH.exists():
        _write_private(TOKEN_PATH, secrets.token_urlsafe(32))
    token = TOKEN_PATH.read_text(encoding="utf-8").strip()
    if len(token) < 32:
        # A truncated/manual file must not silently weaken authentication.
        TOKEN_PATH.unlink(missing_ok=True)
        _write_private(TOKEN_PATH, secrets.token_urlsafe(32))
        token = TOKEN_PATH.read_text(encoding="utf-8").strip()
    return token


def is_loopback_request(request: Request) -> bool:
    host = request.client.host if request.client else ""
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return host.lower() in {"localhost", "ip6-localhost"}


def bootstrap_token(request: Request) -> str:
    """Return the token once, and only to a loopback client."""

    if not is_loopback_request(request):
        raise HTTPException(status_code=403, detail="只能在本机初始化访问令牌。")
    if BOOTSTRAP_MARKER_PATH.exists():
        raise HTTPException(status_code=403, detail="访问令牌已经初始化。")
    token = ensure_app_token()
    try:
        claimed = _write_private(BOOTSTRAP_MARKER_PATH, "consumed")
    except OSError:
        raise HTTPException(status_code=503, detail="暂时无法初始化访问令牌。") from None
    if not claimed:
        raise HTTPException(status_code=403, detail="访问令牌已经初始化。")
    return token


def _candidate_token(request: Request) -> str:
    authorization = request.headers.get("authorization", "")
    scheme, _, value = authorization.partition(" ")
    if scheme.lower() == "bearer" and value.strip():
        return value.strip()
    return request.headers.get("x-night-token", "").strip()


def require_auth(request: Request) -> None:
    expected = ensure_app_token()
    supplied = _candidate_token(request)
    if not supplied or not hmac.compare_digest(supplied, expected):
        raise HTTPException(
            status_code=401,
            detail="需要本机访问令牌。",
            headers={"WWW-Authenticate": "Bearer"},
        )
