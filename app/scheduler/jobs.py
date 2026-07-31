"""APScheduler 定时创建复盘会话。调度器本身不保存用户数据。"""

from __future__ import annotations

import logging
from datetime import date

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.database import SessionLocal
from app.notifier import WebNotifier
from app.services.review_service import create_session_if_needed
from app.services.settings_service import get_or_create_settings, get_provider

logger = logging.getLogger(__name__)


class ReviewScheduler:
    def __init__(self) -> None:
        self.scheduler = BackgroundScheduler(timezone="Asia/Shanghai")
        self.notifier = WebNotifier()

    def run_daily_job(self) -> None:
        """每次触发都新建独立 DB Session，避免跨线程复用 SQLAlchemy Session。"""
        with SessionLocal() as db:
            try:
                try:
                    provider = get_provider(db)
                except Exception:
                    # 与手动 open 对齐：配置无效时仍用模板创建当日会话。
                    logger.exception("定时任务获取 LLM Provider 失败，回退问题模板")
                    provider = None
                session = create_session_if_needed(db, date.today(), provider)
                self.notifier.notify_review_ready(session.date.isoformat())
            except Exception:
                logger.exception("定时创建复盘会话失败")
                db.rollback()

    def refresh(self, time_text: str) -> None:
        parts = time_text.split(":")
        hour, minute = int(parts[0]), int(parts[1])
        self.scheduler.add_job(
            self.run_daily_job,
            trigger="cron",
            hour=hour,
            minute=minute,
            id="daily_review",
            replace_existing=True,
            misfire_grace_time=3600,
        )

    def start(self) -> None:
        with SessionLocal() as db:
            self.refresh(get_or_create_settings(db).question_time)
        if not self.scheduler.running:
            self.scheduler.start()

    def shutdown(self) -> None:
        if self.scheduler.running:
            self.scheduler.shutdown(wait=False)


review_scheduler = ReviewScheduler()
