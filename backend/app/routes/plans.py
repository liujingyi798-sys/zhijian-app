"""Training plan routes — wired to DB."""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from datetime import date
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.training import TrainingPlan, PlanExercise, ExerciseLibrary
from app.models import gen_uuid

router = APIRouter(prefix="/api/plans", tags=["plans"])


class ExerciseUpdate(BaseModel):
    is_completed: bool = False
    actual_sets: Optional[int] = None
    actual_weight_kg: Optional[float] = None


class PlanStatusUpdate(BaseModel):
    status: str  # pending / in_progress / completed / skipped


@router.get("/today")
async def get_today_plan(user_id: str, db: AsyncSession = Depends(get_db)):
    """Get today's training plan."""
    today = date.today()
    result = await db.execute(
        select(TrainingPlan)
        .where(TrainingPlan.user_id == user_id)
        .where(TrainingPlan.plan_date == today)
        .options(selectinload(TrainingPlan.exercises))
        .limit(1)
    )
    plan = result.scalars().first()

    if not plan:
        return {"plan": None, "message": "今日暂无训练计划"}

    return {"plan": _plan_to_dict(plan)}


@router.get("/history")
async def get_plan_history(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = Query(default=30),
    db: AsyncSession = Depends(get_db),
):
    """Get plan history for a user."""
    query = select(TrainingPlan).where(TrainingPlan.user_id == user_id)
    if start_date:
        query = query.where(TrainingPlan.plan_date >= date.fromisoformat(start_date))
    if end_date:
        query = query.where(TrainingPlan.plan_date <= date.fromisoformat(end_date))
    query = query.order_by(desc(TrainingPlan.plan_date)).limit(limit)
    query = query.options(selectinload(TrainingPlan.exercises))

    result = await db.execute(query)
    plans = result.unique().scalars().all()

    return {"plans": [_plan_to_dict(p) for p in plans], "count": len(plans)}


@router.put("/{plan_id}/status")
async def update_plan_status(plan_id: str, req: PlanStatusUpdate, db: AsyncSession = Depends(get_db)):
    """Update plan status (start / complete / skip)."""
    result = await db.execute(select(TrainingPlan).where(TrainingPlan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="计划不存在")

    plan.status = req.status
    if req.status == "completed":
        from datetime import datetime, timezone
        plan.completed_at = datetime.now(timezone.utc)
    await db.commit()

    return {"status": "ok", "plan_id": plan_id, "new_status": req.status}


@router.put("/exercises/{exercise_id}")
async def update_exercise_result(exercise_id: str, req: ExerciseUpdate, db: AsyncSession = Depends(get_db)):
    """Log completed set for an exercise."""
    result = await db.execute(select(PlanExercise).where(PlanExercise.id == exercise_id))
    ex = result.scalar_one_or_none()
    if not ex:
        raise HTTPException(status_code=404, detail="动作不存在")

    ex.is_completed = req.is_completed
    if req.actual_sets is not None:
        ex.actual_sets = req.actual_sets
    if req.actual_weight_kg is not None:
        ex.actual_weight_kg = req.actual_weight_kg
    await db.commit()

    return {"status": "ok", "exercise_id": exercise_id, "is_completed": req.is_completed}


@router.get("/exercises/library")
async def get_exercise_library(
    muscle_group: Optional[str] = None,
    difficulty: Optional[int] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """Search/browse the exercise library."""
    query = select(ExerciseLibrary).where(ExerciseLibrary.is_active == True)
    if muscle_group:
        query = query.where(ExerciseLibrary.target_muscle_group == muscle_group)
    if difficulty is not None:
        query = query.where(ExerciseLibrary.difficulty == difficulty)
    if search:
        query = query.where(ExerciseLibrary.name.contains(search))

    result = await db.execute(query)
    exercises = result.scalars().all()

    return {
        "exercises": [
            {
                "id": e.id,
                "name": e.name,
                "name_en": e.name_en,
                "target_muscle_group": e.target_muscle_group,
                "target_sub_muscle": e.target_sub_muscle,
                "difficulty": e.difficulty,
                "equipment_needed": e.equipment_needed,
                "description": e.description,
                "tags": e.tags,
            }
            for e in exercises
        ],
        "count": len(exercises),
    }


def _plan_to_dict(plan: TrainingPlan) -> dict:
    return {
        "plan_id": plan.id,
        "plan_date": plan.plan_date.isoformat() if plan.plan_date else None,
        "source": plan.source,
        "status": plan.status,
        "personality": plan.personality,
        "notes": plan.notes,
        "exercises": [
            {
                "id": e.id,
                "name": e.exercise_name,
                "target_muscle": e.target_muscle,
                "sets": e.sets,
                "reps": e.reps,
                "notes": e.notes,
                "sort_order": e.sort_order,
                "rest_seconds": e.rest_seconds,
                "is_completed": e.is_completed,
                "actual_sets": e.actual_sets,
                "actual_weight_kg": e.actual_weight_kg,
            }
            for e in (plan.exercises or [])
        ],
    }
