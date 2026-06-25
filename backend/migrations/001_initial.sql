-- 智健 (ZhiJian) Database Migration V001
-- PostgreSQL 15+

-- ============================================================
-- Extension
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone           VARCHAR(20) UNIQUE,
    email           VARCHAR(255) UNIQUE,
    nickname        VARCHAR(50) NOT NULL,
    avatar_url      VARCHAR(500),
    gender          VARCHAR(10),                -- male / female / other
    birthday        DATE,
    height_cm       DECIMAL(5,1),
    start_weight_kg DECIMAL(5,1),
    target_weight_kg DECIMAL(5,1),
    fitness_goal    VARCHAR(50) DEFAULT 'build_muscle',  -- build_muscle / lose_fat / maintain / compete
    fitness_level   VARCHAR(20) DEFAULT 'beginner',       -- beginner / intermediate / advanced / pro
    current_personality VARCHAR(20) DEFAULT 'gym_bro',
    streak_days     INT DEFAULT 0,
    total_days      INT DEFAULT 0,
    subscription_tier VARCHAR(20) DEFAULT 'free',          -- free / pro / premium
    subscription_expires_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- User Preferences (1:1 with users)
-- ============================================================
CREATE TABLE user_preferences (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    personality_history     JSONB DEFAULT '[]'::jsonb,
    notification_enabled    BOOLEAN DEFAULT TRUE,
    notification_remind_time TIME DEFAULT '08:00',
    privacy_cloud_analysis  BOOLEAN DEFAULT TRUE,
    privacy_share_data      BOOLEAN DEFAULT FALSE,
    photo_angle_preference  VARCHAR(20) DEFAULT 'front',
    video_bgm_preference    VARCHAR(20) DEFAULT 'auto',
    language                VARCHAR(10) DEFAULT 'zh-CN',
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Daily Photos
-- ============================================================
CREATE TABLE daily_photos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_date      DATE NOT NULL,
    photo_type      VARCHAR(10) NOT NULL,          -- front / side / back
    photo_url       VARCHAR(1000) NOT NULL,
    thumbnail_url   VARCHAR(1000),
    pose_keypoints  JSONB,                          -- MediaPipe 33 keypoints [{x,y,z,visibility}]
    alignment_score DECIMAL(4,3),                   -- 0.000-1.000
    is_benchmark    BOOLEAN DEFAULT FALSE,
    weight_kg       DECIMAL(5,1),
    body_fat_pct    DECIMAL(4,1),
    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, photo_date, photo_type)
);

CREATE INDEX idx_daily_photos_user_date ON daily_photos(user_id, photo_date DESC);
CREATE INDEX idx_daily_photos_user_benchmark ON daily_photos(user_id, is_benchmark) WHERE is_benchmark = TRUE;

-- ============================================================
-- AI Reports
-- ============================================================
CREATE TABLE ai_reports (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_id            UUID REFERENCES daily_photos(id) ON DELETE SET NULL,
    photo_date          DATE NOT NULL,
    structured_analysis JSONB NOT NULL,
    personality         VARCHAR(20) NOT NULL,
    report_text         TEXT NOT NULL,
    report_text_alt     JSONB DEFAULT '{}'::jsonb,  -- cached texts for other personalities
    generated_plan_id   UUID,                        -- FK added below
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_reports_user_date ON ai_reports(user_id, photo_date DESC);

-- ============================================================
-- Training Plans
-- ============================================================
CREATE TABLE training_plans (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_date       DATE NOT NULL,
    source          VARCHAR(20) DEFAULT 'auto',     -- auto / manual / coach
    status          VARCHAR(20) DEFAULT 'pending',  -- pending / in_progress / completed / skipped
    personality     VARCHAR(20) NOT NULL,
    notes           TEXT,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, plan_date)
);

CREATE INDEX idx_training_plans_user_date ON training_plans(user_id, plan_date DESC);

-- Add FK for ai_reports -> training_plans (deferred due to circular dependency)
ALTER TABLE ai_reports ADD CONSTRAINT fk_ai_reports_plan
    FOREIGN KEY (generated_plan_id) REFERENCES training_plans(id) ON DELETE SET NULL;

-- ============================================================
-- Exercise Library
-- ============================================================
CREATE TABLE exercise_library (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                    VARCHAR(100) NOT NULL,
    name_en                 VARCHAR(200),
    target_muscle_group     VARCHAR(50) NOT NULL,   -- chest/back/legs/shoulders/arms/core
    target_sub_muscle       VARCHAR(100),
    compound_or_isolation   VARCHAR(10) DEFAULT 'compound',
    difficulty              INT DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    equipment_needed        VARCHAR(100),
    alternative_exercise_id UUID REFERENCES exercise_library(id),
    video_url               VARCHAR(500),
    image_url               VARCHAR(500),
    description             TEXT,
    common_mistakes         TEXT,
    tags                    TEXT[] DEFAULT '{}',
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Plan Exercises
-- ============================================================
CREATE TABLE plan_exercises (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id         UUID NOT NULL REFERENCES training_plans(id) ON DELETE CASCADE,
    exercise_id     UUID REFERENCES exercise_library(id) ON DELETE SET NULL,
    exercise_name   VARCHAR(100) NOT NULL,
    target_muscle   VARCHAR(50),
    sets            INT NOT NULL,
    reps            VARCHAR(20) NOT NULL,             -- "8-12" or "10"
    weight_kg       DECIMAL(6,1),
    rest_seconds    INT DEFAULT 60,
    sort_order      INT DEFAULT 0,
    notes           VARCHAR(500),
    is_completed    BOOLEAN DEFAULT FALSE,
    actual_sets     INT,
    actual_weight_kg DECIMAL(6,1),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_plan_exercises_plan ON plan_exercises(plan_id);

-- ============================================================
-- Mood Checkins
-- ============================================================
CREATE TABLE mood_checkins (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    checkin_date DATE NOT NULL,
    mood        VARCHAR(10) NOT NULL,                 -- great / good / okay / bad / terrible
    energy_level INT CHECK (energy_level BETWEEN 1 AND 10),
    sleep_hours DECIMAL(3,1),
    notes       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, checkin_date)
);

-- ============================================================
-- Milestone Videos
-- ============================================================
CREATE TABLE milestone_videos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    photo_count     INT NOT NULL,
    video_url       VARCHAR(1000),
    thumbnail_url   VARCHAR(1000),
    bgm_track_id    VARCHAR(50),
    badge_name      VARCHAR(100),
    badge_url       VARCHAR(500),
    render_status   VARCHAR(20) DEFAULT 'queued',     -- queued / rendering / completed / failed
    render_progress INT DEFAULT 0,
    duration_seconds INT,
    format          VARCHAR(20) DEFAULT '1080x1920',
    error_message   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_milestone_videos_user ON milestone_videos(user_id, created_at DESC);

-- ============================================================
-- Comparison Snapshots
-- ============================================================
CREATE TABLE comparison_snapshots (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date_a      DATE NOT NULL,
    date_b      DATE NOT NULL,
    photo_type  VARCHAR(10) DEFAULT 'front',
    image_url   VARCHAR(1000) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Seed Data: Exercise Library
-- ============================================================
INSERT INTO exercise_library (name, name_en, target_muscle_group, target_sub_muscle, compound_or_isolation, difficulty, equipment_needed, description, tags) VALUES
-- Chest
('杠铃平板卧推', 'Barbell Bench Press', 'chest', 'middle_chest', 'compound', 3, 'barbell', '仰卧平板凳，杠铃下降至胸口，推起至手臂伸直。核心收紧，肩胛骨后缩。', ARRAY['strength', 'mass', 'core']),
('上斜哑铃卧推', 'Incline Dumbbell Press', 'chest', 'upper_chest', 'compound', 3, 'dumbbell', '上斜凳30-45度，哑铃推至上方，重点刺激上胸。', ARRAY['strength', 'mass', 'upper_chest']),
('绳索飞鸟', 'Cable Fly', 'chest', 'inner_chest', 'isolation', 2, 'cable', '龙门架双手飞鸟，顶峰收缩1-2秒。', ARRAY['isolation', 'definition', 'inner_chest']),
('双杠臂屈伸', 'Dips', 'chest', 'lower_chest', 'compound', 4, 'bodyweight', '双杠上身体前倾，下降至肩略低于肘，推起。', ARRAY['strength', 'mass', 'lower_chest']),
-- Back
('引体向上', 'Pull Up', 'back', 'lats', 'compound', 4, 'bodyweight', '正手宽握，拉至下巴过杠，控制下放。', ARRAY['strength', 'width', 'lats']),
('杠铃划船', 'Barbell Row', 'back', 'mid_back', 'compound', 3, 'barbell', '俯身45度，杠铃沿大腿拉至腹部，挤压背部。', ARRAY['strength', 'thickness', 'mid_back']),
('高位下拉', 'Lat Pulldown', 'back', 'lats', 'compound', 2, 'cable', '坐姿宽握，拉至锁骨位置，控制回放。', ARRAY['strength', 'width', 'lats']),
('面拉', 'Face Pull', 'back', 'rear_delts', 'isolation', 2, 'cable', '绳索拉至面部高度，外旋肩膀，强化后束和肩袖。', ARRAY['posture', 'rear_delts', 'rotator_cuff']),
-- Legs
('杠铃深蹲', 'Barbell Squat', 'legs', 'quads', 'compound', 4, 'barbell', '高杠位深蹲，下蹲至大腿平行地面，保持躯干直立。', ARRAY['strength', 'mass', 'core']),
('罗马尼亚硬拉', 'Romanian Deadlift', 'legs', 'hamstrings', 'compound', 3, 'barbell', '膝盖微屈，髋部后推下降杠铃，感受腘绳肌拉伸。', ARRAY['strength', 'posterior_chain', 'hamstrings']),
('保加利亚分腿蹲', 'Bulgarian Split Squat', 'legs', 'quads', 'compound', 3, 'dumbbell', '后脚抬高，前腿下蹲至大腿平行地面，纠正左右不平衡。', ARRAY['unilateral', 'balance', 'legs']),
('坐姿腿屈伸', 'Leg Extension', 'legs', 'quads', 'isolation', 1, 'machine', '孤立刺激股四头肌，顶峰收缩。', ARRAY['isolation', 'quads', 'definition']),
-- Shoulders
('站姿杠铃推举', 'Standing Overhead Press', 'shoulders', 'front_delts', 'compound', 4, 'barbell', '站姿杠铃推至头顶，核心稳定。', ARRAY['strength', 'mass', 'shoulders']),
('哑铃侧平举', 'Lateral Raise', 'shoulders', 'side_delts', 'isolation', 2, 'dumbbell', '哑铃向两侧抬起至肩高，控制下放，不过度借力。', ARRAY['width', 'side_delts', 'definition']),
('蝴蝶机反向飞鸟', 'Reverse Pec Deck', 'shoulders', 'rear_delts', 'isolation', 1, 'machine', '针对后束，改善圆肩体态。', ARRAY['posture', 'rear_delts']),
-- Arms
('杠铃弯举', 'Barbell Curl', 'arms', 'biceps', 'isolation', 1, 'barbell', '站立弯举，肘部固定，顶峰收缩。', ARRAY['biceps', 'mass']),
('窄距卧推', 'Close Grip Bench Press', 'arms', 'triceps', 'compound', 3, 'barbell', '窄握杠铃，刺激三头肌长头。', ARRAY['triceps', 'mass']),
('锤式弯举', 'Hammer Curl', 'arms', 'brachialis', 'isolation', 1, 'dumbbell', '对握弯举，增加手臂厚度。', ARRAY['brachialis', 'thickness']),
-- Core
('平板支撑', 'Plank', 'core', 'abs', 'isolation', 1, 'bodyweight', '肘支撑，保持身体直线，核心收紧。', ARRAY['core', 'stability']),
('悬垂举腿', 'Hanging Leg Raise', 'core', 'lower_abs', 'isolation', 3, 'bodyweight', '悬挂在单杠上，抬腿至水平或更高。', ARRAY['core', 'lower_abs']);
