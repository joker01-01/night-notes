"""SQLite 数据库连接与会话工厂。"""

from __future__ import annotations

from collections.abc import Generator
from pathlib import Path

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import ROOT_DIR, get_config


class Base(DeclarativeBase):
    pass


def resolve_database_url(database_url: str | None = None) -> str:
    """把相对 sqlite 路径锚定到项目根，避免因启动 CWD 不同写出第二套库。"""
    url = database_url or get_config().database_url
    if url.startswith("sqlite:///./"):
        relative = url.removeprefix("sqlite:///./")
        absolute = (ROOT_DIR / relative).resolve()
        absolute.parent.mkdir(parents=True, exist_ok=True)
        return f"sqlite:///{absolute.as_posix()}"
    if url.startswith("sqlite:///") and not url.startswith("sqlite:////"):
        # sqlite:///C:/... 或 sqlite:///absolute — 确保父目录存在
        path_part = url.removeprefix("sqlite:///")
        Path(path_part).parent.mkdir(parents=True, exist_ok=True)
    return url


def create_database_engine(database_url: str | None = None) -> Engine:
    url = resolve_database_url(database_url)
    connect_args: dict[str, object] = {}
    if url.startswith("sqlite"):
        # 请求线程与 APScheduler 并发写时，等待而不是立刻报 database is locked。
        connect_args = {"check_same_thread": False, "timeout": 30}
    engine = create_engine(url, connect_args=connect_args)
    if url.startswith("sqlite"):

        @event.listens_for(engine, "connect")
        def _set_sqlite_pragma(dbapi_connection, _connection_record) -> None:  # type: ignore[no-untyped-def]
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA busy_timeout=30000")
            cursor.close()

    return engine


engine = create_database_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
