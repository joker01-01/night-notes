# 项目进度快照

更新时间：2026-08-12（项目根目录：`D:\\desktop\\app`）

## 总体进度：Web/PWA 与 Flutter Android 试用版核心闭环补齐，准备进入朋友试用

里程碑：**每日四问制已废案**；**周场当时感追问闭环已落地**；**Web/PWA 已补齐情绪-only、候选主题、冷启动自定义主题和周场承接**；产品形态冻结见 `docs/product-constitution.md`。
下一：10～15 人两周试用 → 根据周问质量和第二周回访数据迭代 → 再决定提醒、导出与安全增强。

## 发布路线（2026-07-31 定案，简版）

- 本地优先 + 可选端到端加密同步；BYOK 设备端直连 AI；B 阶段无账号，许可证码订阅同步。  
- Flutter 全平台；FastAPI 原型退役为开放自托管哑存储中继。  
- 纯设备本地通知；跨周对照最小版纳入重写。  
- 完整决策表见 `docs/decisions/2026-07-31-publish-architecture.md`。  
- 周场形态定案（2026-07-31）：选择化主路径 + AI 记忆管家分工 + 承接式上周信号；见 `docs/decisions/2026-07-31-weekly-review-form.md`。  
- 日轨极轻记定案（2026-07-31）：表情即痕迹，只有表情不触发 AI；见 `docs/decisions/2026-07-31-daily-light-capture.md`。  

## 已完成模块

- [x] FastAPI 应用、静态 Web 页面与本地启动入口。
- [x] SQLite 数据模型：DailySession、QA、Summary、Settings、WeeklyReview。
- [x] 周场 API：读周 / 存提纲 / 生成周问 / 存回答 / 短收束；痕迹聚合含未收束日正文。
- [x] 试用版周场：2～3 个候选主题、用户自选/自定义、情绪可选、冷启动无日痕迹也可开始。
- [x] 一次可关闭的本地周提醒：只存浏览器本地，每周最多一次，无逾期提示。
- [x] 启动时 `ensure_schema()` 为旧库补列（无 Alembic）。
- [x] 建会话改为单一「今晚正文」；不再按四问模板/智能出四题。
- [x] `app/llm/prompts.py`：日自问/日收束 + 周追问/周收束（自由写人设）。
- [x] 日场主路径：自由写 → 可选自问 → 可选收一收。
- [x] 日轨情绪-only：只标情绪也算痕迹，但不触发 AI。
- [x] 会话状态：`pending / answered / following_up / summarized`；支持重开今晚。
- [x] 日历回看（旧四问兼容展示）与无记录友好提示。
- [x] 前端双轨 UI；PRODUCT / README 对齐「夜记（日轻·周重）」。
- [x] Flutter Android 试用版：今晚 / 本周 / 历史 / 设置四条主路径。
- [x] Flutter Drift 本地数据层：完整日/周问答结果、旧 SharedPreferences 条件迁移、内存数据库测试。
- [x] Flutter 日轨与周轨：情绪-only 不触发 AI、候选主题、周场收束、历史只读回看与本地兜底。
- [x] Flutter 端 DeepSeek 可选调用、加载状态、失败兜底与 release APK 构建。

## 已知问题与技术债

- [x] 日场主路径已拆除四问默认；旧多题 QA 仅兼容读取。
- [x] 周场追问闭环：问→答→短收束；0 天拒收、缺日可收。
- [ ] Web 原型 API Key 明文存 SQLite；正式 Alembic 迁移仍属 P2。
- [x] Flutter API Key 使用 `FlutterSecureStorage`（Android Keystore），并从旧版明文 `SharedPreferences` 迁走。
- [ ] Flutter 暂未加入本地通知、导出/导入、云同步（均不在首轮试用范围）。
- [ ] 定时任务依赖进程常驻；尚无浏览器/外部通知渠道。
- [ ] 未加入登录/多用户隔离（非目标）。

## 关键设计决策

1. **日轻·周重：** 见 `PRODUCT.md`；每日四问废案；周问+回答是周场核心资产。
2. **SQLite + 单行 Settings：** 本地优先；密钥读取永不回显。
3. **Provider Protocol：** 业务只依赖 `chat(messages)`。
4. **自问有上限且可跳过：** 不绑架打开。
5. **日自问默认不注入近 N 天全文：** 边界清晰；痕迹主要服务周场。
6. **QA 扩展优于新表；旧四问记录兼容展示。**
7. **可靠性：** 自问 LLM 失败不自动出小结，提供重试/跳过。
