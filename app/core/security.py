"""HTTP boundary hardening for the local web application."""

from __future__ import annotations

from urllib.parse import urlsplit

from fastapi import Request
from fastapi.responses import JSONResponse


MAX_REQUEST_BODY_BYTES = 1 * 1024 * 1024
_LOCAL_ORIGIN_HOSTS = {"localhost", "127.0.0.1", "[::1]", "::1"}


def _allowed_origin(origin: str) -> bool:
    if not origin or origin == "null":
        return False
    parsed = urlsplit(origin)
    if parsed.scheme != "http" or not parsed.hostname:
        return False
    return parsed.hostname.lower() in _LOCAL_ORIGIN_HOSTS


async def request_security_boundary(request: Request, call_next):
    """Reject cross-origin mutations and oversized JSON before route handling."""

    path = request.url.path
    is_api = path == "/api" or path.startswith("/api/")
    if is_api:
        origin = request.headers.get("origin")
        if origin is not None and not _allowed_origin(origin):
            return JSONResponse(status_code=403, content={"detail": "不允许的来源。"})

        if request.method in {"POST", "PUT", "PATCH", "DELETE"}:
            content_type = request.headers.get("content-type", "")
            if content_type.split(";", 1)[0].strip().lower() != "application/json":
                return JSONResponse(
                    status_code=415,
                    content={"detail": "状态变更请求必须使用 application/json。"},
                )
            content_length = request.headers.get("content-length")
            if content_length is not None:
                try:
                    too_large = int(content_length) > MAX_REQUEST_BODY_BYTES
                except ValueError:
                    too_large = True
                if too_large:
                    return JSONResponse(status_code=413, content={"detail": "请求体过大。"})

    response = await call_next(request)
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault(
        "Content-Security-Policy",
        "default-src 'self'; frame-ancestors 'none'; base-uri 'self'; object-src 'none'",
    )
    if is_api:
        response.headers["Cache-Control"] = "no-store"
    return response
