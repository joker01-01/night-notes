# 夜记｜随手记一点，每周问自己一句

夜记是一个本地优先、低压力的自我反思与方向校准工具。

它不要求你每天打卡，也不替你总结人生。你可以在晚上留下今天最想记住的一点，到了周日或周一，再从这一周的痕迹里挑一件真正占心力的事，问自己一句，并留下自己的回答。

> 夜记只做自我反思与方向校准，不做诊断和治疗。

## 它想解决什么

很多周复盘最后只剩下「这周做了什么」，却忘了当时为什么在意、犹豫或期待。夜记把记录拆成两种节奏：

- **日轻：** 自由写几句话，或者只留下一个情绪；写完就可以离开。
- **周重：** 从近期痕迹中选一件事，也可以自己写主题，让夜记问自己一个具体的问题，再用自己的话回答。

核心不是 AI 的长篇总结，而是你在当下留下的感受、分量和回答。

## 当前试用版

Flutter Android 试用版已经可以分发给小范围朋友使用，包含：

- 今晚：自由记录、情绪痕迹、可选的自问与收束。
- 本周：候选主题、自定义主题、周问、回答与短回声。
- 历史：按日和按周回看自己的记录，默认只读。
- 本地优先：完整问答保存在设备本地 Drift SQLite 数据库。
- 可选 AI：配置 DeepSeek Key 后才会在主动点击相关按钮时联网；无 Key 或网络失败时使用本地兜底问题。

当前试用版暂不提供账号、云同步、自动提醒、导入导出和社交功能。

![夜记功能预览](docs/images/screenshot-placeholder.svg)

> **产品定位与设计原则以 [`PRODUCT.md`](PRODUCT.md) 为准。**

## 现状与路线

| 轨道 | 状态 | 说明 |
|------|------|------|
| **日（轻）** | 已可用 | 自由书写 → 存一下/先这样；可选「再问自己一句」与短收束。**每日四问制已废案。** |
| **周（重）** | 试用版已补齐 | 候选主题 → 用户自选/自定义 → 情绪可选 → 一个周问 → 用户回答 → 短回声；核心资产是周问+回答 |

### Flutter Android MVP

移动端当前已完成可直接分发给朋友试用的本地闭环：

- **今晚：** 自由记录文字或只选情绪；只有文字记录才出现 AI 追问，支持回答、深化和短收束。
- **本周：** 本地生成 2～3 个候选主题，也可自定义；选择主题和情绪后生成周问，回答后保存完整回声、下一步和备注。
- **历史：** 按时间回看每日记录与周场结果，默认只读，不覆盖原始痕迹。
- **本地：** Drift SQLite 保存完整问答；首次启动检测到旧 `SharedPreferences` 数据才迁移，Key 暂存本机偏好设置。
- **AI：** DeepSeek API Key 可选；无 Key、网络失败或返回异常时使用本地问题与保守收束。

release APK：`mobile/build/app/outputs/flutter-apk/app-release.apk`。

> **发布路线（2026-07-31）：** Flutter 全平台重写；本地优先 + 可选端到端加密同步；BYOK 设备端直连 AI；免费核心 + 同步订阅（许可证码）。详见 [PRODUCT.md](PRODUCT.md) 与 [docs/decisions/2026-07-31-publish-architecture.md](docs/decisions/2026-07-31-publish-architecture.md)。

硬规则见 `PRODUCT.md`：**当时感不可事后补全**；**每日四问制已废案**；长提纲与重对话只属于周场。

## 功能（当前代码）

- 导航：今晚 / 本周 / 回看；设置为次级入口。
- 今晚：自由书写或只选一个情绪；只有情绪不触发 AI；可选自问与可选收一收。
- 本周：七日格 + 痕迹；从近七日痕迹生成 2～3 个候选主题，用户选择或自定义后生成一个温柔周问 → 作答落库 → 短回声（echo / next_focus / note）。没有日痕迹时也可用自定义主题直接起步。
- 回看：日历归档；旧四问历史兼容可读；新数据展示自由写 / 周问答。
- APScheduler 每日定时创建「今晚正文」占位会话（默认 21:00，Asia/Shanghai），**不再出四道固定题**。
- LLM Provider：DeepSeek、OpenAI 兼容 API、Ollama；Prompt 在 `app/llm/prompts.py`。

## 项目结构

```text
.
├── app/
│   ├── api/             # FastAPI 路由与 HTTP 边界
│   ├── core/            # pydantic-settings 配置、SQLAlchemy 连接
│   ├── llm/             # Provider 抽象 + prompts
│   ├── models/          # DailySession / QA / Summary / Settings / WeeklyReview
│   ├── notifier/        # 通知抽象，当前为 Web 提醒
│   ├── scheduler/       # APScheduler 每日任务
│   ├── services/        # 日场、周场、设置、痕迹聚合
│   ├── static/          # 原生 HTML/CSS/JS 前端
│   └── main.py
├── mobile/                 # Flutter Android MVP
├── tests/
├── scripts/
├── config.yaml
├── .env.example
├── PRODUCT.md           # 产品定位与设计原则（宪法）
├── CHANGELOG.md
├── PROGRESS.md
└── TODO.md
```

## 快速开始

要求 Python 3.11+。

```bash
python -m venv .venv
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

浏览器打开 [http://127.0.0.1:8000](http://127.0.0.1:8000)。首次启动会创建 `data/ai_daily_review.db`。未填 Key 也可记录与回看；需要 AI 时再在设置页配置模型。

```bash
pytest
python scripts/demo_review_flow.py
```

## Docker

见仓库内 `Dockerfile` 与 `docker-compose.yml`（默认仅绑定本机）。

## 数据与隐私

- Web 原型使用本地 SQLite；Flutter 端使用设备本地存储。API Key 当前只保存在本机（移动端正式发布前迁移到系统 Keychain/Keystore），Key 永不上云。
- 日痕迹供周场消费；周问+回答是周场核心资产。

## 许可

MIT。详见 [LICENSE](LICENSE)。
