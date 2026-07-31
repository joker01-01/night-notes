"""通知抽象层，今后可在此增加 Telegram 或飞书适配器。"""

from __future__ import annotations

from typing import Protocol


class Notifier(Protocol):
    def notify_review_ready(self, day: str) -> None:
        """通知用户今天的复盘会话已准备好。"""


class WebNotifier:
    """Web 提醒无需向外发送消息：前端轮询 pending 会话即可显示横幅。"""

    def notify_review_ready(self, day: str) -> None:
        return None

