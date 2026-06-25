"""AI Report routes — query + personality hot-switch."""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from datetime import date
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.photo import AIReport
from app.services.llm import llm_service

router = APIRouter(prefix="/api/reports", tags=["reports"])


class PersonalitySwitchResponse(BaseModel):
    report_id: str
    new_personality: str
    new_text: str


@router.post("/{report_id}/switch-personality", response_model=PersonalitySwitchResponse)
async def switch_report_personality(
    report_id: str,
    personality: str = Query(..., pattern="^(strict_pro|gym_bro|cute_cheerleader|playful_tsundere|innocent_rookie)$"),
    db: AsyncSession = Depends(get_db),
):
    """Hot-switch personality for an existing report (uses cache or regenerates)."""
    result = await db.execute(select(AIReport).where(AIReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="报告不存在")

    # Check cache first
    alt_cache = report.report_text_alt or {}
    if personality in alt_cache and alt_cache[personality]:
        return PersonalitySwitchResponse(
            report_id=report_id,
            new_personality=personality,
            new_text=alt_cache[personality],
        )

    # Regenerate (angle-aware)
    new_text = await llm_service.generate_report(
        analysis_json=report.structured_analysis,
        personality=personality,
        photo_type="front",  # Default — report doesn't store photo_type (MVP)
    )

    # Update cache
    alt_cache[personality] = new_text
    report.report_text_alt = alt_cache
    await db.commit()

    return PersonalitySwitchResponse(
        report_id=report_id,
        new_personality=personality,
        new_text=new_text,
    )


@router.get("/history")
async def get_report_history(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(default=30, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated report history for a user."""
    query = select(AIReport).where(AIReport.user_id == user_id)
    if start_date:
        query = query.where(AIReport.photo_date >= date.fromisoformat(start_date))
    if end_date:
        query = query.where(AIReport.photo_date <= date.fromisoformat(end_date))
    query = query.order_by(desc(AIReport.photo_date)).limit(limit)

    result = await db.execute(query)
    reports = result.scalars().all()

    return {
        "reports": [
            {
                "report_id": r.id,
                "photo_date": r.photo_date.isoformat(),
                "overall_score": r.structured_analysis.get("overall_score") if r.structured_analysis else None,
                "personality": r.personality,
                "report_text": r.report_text,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ],
        "count": len(reports),
    }


@router.get("/{report_id}")
async def get_report(report_id: str, db: AsyncSession = Depends(get_db)):
    """Get a single report by ID with full details."""
    result = await db.execute(select(AIReport).where(AIReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="报告不存在")

    analysis = report.structured_analysis or {}
    return {
        "report_id": report.id,
        "photo_date": report.photo_date.isoformat() if report.photo_date else None,
        "overall_score": analysis.get("overall_score"),
        "personality": report.personality,
        "report_text": report.report_text,
        "alt_cache": report.report_text_alt or {},
        "progress_items": analysis.get("progress_items", []),
        "weakness_items": analysis.get("weakness_items", []),
        "symmetry_alerts": analysis.get("symmetry_alerts", []),
        "posture_alerts": analysis.get("posture_alerts", []),
        "created_at": report.created_at.isoformat() if report.created_at else None,
    }
