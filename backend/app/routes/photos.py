"""
Photo upload & AI analysis route — wired to DB + real file storage.

POST /api/photos/upload
  → saves photo to disk → saves to DB → runs vision analysis
  → runs LLM report → generates training plan → saves all to DB
  → returns complete analysis + plan
"""
from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime, timezone
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.database import get_db
from app.models import gen_uuid, now_utc
from app.auth import get_current_user
from app.models.user import User
from app.models.photo import DailyPhoto, AIReport
from app.models.training import TrainingPlan, PlanExercise
from app.services.vision import vision_service
from app.services.llm import llm_service
from app.utils.image import validate_photo, create_thumbnail
from app.utils.storage import save_photo, save_thumbnail

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/photos", tags=["photos"])

# ── Schemas ──────────────────────────────────────────────────

class AnalysisItem(BaseModel):
    body_part: str
    label: str
    change_pct: float = 0
    confidence: float = 0
    direction: str = "stable"

class SymmetryItem(BaseModel):
    body_part: str = ""
    label: str = ""
    diff_cm: float = 0
    severity: str = "mild"

class PostureItem(BaseModel):
    label: str = ""
    angle: float = 0
    severity: str = "normal"
    recommendation: str = ""

class ExerciseItem(BaseModel):
    name: str
    target_muscle: str = ""
    sets: int = 4
    reps: str = "8-12"
    notes: str = ""
    sort_order: int = 0
    rest_seconds: int = 60

class PhotoUploadResponse(BaseModel):
    photo_id: str
    photo_date: str
    report: dict
    plan: Optional[dict] = None


# ── Route ───────────────────────────────────────────────────

@router.post("/upload", response_model=PhotoUploadResponse)
async def upload_photo(
    photo_type: str = Form("front"),
    photo: UploadFile = File(...),
    personality: str = Form("gym_bro"),
    weight_kg: Optional[float] = Form(None),
    body_fat_pct: Optional[float] = Form(None),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),  # JWT auth
):
    """
    Upload a daily body photo + trigger full AI analysis pipeline.
    User is identified via JWT token — no user_id needed in form.
    """
    user_id = user.id

    # 2. Validate photo
    contents = await photo.read()
    valid, err_msg = validate_photo(contents)
    if not valid:
        raise HTTPException(status_code=400, detail=err_msg)

    today = date.today()

    # 3. Save photo to disk & create thumbnail
    photo_url = save_photo(user_id, today, photo_type, contents)
    thumb_bytes = create_thumbnail(contents)
    thumbnail_url = save_thumbnail(thumb_bytes)

    # 4. Save to daily_photos
    photo_id = gen_uuid()
    daily_photo = DailyPhoto(
        id=photo_id,
        user_id=user_id,
        photo_date=today,
        photo_type=photo_type,
        photo_url=photo_url,
        thumbnail_url=thumbnail_url,
        weight_kg=weight_kg,
        body_fat_pct=body_fat_pct,
    )
    db.add(daily_photo)

    # 5. Load yesterday's photo for comparison (same angle)
    yesterday = date(today.year, today.month, today.day)
    yesterday = yesterday.replace(day=yesterday.day - 1) if yesterday.day > 1 else yesterday
    # Actually use timedelta:
    from datetime import timedelta
    yesterday = today - timedelta(days=1)

    yesterday_result = await db.execute(
        select(DailyPhoto)
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date == yesterday)
        .where(DailyPhoto.photo_type == photo_type)
        .limit(1)
    )
    yesterday_photo = yesterday_result.scalar_one_or_none()

    # 6. Run visual analysis
    analysis_result = vision_service.analyze(
        today_image_bytes=contents,
        yesterday_image_bytes=contents,  # In production: load yesterday's photo bytes from disk
        photo_type=photo_type,
    )

    analysis_dict = {
        "overall_score": analysis_result.overall_score,
        "progress_items": analysis_result.progress_items,
        "weakness_items": analysis_result.weakness_items,
        "symmetry_alerts": analysis_result.symmetry_alerts,
        "posture_alerts": analysis_result.posture_alerts,
        "body_fat_estimate": analysis_result.body_fat_estimate,
        "muscle_mass_estimate_trend": analysis_result.muscle_mass_estimate_trend,
        "roi_details": analysis_result.roi_details,
    }

    # 7. Generate LLM report (angle-aware, with personality cache)
    report_data = await llm_service.generate_report_with_cache(
        analysis_dict, personality, photo_type=photo_type,
    )

    # 8. Save AI report to DB
    report_id = gen_uuid()
    ai_report = AIReport(
        id=report_id,
        user_id=user_id,
        photo_id=photo_id,
        photo_date=today,
        structured_analysis=analysis_dict,
        personality=personality,
        report_text=report_data["primary_text"],
        report_text_alt=report_data["alt_cache"],
    )
    db.add(ai_report)

    # 9. Generate training plan
    weak_areas = [w["body_part"] for w in analysis_result.weakness_items]
    plan_data = await llm_service.generate_training_plan(
        weak_areas=weak_areas if weak_areas else [],
        fitness_goal=user.fitness_goal or "build_muscle",
        fitness_level=user.fitness_level or "intermediate",
        personality=personality,
        photo_type=photo_type,
    )

    # 10. Save training plan to DB
    plan_id = gen_uuid()
    tomorrow = today + timedelta(days=1)
    training_plan = TrainingPlan(
        id=plan_id,
        user_id=user_id,
        plan_date=tomorrow,
        source="auto",
        status="pending",
        personality=personality,
        notes=plan_data.get("notes", ""),
    )
    db.add(training_plan)

    for i, ex in enumerate(plan_data.get("exercises", [])):
        db.add(PlanExercise(
            id=gen_uuid(),
            plan_id=plan_id,
            exercise_name=ex["name"],
            target_muscle=ex.get("target_muscle", ""),
            sets=ex.get("sets", 4),
            reps=ex.get("reps", "8-12"),
            sort_order=ex.get("sort_order", i),
            notes=ex.get("notes", ""),
            rest_seconds=ex.get("rest_seconds", 60),
        ))

    # Link report to plan
    ai_report.generated_plan_id = plan_id

    # 11. Update user streak
    user.streak_days = (user.streak_days or 0) + 1
    user.total_days = (user.total_days or 0) + 1
    user.updated_at = now_utc()

    await db.commit()
    await db.refresh(ai_report)
    await db.refresh(training_plan)

    return PhotoUploadResponse(
        photo_id=photo_id,
        photo_date=today.isoformat(),
        report={
            "report_id": report_id,
            "overall_score": analysis_result.overall_score,
            "personality": personality,
            "report_text": report_data["primary_text"],
            "alt_cache": report_data["alt_cache"],
            "progress_items": analysis_result.progress_items,
            "weakness_items": analysis_result.weakness_items,
            "symmetry_alerts": analysis_result.symmetry_alerts,
            "posture_alerts": analysis_result.posture_alerts,
        },
        plan={
            "plan_id": plan_id,
            "plan_date": tomorrow.isoformat(),
            "exercises": plan_data.get("exercises", []),
            "notes": plan_data.get("notes", ""),
        },
    )


@router.get("/by-date")
async def get_photos_by_date(
    user_id: str,
    photo_date: str,
    db: AsyncSession = Depends(get_db),
):
    """Get all photos for a specific date."""
    d = date.fromisoformat(photo_date)
    result = await db.execute(
        select(DailyPhoto)
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date == d)
        .order_by(DailyPhoto.photo_type)
    )
    photos = result.scalars().all()
    return {
        "date": photo_date,
        "photos": [
            {
                "id": p.id,
                "photo_type": p.photo_type,
                "photo_url": p.photo_url,
                "thumbnail_url": p.thumbnail_url,
                "weight_kg": p.weight_kg,
                "body_fat_pct": p.body_fat_pct,
            }
            for p in photos
        ],
    }


@router.get("/range")
async def get_photos_range(
    user_id: str,
    start_date: str,
    end_date: str,
    photo_type: str = "front",
    db: AsyncSession = Depends(get_db),
):
    """Get photos within a date range."""
    start = date.fromisoformat(start_date)
    end = date.fromisoformat(end_date)
    result = await db.execute(
        select(DailyPhoto)
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date.between(start, end))
        .where(DailyPhoto.photo_type == photo_type)
        .order_by(DailyPhoto.photo_date.asc())
    )
    photos = result.scalars().all()
    return {
        "photos": [
            {"id": p.id, "date": p.photo_date.isoformat(), "photo_url": p.photo_url}
            for p in photos
        ],
        "count": len(photos),
    }
