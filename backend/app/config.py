"""Application configuration via environment variables."""
from pydantic_settings import BaseSettings
from functools import lru_cache
import os


class Settings(BaseSettings):
    # App
    app_name: str = "智健"
    app_version: str = "0.1.0"
    debug: bool = True
    dev_mode: bool = True  # True = SQLite + local storage, False = PostgreSQL + S3

    # Auth
    jwt_secret_key: str = "zhijian-jwt-secret-change-in-production-2026"

    # Database — PostgreSQL (production) or SQLite (dev)
    database_url: str = "sqlite+aiosqlite:///./zhijian.db"
    database_url_sync: str = "sqlite:///./zhijian.db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Object Storage (MinIO / S3) — or local filesystem in dev
    s3_endpoint: str = "http://localhost:9000"
    s3_access_key: str = "zhijian"
    s3_secret_key: str = "zhijian123"
    s3_bucket: str = "zhijian-photos"
    s3_region: str = "us-east-1"
    local_storage_path: str = "./uploads"

    # LLM - DeepSeek (primary, default)
    deepseek_api_key: str = ""
    deepseek_model: str = "deepseek-chat"
    deepseek_base_url: str = "https://api.deepseek.com"

    # LLM - Claude (secondary)
    anthropic_api_key: str = ""
    claude_model: str = "claude-sonnet-4-6"

    # LLM - OpenAI (tertiary)
    openai_api_key: str = ""
    openai_model: str = "gpt-4o"

    # LLM selection: "deepseek" | "anthropic" | "openai"
    llm_provider: str = "deepseek"

    # AI Analysis
    vision_confidence_threshold: float = 0.65
    alignment_quality_threshold: float = 0.70
    symmetry_alert_threshold_cm: float = 1.5
    posture_alert_angle: float = 5.0

    # Video Rendering
    video_default_format: str = "1080x1920"
    video_max_duration_seconds: int = 60
    video_fps: int = 30

    # Limits
    max_photo_size_mb: int = 20
    daily_report_cache_hours: int = 24
    free_tier_daily_llm_calls: int = 3

    class Config:
        env_file = ".env"
        env_prefix = ""  # No prefix needed — .env vars match field names directly


@lru_cache()
def get_settings() -> Settings:
    s = Settings()
    # Ensure upload directory exists
    if s.dev_mode:
        os.makedirs(s.local_storage_path, exist_ok=True)
    return s
