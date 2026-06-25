"""DailyPhoto, AIReport, MoodCheckin models — SQLite compatible."""
from sqlalchemy import Column, String, Integer, Float, Date, Boolean, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship

from app.models import Base, gen_uuid, now_utc


class DailyPhoto(Base):
    __tablename__ = "daily_photos"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    photo_date = Column(Date, nullable=False)
    photo_type = Column(String(10), nullable=False)  # front / side / back
    photo_url = Column(String(1000), nullable=False)
    thumbnail_url = Column(String(1000))
    pose_keypoints = Column(JSON)  # MediaPipe 33 keypoints
    alignment_score = Column(Float)
    is_benchmark = Column(Boolean, default=False)
    weight_kg = Column(Float)
    body_fat_pct = Column(Float)
    created_at = Column(DateTime(timezone=True), default=now_utc)

    user = relationship("User", back_populates="photos")
    report = relationship("AIReport", back_populates="photo", uselist=False, cascade="all, delete-orphan")


class AIReport(Base):
    __tablename__ = "ai_reports"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    photo_id = Column(String(36), ForeignKey("daily_photos.id", ondelete="SET NULL"), nullable=True)
    photo_date = Column(Date, nullable=False)
    structured_analysis = Column(JSON, nullable=False)
    personality = Column(String(20), nullable=False)
    report_text = Column(Text, nullable=False)
    report_text_alt = Column(JSON, default=dict)  # {"gym_bro": "...", ...}
    generated_plan_id = Column(String(36), nullable=True)
    created_at = Column(DateTime(timezone=True), default=now_utc)

    user = relationship("User", back_populates="reports")
    photo = relationship("DailyPhoto", back_populates="report")


class MoodCheckin(Base):
    __tablename__ = "mood_checkins"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    checkin_date = Column(Date, nullable=False)
    mood = Column(String(10), nullable=False)  # great / good / okay / bad / terrible
    energy_level = Column(Integer)
    sleep_hours = Column(Float)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), default=now_utc)

    user = relationship("User", back_populates="moods")
