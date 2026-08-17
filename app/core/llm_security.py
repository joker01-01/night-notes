"""Validation for user-configured LLM egress destinations."""

from __future__ import annotations

import ipaddress
from urllib.parse import urlsplit

from app.core.config import get_config


def validate_llm_base_url(value: str, provider: str = "deepseek") -> str:
    cleaned = value.strip().rstrip("/")
    parsed = urlsplit(cleaned)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("Base URL 必须是带主机名的 http/https 地址")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("Base URL 不允许携带用户名或密码")
    if parsed.query or parsed.fragment:
        raise ValueError("Base URL 不允许携带 query 或 fragment")
    try:
        port = parsed.port
    except ValueError as exc:
        raise ValueError("Base URL 端口无效") from exc

    hostname = parsed.hostname.rstrip(".").lower()
    normalized_provider = provider.strip().lower()
    local_hosts = {"localhost", "127.0.0.1", "::1"}
    if hostname in local_hosts:
        if normalized_provider != "ollama":
            raise ValueError("本地 LLM 地址只能配合 ollama provider 使用")
        if parsed.scheme != "http" or port is None:
            raise ValueError("本地 Ollama 地址必须是带显式端口的 http URL")
        return cleaned

    try:
        address = ipaddress.ip_address(hostname)
    except ValueError:
        address = None
    if address is not None and (
        address.is_private
        or address.is_loopback
        or address.is_link_local
        or address.is_multicast
        or address.is_reserved
        or address.is_unspecified
    ):
        raise ValueError("Base URL 不允许指向私有、回环或链路本地地址")

    if parsed.scheme != "https":
        raise ValueError("带 API Key 的远端 LLM 地址必须使用 HTTPS")
    allowed_hosts = {
        item.strip().rstrip(".").lower()
        for item in get_config().llm_allowed_hosts
        if item.strip()
    }
    if hostname not in allowed_hosts:
        raise ValueError("Base URL 主机不在允许的 LLM 出口白名单中")
    return cleaned
