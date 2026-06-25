"""
JWT Authentication — login, register, token verification.

Uses python-jose for JWT signing + passlib for password hashing.
"""
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.models.user import User

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Security config ─────────────────────────────────────────

SECRET_KEY = settings.jwt_secret_key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 30

bearer_scheme = HTTPBearer(auto_error=False)

# ── Password helpers (bcrypt direct — avoids passlib compat issues) ─

import bcrypt as _bcrypt


def hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode("utf-8"), _bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return _bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


# ── Schemas ──────────────────────────────────────────────────

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict


class LoginRequest(BaseModel):
    phone: Optional[str] = None
    email: Optional[str] = None
    password: str


class RegisterRequest(BaseModel):
    nickname: str
    phone: Optional[str] = None
    email: Optional[str] = None
    password: str
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    start_weight_kg: Optional[float] = None
    fitness_goal: str = "build_muscle"
    fitness_level: str = "beginner"


# ── Token helpers ────────────────────────────────────────────

def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    payload = {"sub": user_id, "exp": expire, "iat": datetime.now(timezone.utc)}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[str]:
    """Decode JWT → user_id. Returns None if invalid."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


# ── Auth dependency ──────────────────────────────────────────

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    FastAPI dependency: extract and validate JWT, return User.
    Use this to protect any route: `user: User = Depends(get_current_user)`
    """
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="请先登录")

    user_id = decode_token(credentials.credentials)
    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="登录已过期，请重新登录")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="用户不存在")

    return user


# Optional auth — returns None if not logged in (for public endpoints)
async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    if credentials is None:
        return None
    user_id = decode_token(credentials.credentials)
    if user_id is None:
        return None
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


# ── Auth routes ──────────────────────────────────────────────

from fastapi import APIRouter
from app.models.user import UserPreference
from app.models import gen_uuid, now_utc

auth_router = APIRouter(prefix="/api/auth", tags=["auth"])


@auth_router.post("/register", response_model=TokenResponse)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register a new user and return JWT token."""
    # Check duplicate
    if req.phone:
        existing = await db.execute(select(User).where(User.phone == req.phone))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="该手机号已注册")
    if req.email:
        existing = await db.execute(select(User).where(User.email == req.email))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="该邮箱已注册")

    uid = gen_uuid()
    user = User(
        id=uid,
        phone=req.phone,
        email=req.email,
        nickname=req.nickname,
        password_hash=hash_password(req.password),
        gender=req.gender,
        height_cm=req.height_cm,
        start_weight_kg=req.start_weight_kg,
        fitness_goal=req.fitness_goal,
        fitness_level=req.fitness_level,
    )
    prefs = UserPreference(user_id=uid)

    db.add(user)
    db.add(prefs)
    await db.commit()

    token = create_access_token(uid)
    return TokenResponse(
        access_token=token,
        user=_user_dict(user),
    )


@auth_router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login with phone/email + password, return JWT."""
    if req.phone:
        result = await db.execute(select(User).where(User.phone == req.phone))
    elif req.email:
        result = await db.execute(select(User).where(User.email == req.email))
    else:
        raise HTTPException(status_code=400, detail="请提供手机号或邮箱")

    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="用户不存在")

    if not user.password_hash or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=400, detail="密码错误")

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user=_user_dict(user),
    )


@auth_router.get("/me")
async def me(user: User = Depends(get_current_user)):
    """Get current user profile (requires auth)."""
    return {"user": _user_dict(user)}


def _user_dict(user: User) -> dict:
    return {
        "id": user.id,
        "nickname": user.nickname,
        "phone": user.phone,
        "email": user.email,
        "gender": user.gender,
        "height_cm": user.height_cm,
        "start_weight_kg": user.start_weight_kg,
        "fitness_goal": user.fitness_goal,
        "fitness_level": user.fitness_level,
        "current_personality": user.current_personality,
        "streak_days": user.streak_days or 0,
        "total_days": user.total_days or 0,
        "subscription_tier": user.subscription_tier,
    }
