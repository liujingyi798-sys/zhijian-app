"""User model & preferences — SQLite compatible."""
from sqlalchemy import Column, String, Integer, Float, Date, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
import uuid as _uuid

from app.models import Base, gen_uuid, now_utc


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    phone = Column(String(20), unique=True, nullable=True)
    email = Column(String(255), unique=True, nullable=True)
    nickname = Column(String(50), nullable=False)
    password_hash = Column(String(200))  # bcrypt hash
    avatar_url = Column(String(500))
    gender = Column(String(10))
    birthday = Column(Date)
    height_cm = Column(Float)
    start_weight_kg = Column(Float)
    target_weight_kg = Column(Float)
    fitness_goal = Column(String(50), default="build_muscle")
    fitness_level = Column(String(20), default="beginner")
    current_personality = Column(String(20), default="gym_bro")
    streak_days = Column(Integer, default=0)
    total_days = Column(Integer, default=0)
    subscription_tier = Column(String(20), default="free")
    subscription_expires_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=now_utc)
    updated_at = Column(DateTime(timezone=True), default=now_utc, onupdate=now_utc)

    preferences = relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    photos = relationship("DailyPhoto", back_populates="user", cascade="all, delete-orphan")
    reports = relationship("AIReport", back_populates="user", cascade="all, delete-orphan")
    plans = relationship("TrainingPlan", back_populates="user", cascade="all, delete-orphan")
    videos = relationship("MilestoneVideo", back_populates="user", cascade="all, delete-orphan")
    moods = relationship("MoodCheckin", back_populates="user", cascade="all, delete-orphan")


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    personality_history = Column(JSON, default=list)
    notification_enabled = Column(Boolean, default=True)
    notification_remind_time = Column(String, default="08:00")
    privacy_cloud_analysis = Column(Boolean, default=True)
    privacy_share_data = Column(Boolean, default=False)
    photo_angle_preference = Column(String(20), default="front")
    video_bgm_preference = Column(String(20), default="auto")
    language = Column(String(10), default="zh-CN")
    created_at = Column(DateTime(timezone=True), default=now_utc)
    updated_at = Column(DateTime(timezone=True), default=now_utc, onupdate=now_utc)

    user = relationship("User", back_populates="preferences")
