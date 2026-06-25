"""智健 (ZhiJian) — FastAPI Application Entry Point."""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import logging
import os

from app.config import get_settings
from app.database import init_db
from app.routes import users, photos, reports, plans, calendar
from app.auth import auth_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: init DB tables + seed data. Shutdown: cleanup."""
    logger.info("[智健] 正在初始化数据库...")
    await init_db()
    logger.info("[智健] 数据库就绪，服务启动中...")
    yield
    logger.info("[智健] 服务关闭。")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="智健 API",
        description="AI-powered fitness progress tracking app",
        version=settings.app_version,
        lifespan=lifespan,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Serve uploaded files
    if settings.dev_mode:
        os.makedirs(settings.local_storage_path, exist_ok=True)
        app.mount("/uploads", StaticFiles(directory=settings.local_storage_path), name="uploads")

    # Routers
    app.include_router(auth_router)  # Auth routes (public: register/login)
    app.include_router(users.router)
    app.include_router(photos.router)
    app.include_router(reports.router)
    app.include_router(plans.router)
    app.include_router(calendar.router)

    @app.get("/api/health")
    async def health_check():
        return {"status": "ok", "app": "智健", "version": settings.app_version, "dev_mode": settings.dev_mode}

    @app.get("/api/personalities")
    async def list_personalities():
        from app.prompts.personalities import get_all_personalities
        return {"personalities": get_all_personalities()}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
