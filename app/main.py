"""FastAPI 应用入口。"""

from __future__ import annotations

from contextlib import asynccontextmanager
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from starlette.middleware.trustedhost import TrustedHostMiddleware

from app.api.routes import public_router, router
from app.core.config import get_config
from app.core.database import Base, engine
from app.core.schema import ensure_schema
from app.core.security import request_security_boundary
from app import models  # noqa: F401 让 SQLAlchemy 注册全部模型
from app.scheduler import review_scheduler


STATIC_DIR = Path(__file__).parent / "static"
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    ensure_schema(engine)
    config = get_config()
    if config.bind_host not in {"127.0.0.1", "localhost", "::1"} and not config.allow_lan:
        logger.warning(
            "AI_REVIEW_BIND_HOST=%s is not loopback while allow_lan=false; "
            "keep the process behind a loopback-only reverse proxy.",
            config.bind_host,
        )
    review_scheduler.start()
    yield
    review_scheduler.shutdown()


app = FastAPI(title="AI 每日复盘助手", version="0.1.0", lifespan=lifespan)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "[::1]"],
)
app.middleware("http")(request_security_boundary)
app.include_router(public_router)
app.include_router(router)
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/", include_in_schema=False)
def index() -> FileResponse:
    return FileResponse(STATIC_DIR / "index.html")
