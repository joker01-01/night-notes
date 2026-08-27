<p>
  <a href="#english"><kbd>&nbsp;English&nbsp;</kbd></a>
  &nbsp;
  <a href="#zhong-wen"><kbd>&nbsp;中文&nbsp;</kbd></a>
</p>

<a id="english"></a>

# Night Notes / 夜记

Local-first AI reflection app built with Flutter, FastAPI, and pluggable LLM providers.

AI is optional. The product is the ritual: note a little at night, ask yourself one question each week.

This repository is a complete local-first AI product, not a chatbot wrapper: on-device storage, optional LLM calls, fail-soft fallbacks, tests, Docker, and a written product constitution.

## Demo

There is no hosted public demo yet.

- **Web prototype:** run locally at `http://127.0.0.1:8000`
- **Android trial:** Flutter APK at `mobile/build/app/outputs/flutter-apk/app-release.apk` after `flutter build apk --release`

TODO: add real product screenshots

## Why this exists

Weekly reviews often collapse into “what I did,” while the feeling and weight of the week are already gone.

Night Notes splits the workflow:

- **Daily / light** — a few sentences, or just one emotion. Then leave.
- **Weekly / heavy** — pick one thing that actually occupied you, answer one question in your own words, keep that record.

The product is self-reflection and direction-checking. It is not diagnosis, coaching, or therapy.

## What it does

| Surface | What ships today |
| --- | --- |
| Flutter Android trial | Tonight / This week / History / Settings. Drift SQLite on device. Optional DeepSeek. Local fallback if the key or network is missing. |
| FastAPI + web prototype | Same dual-track flow in the browser. SQLAlchemy SQLite. Pluggable LLM providers. |

Current trial explicitly does **not** include accounts, cloud sync, push notifications, import/export, or social features.

Product rules live in [`PRODUCT.md`](PRODUCT.md).

## Architecture

```mermaid
flowchart LR
  user[User]
  flutter[Flutter Android]
  web[Web prototype]
  local[(Local SQLite / Drift)]
  svc[Service layer]
  llm[LLM Provider]
  ds[DeepSeek]
  oai[OpenAI-compatible]
  oll[Ollama]

  user --> flutter
  user --> web
  flutter --> local
  web --> local
  flutter --> svc
  web --> svc
  svc --> llm
  llm --> ds
  llm --> oai
  llm --> oll
```

Local-first: notes stay on the device or in a local database. The model is called only when the user triggers it.

Provider split (what the code actually does):

- **FastAPI backend** — `app/llm/providers.py` abstracts DeepSeek, OpenAI-compatible APIs, and Ollama behind `chat(messages)`.
- **Flutter Android** — talks to `https://api.deepseek.com/chat/completions` with model `deepseek-chat`. No Ollama / OpenAI-compatible switch in the mobile client yet.

## Engineering highlights

- **Product before prompt.** Daily-light / weekly-heavy is a documented constraint, not a UI theme. The old “four questions every night” path is explicitly abandoned.
- **LLM is optional.** No key, network failure, or bad response → local questions and conservative closing text. Emotion-only days do not trigger AI.
- **Provider abstraction on the server.** Business code depends on `chat(messages)`, not a vendor SDK.
- **Secrets stay local.** Flutter API keys use `FlutterSecureStorage` (Android Keystore), with a one-time migration off legacy `SharedPreferences`. Keys are not uploaded.
- **Prompt and API boundaries.** Tests cover prompt injection / secret leakage (`tests/test_prompts.py`, `tests/test_llm_guard.py`) and LLM request idempotency (`app/core/llm_guard.py`).
- **CI.** GitHub Actions runs `pytest` and `pip-audit` on the Python backend. Flutter tests exist under `mobile/test/` but are not in that workflow yet.
- **Docker binds localhost only.** `docker-compose.yml` maps `127.0.0.1:8000` so the unauthenticated local API is not exposed on the LAN.

## Tech stack

| Layer | Stack |
| --- | --- |
| Android | Flutter, Drift / SQLite, `flutter_secure_storage` |
| Backend / web | Python 3.11, FastAPI, SQLAlchemy, APScheduler, vanilla HTML/JS |
| LLM | DeepSeek; OpenAI-compatible and Ollama on the FastAPI side |
| Quality | pytest, Flutter widget/database tests, pip-audit, Docker |

## Getting started

### Web prototype

Python 3.11+.

```bash
python -m venv .venv
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

Open [http://127.0.0.1:8000](http://127.0.0.1:8000). First launch creates `data/ai_daily_review.db`. Recording and history work without a key.

```bash
pytest
python scripts/demo_review_flow.py
```

Docker: see `Dockerfile` and `docker-compose.yml`.

### Android trial

```bash
cd mobile
flutter pub get
dart run build_runner build
flutter run
# or
flutter build apk --release
```

## Design decisions

- **AI does not write the user's answer.** It may propose a weekly question and a short echo. The answer must be the user's own words (`PRODUCT.md`).
- **BYOK.** The user brings a key; the app does not host a shared model quota.
- **Fail-soft over fail-loud.** The nightly ritual has to work when the network does not.
- **Publish architecture is documented,** including a later optional end-to-end encrypted sync path that is **not implemented** in this trial. See `docs/decisions/2026-07-31-publish-architecture.md`.

## Limitations

- Android trial + local web prototype only. No iOS / desktop client in this repo yet.
- Flutter client is DeepSeek-only; Ollama / OpenAI-compatible providers are on the FastAPI side.
- No public screenshots, hosted demo, or published store listing.
- GitHub Actions does not yet run Flutter tests.
- Cloud sync, notifications, and import/export are out of scope for the current trial.

## License

MIT. See [LICENSE](LICENSE).

---

<a id="zhong-wen"></a>

# 中文

<p>
  <a href="#english"><kbd>&nbsp;English&nbsp;</kbd></a>
  &nbsp;
  <a href="#zhong-wen"><kbd>&nbsp;中文&nbsp;</kbd></a>
</p>

# 夜记

本地优先的 AI 反思应用，基于 Flutter、FastAPI 和可插拔 LLM Provider。

**一句话：** 随手记一点，每周问自己一句。AI 是可选能力，不是产品本身。

这不是聊天机器人套壳：本地存储、按需调用模型、失败可兜底、有测试、有 Docker、有产品宪法。

## Demo

目前没有公开托管演示。

- **Web 原型：** 本地打开 `http://127.0.0.1:8000`
- **Android 试用版：** `flutter build apk --release` 后产物在 `mobile/build/app/outputs/flutter-apk/app-release.apk`

TODO: add real product screenshots

## 它想解决什么

周复盘常常只剩下「这周做了什么」，当时的感受和分量已经没了。

夜记拆成两种节奏：

- **日轻：** 写几句，或只留一个情绪，然后离开。
- **周重：** 选一件真正占心力的事，用自己的话回答一个问题，把这份记录留下来。

产品只做自我反思与方向校准，不做诊断、教练或治疗。

## 当前能做什么

| 端 | 现状 |
| --- | --- |
| Flutter Android 试用版 | 今晚 / 本周 / 历史 / 设置。设备内 Drift SQLite。可选 DeepSeek。无 Key 或网络失败时本地兜底。 |
| FastAPI + Web 原型 | 浏览器里同一套双轨流程。SQLAlchemy SQLite。可插拔 LLM Provider。 |

试用版明确不做：账号、云同步、推送、导入导出、社交。

产品规则以 [`PRODUCT.md`](PRODUCT.md) 为准。

## 架构

见上方英文 Architecture 图。代码里的 Provider 分工：

- **FastAPI：** `app/llm/providers.py` 把 DeepSeek、OpenAI 兼容 API、Ollama 收成 `chat(messages)`。
- **Flutter Android：** 只请求 `https://api.deepseek.com/chat/completions`，模型 `deepseek-chat`。移动端还没有 Ollama / OpenAI-compatible 切换。

## 工程亮点

- 日轻 / 周重是写进宪法的约束，不是 UI 主题。每日四问制已废案。
- LLM 可选。没 Key、网络失败、返回异常 → 本地问题和保守收束。只有情绪、没有文字的天不触发 AI。
- 服务端业务代码依赖 `chat(messages)`，不绑某个厂商 SDK。
- Flutter API Key 使用 `FlutterSecureStorage`（Android Keystore），并从旧版明文 `SharedPreferences` 迁走。Key 不上云。
- 测试覆盖 prompt 边界和 LLM 请求幂等。CI 跑 Python `pytest` + `pip-audit`。Flutter 测试在 `mobile/test/`，尚未进 GitHub Actions。
- Docker 只绑定 `127.0.0.1:8000`，避免局域网暴露无鉴权接口。

## 快速开始

运行命令与英文 [Getting started](#getting-started) 相同。Android 说明见 [`mobile/README.md`](mobile/README.md)。

## 局限

- 目前只有 Android 试用版和本地 Web 原型。
- Flutter 端只接 DeepSeek。
- 没有公开截图、托管 Demo、商店上架。
- 云同步、通知、导入导出不在本轮范围。
