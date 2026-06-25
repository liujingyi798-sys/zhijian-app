# 智健 (ZhiJian)

> AI-powered fitness progress tracking app.  
> 拍一张照片，AI 告诉你哪里进步了、哪里需要加强，并自动调整明天的训练计划。

---

## 项目结构

```
zhijian/
├── backend/                    # Python FastAPI 后端
│   ├── app/
│   │   ├── main.py            # FastAPI 入口
│   │   ├── config.py          # 配置（环境变量驱动）
│   │   ├── models/            # SQLAlchemy 数据模型（10 张表）
│   │   ├── routes/            # API 路由
│   │   │   ├── users.py       # 用户注册/管理
│   │   │   ├── photos.py      # 照片上传 + AI 分析主流程
│   │   │   ├── reports.py     # 报告查询 + 人格切换
│   │   │   ├── plans.py       # 训练计划
│   │   │   └── calendar.py    # 日历 + 对比
│   │   ├── services/
│   │   │   ├── vision.py      # 视觉分析引擎（MediaPipe + SSIM）
│   │   │   ├── llm.py         # LLM 调用层（Claude/GPT-4o）
│   │   │   └── training.py    # 自适应训练计划生成
│   │   ├── prompts/
│   │   │   └── personalities.py  # 5 种 AI 教练人格 Prompt
│   │   └── utils/image.py     # 图片处理工具
│   ├── migrations/
│   │   └── 001_initial.sql    # 完整建库脚本 + 动作库种子数据
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/zhijian_app/       # Flutter 移动端
│   └── lib/
│       ├── main.dart           # App 入口
│       ├── app.dart            # 主 Scaffold + 底部导航
│       ├── config/
│       │   ├── api_config.dart # API 地址配置
│       │   └── theme.dart      # 暗黑主题 + 人格配色
│       ├── models/index.dart   # 所有数据模型
│       ├── services/api_service.dart  # HTTP 通信层
│       └── screens/
│           ├── home/           # 📸 今日追踪（首页）
│           │   ├── home_screen.dart
│           │   └── widgets/
│           │       ├── camera_view.dart       # 拍照取景框
│           │       ├── analysis_card.dart     # AI 分析报告卡片
│           │       ├── plan_card.dart         # 训练计划卡片
│           │       └── personality_picker.dart # 人格切换器
│           ├── calendar/       # 📅 时光日历
│           │   └── calendar_screen.dart
│           └── video/          # 🎬 蜕变视频
│               └── video_screen.dart
├── docker-compose.yml          # 一键启动全部服务
└── README.md
```

## 快速启动

### 1. 启动后端服务

```bash
# 安装 Python 依赖
cd backend
pip install -r requirements.txt

# 复制配置
cp .env.example .env
# 编辑 .env 填入你的 ANTHROPIC_API_KEY 或 OPENAI_API_KEY

# 或用 Docker Compose 一键启动全部服务：
cd ..
docker-compose up -d
```

### 2. 初始化数据库

```bash
# Docker 已自动执行 migrations/001_initial.sql
# 手动执行：
psql -h localhost -U zhijian -d zhijian -f backend/migrations/001_initial.sql
```

### 3. 启动 Flutter App

```bash
cd frontend/zhijian_app
flutter pub get
flutter run
```

## API 端点速览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
| GET | `/api/personalities` | 获取全部 5 种 AI 人格 |
| POST | `/api/photos/upload` | **核心流程**：上传照片→AI分析→返回报告+计划 |
| POST | `/api/reports/:id/switch-personality` | 热切换报告人格 |
| GET | `/api/calendar/month` | 获取月度日历数据 |
| POST | `/api/calendar/compare` | 生成滑块对比图 |

## 五 AI 教练人格

| 人格 | 代号 | 特征 |
|------|------|------|
| 🗿 高冷毒舌 | `strict_pro` | 话少、客观、一针见血 |
| 🔥 热血搞怪 | `gym_bro` | 极度亢奋、健身梗拉满 |
| ✨ 萌系正太 | `cute_cheerleader` | 崇拜语气 + 颜文字 |
| 😤 傲娇调皮 | `playful_tsundere` | 嘴硬心软、暗中关心 |
| 🌱 单纯小白 | `innocent_rookie` | 谦逊诚恳、陪练搭子 |

## 技术栈

- **前端**: Flutter 3.16+
- **后端**: Python 3.12 + FastAPI
- **数据库**: PostgreSQL 16 + Redis 7
- **对象存储**: MinIO (S3 兼容)
- **视觉 AI**: MediaPipe Pose + SSIM 差分
- **大模型**: Claude Sonnet / GPT-4o
- **视频渲染**: FFmpeg + GPU 实例

## MVP 状态

- [x] 拍照上传 + 轮廓对齐引导
- [x] AI 增量视觉分析（ROI 对比 + 对称性 + 体态）
- [x] 单人格 AI 报告 + 人格热切换 UI
- [x] 自适应训练计划生成
- [x] 日历月视图 + 日详情
- [x] 蜕变视频生成流程
- [x] 5 种人格 Prompt 全量
- [ ] DB 读写实现（模型已就绪，路由待接 DB）
- [ ] LLM API Key 配置后即可端到端运行
