"""进程内令牌桶限流（单进程本地应用足够）。

LLM 触发路由：10 次/分钟；settings 写入：20 次/分钟。
超限返回 429 + Retry-After。
"""

from __future__ import annotations

import threading
import time
from collections import deque

from fastapi import HTTPException

_LIMITS: dict[str, tuple[int, float]] = {
    "llm": (10, 60.0),
    "settings": (20, 60.0),
}

_lock = threading.Lock()
_buckets: dict[str, deque[float]] = {}


def rate_limit(bucket: str) -> None:
    limit, window = _LIMITS[bucket]
    with _lock:
        entries = _buckets.setdefault(bucket, deque())
        now = time.monotonic()
        while entries and now - entries[0] >= window:
            entries.popleft()
        if len(entries) >= limit:
            retry_after = max(1, int(window - (now - entries[0])))
            raise HTTPException(
                status_code=429,
                detail="操作太频繁，请稍候再试。",
                headers={"Retry-After": str(retry_after)},
            )
        entries.append(now)


def rate_limit_llm() -> None:
    rate_limit("llm")


def rate_limit_settings() -> None:
    rate_limit("settings")


def reset_rate_limits() -> None:
    """仅测试使用：清空所有桶。"""
    with _lock:
        _buckets.clear()
