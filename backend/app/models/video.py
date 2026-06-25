"""MilestoneVideo, ComparisonSnapshot models — SQLite compatible."""
from sqlalchemy import Column, String, Integer, Float, Date, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship

from app.models import Base, gen_uuid, now_utc


class MilestoneVideo(Base):
    __tablename__ = "milestone_videos"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    photo_count = Column(Integer, nullable=False)
    video_url = Column(String(1000))
    thumbnail_url = Column(String(1000))
    bgm_track_id = Column(String(50))
    badge_name = Column(String(100))
    badge_url = Column(String(500))
    render_status = Column(String(20), default="queued")  # queued / rendering / completed / failed
    render_progress = Column(Integer, default=0)
    duration_seconds = Column(Integer)
    format = Column(String(20), default="1080x1920")
    error_message = Column(Text)
    created_at = Column(DateTime(timezone=True), default=now_utc)
    completed_at = Column(DateTime(timezone=True))

    user = relationship("User", back_populates="videos")


class ComparisonSnapshot(Base):
    __tablename__ = "comparison_snapshots"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date_a = Column(Date, nullable=False)
    date_b = Column(Date, nullable=False)
    photo_type = Column(String(10), default="front")
    image_url = Column(String(1000), nullable=False)
    created_at = Column(DateTime(timezone=True), default=now_utc)
