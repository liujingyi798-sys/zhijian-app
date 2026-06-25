# 智健 App — 发布上线指南

## 一、构建 APK（Android 安装包）

### 1. 安装 Android Studio
1. 下载：https://developer.android.com/studio
2. 安装时保持默认选项（会自动装 JDK + Android SDK）
3. 安装完成后打开 Android Studio → SDK Manager → 安装 Android 14.0 (API 34)

### 2. 构建 APK
```bash
cd C:\Users\LFCYHY\zhijian\frontend\zhijian_app
flutter build apk --release
```

APK 文件在：`build\app\outputs\flutter-apk\app-release.apk`

直接发这个 .apk 文件给别人，他们就能安装使用了。

---

## 二、部署后端到云服务器

要让别人从外网访问，后端必须部署到云服务器上。

### 方案 A：Railway（推荐，最简单，有免费额度）

1. 去 https://railway.app 注册（用 GitHub 登录）
2. 安装 Railway CLI，或在网页上操作
3. 在项目根目录执行：
```bash
railway init
railway up
```
Railway 会自动检测 Dockerfile 并部署，免费额度够几百人用。

### 方案 B：阿里云/腾讯云轻量服务器（国内用户推荐）

1. 买一台轻量服务器（最便宜的 ¥68/月）
2. SSH 连接上去，安装 Docker：
```bash
curl -fsSL https://get.docker.com | sh
```
3. 上传项目：
```bash
scp -r zhijian/ user@your-server-ip:/home/user/
```
4. 在服务器上启动：
```bash
cd /home/user/zhijian
docker-compose up -d
```

### 方案 C：Render（免费，适合测试）

1. 去 https://render.com 注册
2. 创建 Web Service → 连接 GitHub
3. 自动检测 Dockerfile 并部署
4. 免费版有 15 分钟无访问自动休眠的限制

---

## 三、部署后配置

无论用哪个方案，部署后需要设置环境变量：

```
DEEPSEEK_API_KEY=你的key          # DeepSeek AI
JWT_SECRET_KEY=一个随机字符串       # 用于用户登录加密（生产环境必须改）
```

在 `.env` 文件里改好，或直接在各平台的环境变量面板里设置。

---

## 四、Flutter App 连接服务器

部署成功后你会得到一个域名，比如 `https://your-app.railway.app`。

修改前端 API 地址：
```
文件：frontend/zhijian_app/lib/config/api_config.dart
第 4 行：static const String baseUrl = 'https://你的域名';
```

重新构建 APK，用户就能通过外网使用了。

---

## 五、上架应用商店（可选）

### Google Play（$25 一次性）
1. 注册 Google Play 开发者账号：https://play.google.com/console
2. 交 $25 注册费
3. 上传 APK + 应用截图 + 隐私政策
4. 审核通常 1-3 天

### 国内应用商店
- 腾讯应用宝、华为应用市场、小米应用商店等
- 需要软著（软件著作权），可找代理办
- 审核周期较长（1-4 周）

---

## 六、当前项目状态

| 项目 | 状态 |
|------|------|
| 后端 API | ✅ 完成（FastAPI + SQLite/PostgreSQL + DeepSeek AI） |
| 视觉分析 | ✅ 完成（MediaPipe + SSIM 差分） |
| 5 种 AI 人格 | ✅ 完成（角度感知 + 专业解剖学术语） |
| JWT 用户认证 | ✅ 完成（注册/登录/数据隔离） |
| Flutter 前端 | ✅ 完成（3 页面：追踪/日历/视频） |
| APK 构建 | ⚠️ 需安装 Android Studio |
| 后端部署 | ⚠️ 需选云平台 |
| 应用商店 | ⚠️ 需开发者账号 |
