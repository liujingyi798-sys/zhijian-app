"""User management routes — wired to DB."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User, UserPreference
from app.models import gen_uuid, now_utc

router = APIRouter(prefix="/api/users", tags=["users"])

# ── Schemas ──────────────────────────────────────────────────

class UserCreateRequest(BaseModel):
    phone: Optional[str] = None
    email: Optional[str] = None
    nickname: str = Field(min_length=1, max_length=50)
    gender: Optional[str] = None
    birthday: Optional[date] = None
    height_cm: Optional[float] = None
    start_weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    fitness_goal: str = "build_muscle"
    fitness_level: str = "beginner"

class UserUpdateRequest(BaseModel):
    nickname: Optional[str] = None
    height_cm: Optional[float] = None
    target_weight_kg: Optional[float] = None
    fitness_goal: Optional[str] = None
    fitness_level: Optional[str] = None
    current_personality: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    nickname: str
    current_personality: str
    streak_days: int
    total_days: int
    fitness_goal: str
    fitness_level: str
    subscription_tier: str
    created_at: Optional[str] = None

    class Config:
        from_attributes = True

class PersonalitySwitchRequest(BaseModel):
    personality: str = Field(pattern="^(strict_pro|gym_bro|cute_cheerleader|playful_tsundere|innocent_rookie)$")

# ── Routes ───────────────────────────────────────────────────

@router.post("/register", response_model=UserResponse, status_code=201)
async def register_user(req: UserCreateRequest, db: AsyncSession = Depends(get_db)):
    """Register a new user."""
    uid = gen_uuid()
    user = User(
        id=uid,
        phone=req.phone,
        email=req.email,
        nickname=req.nickname,
        gender=req.gender,
        birthday=req.birthday,
        height_cm=req.height_cm,
        start_weight_kg=req.start_weight_kg,
        target_weight_kg=req.target_weight_kg,
        fitness_goal=req.fitness_goal,
        fitness_level=req.fitness_level,
    )
    prefs = UserPreference(user_id=uid)
    db.add(user)
    db.add(prefs)
    await db.commit()
    await db.refresh(user)
    return _user_to_response(user)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    """Get user profile."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return _user_to_response(user)


@router.put("/{user_id}/personality")
async def switch_personality(user_id: str, req: PersonalitySwitchRequest, db: AsyncSession = Depends(get_db)):
    """Switch AI coach personality."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    # Update user
    user.current_personality = req.personality
    user.updated_at = now_utc()

    # Log to preferences history
    prefs_result = await db.execute(select(UserPreference).where(UserPreference.user_id == user_id))
    prefs = prefs_result.scalar_one_or_none()
    if prefs:
        history = list(prefs.personality_history or [])
        history.append({
            "personality": req.personality,
            "switched_at": datetime.now(timezone.utc).isoformat(),
            "switched_from": user.current_personality,
        })
        prefs.personality_history = history

    await db.commit()
    return {"status": "ok", "personality": req.personality}


def _user_to_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        nickname=user.nickname,
        current_personality=user.current_personality,
        streak_days=user.streak_days or 0,
        total_days=user.total_days or 0,
        fitness_goal=user.fitness_goal or "build_muscle",
        fitness_level=user.fitness_level or "beginner",
        subscription_tier=user.subscription_tier or "free",
        created_at=user.created_at.isoformat() if user.created_at else None,
    )
