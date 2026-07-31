# 夜记（日轻 · 周重）

本地优先的中文自我复盘工具：平日五分钟自由书写，周日在痕迹仍热时问自己一句「这件事对你是什么感觉/分量」。

> **产品定位与原则以 [`PRODUCT.md`](PRODUCT.md) 为准。**  
> 改功能 / 改 UI / 改文案前先读它，避免定位漂移。

**一句话介绍：** 平时五分钟随手记；周日用近七日痕迹生成一个温柔周问，作答后极短收束。  
**核心差异：** 别人的 AI 周记总结「做了什么」；我们留下当时感，用来校正方向、少走弯路。

> 默认情况下，夜记、设置与本地归档只写入本机 SQLite。  
> 只有你主动触发 AI（可选自问、日收束、周问、周收束）时，才会把**当时所需**的上下文发送到你选择的 LLM API。

![功能截图占位](docs/images/screenshot-placeholder.svg)

## 现状与路线

| 轨道 | 状态 | 说明 |
|------|------|------|
| **日（轻）** | 已可用 | 自由书写 → 存一下/先这样；可选「再问自己一句」与短收束。**每日四问制已废案。** |
| **周（重）** | 已可用 | 近七日痕迹 → 问自己一句（本周）→ 作答 → 极短收束；核心资产是周问+回答 |

硬规则见 `PRODUCT.md`：**当时感不可事后补全**；**每日四问制已废案**；长提纲与重对话只属于周场。

## 功能（当前代码）

- 导航：今晚 / 本周 / 回看 / 设置。
- 今晚：自由书写；AI 默认关；可选自问与可选收一收。
- 本周：七日格 + 痕迹；生成一个温柔周问 → 作答落库 → 短收束（echo / next_focus / note）。
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

- 本地 SQLite；API Key 存本机设置表，接口不回显密钥。
- 日痕迹供周场消费；周问+回答是周场核心资产。

## 许可

MIT。详见 [LICENSE](LICENSE)。
