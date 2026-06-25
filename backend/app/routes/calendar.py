"""Calendar & comparison routes — wired to DB."""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from datetime import date, timedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.photo import DailyPhoto, AIReport, MoodCheckin
from app.models.video import ComparisonSnapshot

router = APIRouter(prefix="/api/calendar", tags=["calendar"])


class CalendarDay(BaseModel):
    date: str
    has_photo: bool = False
    thumbnail_url: Optional[str] = None
    body_weight_kg: Optional[float] = None
    mood: Optional[str] = None
    streak_day: bool = False


class CalendarMonthResponse(BaseModel):
    year: int
    month: int
    days: list[CalendarDay]
    total_checkins: int
    streak_days: int


class ComparisonResponse(BaseModel):
    date_a: str
    date_b: str
    days_between: int
    photo_type: str
    comparison_url: str


@router.get("/month", response_model=CalendarMonthResponse)
async def get_month_calendar(
    user_id: str,
    year: int = Query(ge=2020, le=2100),
    month: int = Query(ge=1, le=12),
    db: AsyncSession = Depends(get_db),
):
    """Get calendar data for a specific month."""
    # Get user for streak info
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()

    # Get all photos for this month
    month_start = date(year, month, 1)
    if month == 12:
        month_end = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        month_end = date(year, month + 1, 1) - timedelta(days=1)

    photos_result = await db.execute(
        select(DailyPhoto)
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date.between(month_start, month_end))
        .where(DailyPhoto.photo_type == "front")  # only front photos for calendar thumbnails
        .order_by(DailyPhoto.photo_date)
    )
    photos_by_date = {}
    for p in photos_result.scalars().all():
        key = p.photo_date.isoformat()
        photos_by_date[key] = p

    # Get moods for this month
    moods_result = await db.execute(
        select(MoodCheckin)
        .where(MoodCheckin.user_id == user_id)
        .where(MoodCheckin.checkin_date.between(month_start, month_end))
    )
    moods_by_date = {}
    for m in moods_result.scalars().all():
        moods_by_date[m.checkin_date.isoformat()] = m.mood

    # Build calendar days
    total_days = (month_end - month_start).days + 1
    days = []
    checkin_count = 0

    for i in range(total_days):
        d = month_start + timedelta(days=i)
        key = d.isoformat()
        photo = photos_by_date.get(key)
        has_photo = photo is not None
        if has_photo:
            checkin_count += 1

        days.append(CalendarDay(
            date=key,
            has_photo=has_photo,
            thumbnail_url=photo.thumbnail_url if photo else None,
            body_weight_kg=photo.weight_kg if photo else None,
            mood=moods_by_date.get(key),
            streak_day=False,  # Computed separately
        ))

    return CalendarMonthResponse(
        year=year,
        month=month,
        days=days,
        total_checkins=checkin_count,
        streak_days=user.streak_days if user else 0,
    )


@router.get("/day/{date_str}")
async def get_day_detail(user_id: str, date_str: str, db: AsyncSession = Depends(get_db)):
    """Get full detail for a specific day."""
    d = date.fromisoformat(date_str)

    # Photos
    photos_result = await db.execute(
        select(DailyPhoto)
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date == d)
        .order_by(DailyPhoto.photo_type)
    )
    photos = photos_result.scalars().all()

    # AI Report
    report_result = await db.execute(
        select(AIReport)
        .where(AIReport.user_id == user_id)
        .where(AIReport.photo_date == d)
        .limit(1)
    )
    report = report_result.scalar_one_or_none()

    # Mood
    mood_result = await db.execute(
        select(MoodCheckin)
        .where(MoodCheckin.user_id == user_id)
        .where(MoodCheckin.checkin_date == d)
        .limit(1)
    )
    mood = mood_result.scalar_one_or_none()

    return {
        "date": date_str,
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
        "report": {
            "report_id": report.id,
            "overall_score": report.structured_analysis.get("overall_score") if report and report.structured_analysis else None,
            "personality": report.personality,
            "report_text": report.report_text,
            "progress_items": report.structured_analysis.get("progress_items", []) if report and report.structured_analysis else [],
            "weakness_items": report.structured_analysis.get("weakness_items", []) if report and report.structured_analysis else [],
        } if report else None,
        "mood": mood.mood if mood else None,
        "weight_kg": photos[0].weight_kg if photos else None,
        "body_fat_pct": photos[0].body_fat_pct if photos else None,
    }


@router.get("/heatmap")
async def get_year_heatmap(user_id: str, year: int, db: AsyncSession = Depends(get_db)):
    """Get annual check-in heatmap data (GitHub-style grid)."""
    year_start = date(year, 1, 1)
    year_end = date(year, 12, 31)

    result = await db.execute(
        select(DailyPhoto.photo_date, func.count(DailyPhoto.id).label("count"))
        .where(DailyPhoto.user_id == user_id)
        .where(DailyPhoto.photo_date.between(year_start, year_end))
        .group_by(DailyPhoto.photo_date)
        .order_by(DailyPhoto.photo_date)
    )
    daily_counts = {row[0].isoformat(): row[1] for row in result.all()}

    # Build grid (date → count)
    grid = {}
    d = year_start
    while d <= year_end:
        grid[d.isoformat()] = daily_counts.get(d.isoformat(), 0)
        d += timedelta(days=1)

    return {"year": year, "grid": grid, "total_days": sum(1 for v in grid.values() if v > 0)}
