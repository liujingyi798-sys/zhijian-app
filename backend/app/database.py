"""
Database session management + table creation.

Supports both:
  - SQLite (dev mode, zero-setup)
  - PostgreSQL (production, via asyncpg)
"""
import logging
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session, sessionmaker

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Async engine (for FastAPI) ───────────────────────────
async_engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
)
AsyncSessionLocal = async_sessionmaker(async_engine, class_=AsyncSession, expire_on_commit=False)

# ── Sync engine (for init / migrations) ──────────────────
sync_engine = create_engine(
    settings.database_url_sync,
    echo=False,
    connect_args={"check_same_thread": False} if "sqlite" in settings.database_url_sync else {},
)
SyncSessionLocal = sessionmaker(sync_engine, expire_on_commit=False)


async def get_db() -> AsyncSession:
    """FastAPI dependency: yield an async DB session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


def get_sync_db() -> Session:
    """Synchronous DB session (for init scripts)."""
    return SyncSessionLocal()


async def init_db():
    """Create all tables and seed exercise library if empty."""
    from app.models import Base
    from app.models import user, photo, training, video  # noqa: F401 — registers models

    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed exercise library if empty
    from app.models.training import ExerciseLibrary
    async with AsyncSessionLocal() as session:
        from sqlalchemy import select
        result = await session.execute(select(ExerciseLibrary).limit(1))
        if result.first() is None:
            await _seed_exercises(session)
            await session.commit()
            logger.info("Exercise library seeded with 21 exercises.")

    logger.info(f"Database initialized ({'SQLite' if settings.dev_mode else 'PostgreSQL'}).")


async def _seed_exercises(session: AsyncSession):
    """Insert the standard 21-exercise library."""
    from app.models.training import ExerciseLibrary
    exercises = [
        ExerciseLibrary(name="杠铃平板卧推", name_en="Barbell Bench Press", target_muscle_group="chest", target_sub_muscle="middle_chest", compound_or_isolation="compound", difficulty=3, equipment_needed="barbell", description="仰卧平板凳，杠铃下降至胸口，推起至手臂伸直。", common_mistakes="肩胛骨未后缩，臀部离凳", tags=["strength","mass","core"]),
        ExerciseLibrary(name="上斜哑铃卧推", name_en="Incline Dumbbell Press", target_muscle_group="chest", target_sub_muscle="upper_chest", compound_or_isolation="compound", difficulty=3, equipment_needed="dumbbell", description="上斜凳30-45度，哑铃推至上方，重点刺激上胸。", common_mistakes="角度过高变前束", tags=["strength","mass","upper_chest"]),
        ExerciseLibrary(name="绳索飞鸟", name_en="Cable Fly", target_muscle_group="chest", target_sub_muscle="inner_chest", compound_or_isolation="isolation", difficulty=2, equipment_needed="cable", description="龙门架双手飞鸟，顶峰收缩1-2秒。", common_mistakes="肘部弯曲角度过大", tags=["isolation","definition"]),
        ExerciseLibrary(name="双杠臂屈伸", name_en="Dips", target_muscle_group="chest", target_sub_muscle="lower_chest", compound_or_isolation="compound", difficulty=4, equipment_needed="bodyweight", description="双杠上身体前倾，下降至肩略低于肘，推起。", common_mistakes="下降幅度过大伤肩", tags=["strength","mass"]),
        ExerciseLibrary(name="引体向上", name_en="Pull Up", target_muscle_group="back", target_sub_muscle="lats", compound_or_isolation="compound", difficulty=4, equipment_needed="bodyweight", description="正手宽握，拉至下巴过杠，控制下放。", common_mistakes="借力摆荡，半程动作", tags=["strength","width"]),
        ExerciseLibrary(name="杠铃划船", name_en="Barbell Row", target_muscle_group="back", target_sub_muscle="mid_back", compound_or_isolation="compound", difficulty=3, equipment_needed="barbell", description="俯身45度，杠铃沿大腿拉至腹部。", common_mistakes="下背弯曲，借力过多", tags=["strength","thickness"]),
        ExerciseLibrary(name="高位下拉", name_en="Lat Pulldown", target_muscle_group="back", target_sub_muscle="lats", compound_or_isolation="compound", difficulty=2, equipment_needed="cable", description="坐姿宽握，拉至锁骨位置。", common_mistakes="过度后仰借力", tags=["strength","width"]),
        ExerciseLibrary(name="面拉", name_en="Face Pull", target_muscle_group="back", target_sub_muscle="rear_delts", compound_or_isolation="isolation", difficulty=2, equipment_needed="cable", description="绳索拉至面部高度，外旋肩膀。", common_mistakes="重量过大，动作变形", tags=["posture","rear_delts","rotator_cuff"]),
        ExerciseLibrary(name="杠铃深蹲", name_en="Barbell Squat", target_muscle_group="legs", target_sub_muscle="quads", compound_or_isolation="compound", difficulty=4, equipment_needed="barbell", description="高杠位深蹲，下蹲至大腿平行地面。", common_mistakes="膝盖内扣，下背弯曲", tags=["strength","mass","core"]),
        ExerciseLibrary(name="罗马尼亚硬拉", name_en="Romanian Deadlift", target_muscle_group="legs", target_sub_muscle="hamstrings", compound_or_isolation="compound", difficulty=3, equipment_needed="barbell", description="膝盖微屈，髋部后推下降杠铃。", common_mistakes="下背弯曲，膝盖过度前移", tags=["strength","posterior_chain"]),
        ExerciseLibrary(name="保加利亚分腿蹲", name_en="Bulgarian Split Squat", target_muscle_group="legs", target_sub_muscle="quads", compound_or_isolation="compound", difficulty=3, equipment_needed="dumbbell", description="后脚抬高，前腿下蹲至大腿平行地面。", common_mistakes="前膝超过脚尖过多", tags=["unilateral","balance"]),
        ExerciseLibrary(name="坐姿腿屈伸", name_en="Leg Extension", target_muscle_group="legs", target_sub_muscle="quads", compound_or_isolation="isolation", difficulty=1, equipment_needed="machine", description="孤立刺激股四头肌，顶峰收缩。", common_mistakes="速度过快，无顶峰收缩", tags=["isolation","definition"]),
        ExerciseLibrary(name="站姿杠铃推举", name_en="Standing OHP", target_muscle_group="shoulders", target_sub_muscle="front_delts", compound_or_isolation="compound", difficulty=4, equipment_needed="barbell", description="站姿杠铃推至头顶，核心稳定。", common_mistakes="过度挺腰借力", tags=["strength","mass"]),
        ExerciseLibrary(name="哑铃侧平举", name_en="Lateral Raise", target_muscle_group="shoulders", target_sub_muscle="side_delts", compound_or_isolation="isolation", difficulty=2, equipment_needed="dumbbell", description="哑铃向两侧抬起至肩高，控制下放。", common_mistakes="借力摆荡，重量过大", tags=["width","definition"]),
        ExerciseLibrary(name="蝴蝶机反向飞鸟", name_en="Reverse Pec Deck", target_muscle_group="shoulders", target_sub_muscle="rear_delts", compound_or_isolation="isolation", difficulty=1, equipment_needed="machine", description="针对后束，改善圆肩体态。", common_mistakes="肩胛骨未打开", tags=["posture"]),
        ExerciseLibrary(name="杠铃弯举", name_en="Barbell Curl", target_muscle_group="arms", target_sub_muscle="biceps", compound_or_isolation="isolation", difficulty=1, equipment_needed="barbell", description="站立弯举，肘部固定，顶峰收缩。", common_mistakes="借力摆荡，肘部移动", tags=["biceps","mass"]),
        ExerciseLibrary(name="窄距卧推", name_en="Close Grip Bench Press", target_muscle_group="arms", target_sub_muscle="triceps", compound_or_isolation="compound", difficulty=3, equipment_needed="barbell", description="窄握杠铃，刺激三头肌长头。", common_mistakes="握距过窄伤腕", tags=["triceps","mass"]),
        ExerciseLibrary(name="锤式弯举", name_en="Hammer Curl", target_muscle_group="arms", target_sub_muscle="brachialis", compound_or_isolation="isolation", difficulty=1, equipment_needed="dumbbell", description="对握弯举，增加手臂厚度。", common_mistakes="摆动借力", tags=["brachialis","thickness"]),
        ExerciseLibrary(name="平板支撑", name_en="Plank", target_muscle_group="core", target_sub_muscle="abs", compound_or_isolation="isolation", difficulty=1, equipment_needed="bodyweight", description="肘支撑，保持身体直线。", common_mistakes="塌腰或拱臀", tags=["core","stability"]),
        ExerciseLibrary(name="悬垂举腿", name_en="Hanging Leg Raise", target_muscle_group="core", target_sub_muscle="lower_abs", compound_or_isolation="isolation", difficulty=3, equipment_needed="bodyweight", description="悬挂在单杠上，抬腿至水平。", common_mistakes="借力摆荡，幅度不足", tags=["core","lower_abs"]),
        ExerciseLibrary(name="杠铃臀桥", name_en="Barbell Hip Thrust", target_muscle_group="legs", target_sub_muscle="glutes", compound_or_isolation="isolation", difficulty=2, equipment_needed="barbell", description="肩胛骨靠凳，杠铃置于髋部推起。", common_mistakes="过度挺腰代偿", tags=["glutes","posterior_chain"]),
    ]
    session.add_all(exercises)
