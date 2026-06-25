"""TrainingPlan, PlanExercise, ExerciseLibrary models — SQLite compatible."""
from sqlalchemy import Column, String, Integer, Float, Date, Boolean, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship

from app.models import Base, gen_uuid, now_utc


class TrainingPlan(Base):
    __tablename__ = "training_plans"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    plan_date = Column(Date, nullable=False)
    source = Column(String(20), default="auto")  # auto / manual / coach
    status = Column(String(20), default="pending")  # pending / in_progress / completed / skipped
    personality = Column(String(20), nullable=False)
    notes = Column(Text)
    completed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=now_utc)

    user = relationship("User", back_populates="plans")
    exercises = relationship("PlanExercise", back_populates="plan", cascade="all, delete-orphan",
                             order_by="PlanExercise.sort_order")


class PlanExercise(Base):
    __tablename__ = "plan_exercises"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    plan_id = Column(String(36), ForeignKey("training_plans.id", ondelete="CASCADE"), nullable=False)
    exercise_id = Column(String(36), ForeignKey("exercise_library.id", ondelete="SET NULL"), nullable=True)
    exercise_name = Column(String(100), nullable=False)
    target_muscle = Column(String(50))
    sets = Column(Integer, nullable=False)
    reps = Column(String(20), nullable=False)
    weight_kg = Column(Float)
    rest_seconds = Column(Integer, default=60)
    sort_order = Column(Integer, default=0)
    notes = Column(String(500))
    is_completed = Column(Boolean, default=False)
    actual_sets = Column(Integer)
    actual_weight_kg = Column(Float)
    created_at = Column(DateTime(timezone=True), default=now_utc)

    plan = relationship("TrainingPlan", back_populates="exercises")


class ExerciseLibrary(Base):
    __tablename__ = "exercise_library"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    name_en = Column(String(200))
    target_muscle_group = Column(String(50), nullable=False)
    target_sub_muscle = Column(String(100))
    compound_or_isolation = Column(String(10), default="compound")
    difficulty = Column(Integer, default=1)
    equipment_needed = Column(String(100))
    alternative_exercise_id = Column(String(36), ForeignKey("exercise_library.id"), nullable=True)
    video_url = Column(String(500))
    image_url = Column(String(500))
    description = Column(Text)
    common_mistakes = Column(Text)
    tags = Column(JSON, default=list)  # Store as JSON array in SQLite
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=now_utc)

    alternative_exercise = relationship("ExerciseLibrary", remote_side=[id])
