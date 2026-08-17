# CHANGELOG

- [2026-08-17] fix/security FIX-1: API 改为本机一次性初始化令牌鉴权，Web 请求统一携带 Bearer token。
- [2026-08-17] fix/security FIX-2: 增加受信任 Host 校验，拒绝 DNS rebinding Host。
- [2026-08-17] fix/security FIX-3: 容器默认仅绑定 127.0.0.1，并对非回环绑定给出告警。
- [2026-08-17] fix/security FIX-5: LLM 出口限定 HTTPS 白名单，拒绝 userinfo 与私有地址。
- [2026-08-17] fix/security FIX-6: LLM HTTP 客户端禁用环境代理与重定向。
- [2026-08-17] fix/security FIX-8: 日、周状态迁移使用条件 UPDATE，竞态改为明确 409。
- [2026-08-17] fix/security FIX-9: 已收束的日/周记录拒绝再次触发收束。
- [2026-08-17] fix/security FIX-10: LLM 触发路径为单状态占位，避免并发重复消费。
- [2026-08-17] fix/security FIX-11: 重开需显式确认，收束改为带删除时间戳的软删除。
- [2026-08-17] fix/security FIX-4: API 拒绝跨源状态变更与非 JSON 写请求。
- [2026-08-17] fix/security FIX-7: 打开本周页仅生成本地候选，AI 联网改为明确点击。
- [2026-08-17] fix/security FIX-12: API 请求体限制为 1MB，集合与模板条目均设上限。
- [2026-08-17] fix/security FIX-13: 增加拒绝嵌入、CSP 与 API no-store 响应头。

- [2026-08-12] feat/mobile: Flutter Android 试用版同步完成：Drift 本地数据库、旧 SharedPreferences 条件迁移、每日情绪与可选追问、周候选主题与完整收束、历史只读回看、可选 DeepSeek 与本地兜底；生成 release APK。

- [2026-08-12] feat/pilot: Web/PWA 补齐试用闭环：日轨情绪-only 痕迹、2～3 个周场候选主题、用户自选/自定义主题、周场情绪、冷启动自定义主题、有限周场承接，并补充迁移与自动化测试。

- [2026-08-12] docs/product: 冻结「夜记｜每周问自己一句」产品形态与两周试用方案：日常记录可选且不触发 AI；周场无截止时间；AI 一问一答、用户回答为核心资产；新增 [`docs/product-constitution.md`](docs/product-constitution.md) 与 [`docs/decisions/2026-08-12-product-shape-freeze.md`](docs/decisions/2026-08-12-product-shape-freeze.md)，并更新试用成功标准。

- [2026-08-07] feat/mobile: Flutter Android MVP 接通 DeepSeek 周问真实请求；设置页保存本机 Key，增加请求加载态、失败兜底与 Android 网络权限；今晚文案改为「写下今天最想留下的一点，不用完整」，同步更新 PRODUCT / README / PROGRESS。
- [2026-07-31] feat/定位: 日轨极轻记定案——可选「表情 ± 一句话」，表情即痕迹；daily_sessions 新增 emotion；只有表情不触发 AI；自由书写仍为主路径（防每日四问幽灵借壳）；决策记录 003 落地。
- [2026-07-31] feat/定位: 周场细节定案——弹性热窗（周一/周二宽限，周三起降级「只收不问」）；表情预选集 8+跳过；周问/收束 prompt 定稿；决策记录 002 补全。
- [2026-07-31] feat/定位: 周场形态定案——选择化主路径（自选一件 → 情绪表情 → 温柔周问 → 一句话作答 → 收束确认）；AI 分工定界（记忆管家：检索/对照/出题/收束草稿；不代写回答、不先出总结）；上周信号改承接式；提纲热身退役；weekly_reviews 新增 followup_emotion（Flutter schema）；决策记录 002 落地。
- [2026-07-31] feat/定位: 发布路线定案（B 先行 / A 后扩）——本地优先 + 可选端到端加密同步；BYOK 设备端直连 AI；无账号 + 许可证码同步订阅；Flutter 全平台重写，FastAPI 退役为开放自托管哑存储中继；纯设备本地通知；跨周对照最小版纳入重写；原型冻结并提交基线 8e3e9e6。PRODUCT.md 修订 + docs/decisions/2026-07-31-publish-architecture.md 落地。
- [2026-07-30 09:20] feat/定位: 废案每日四问——建会话仅「今晚正文」、配置/设置不再出四题；周场当时感追问为主路径；PRODUCT/README/demo/pytest 对齐。
- [2026-07-29 22:50] feat/定位: 周场改追问主路径（问一句→作答→极短收束）；日/周 prompt 去教练压迫；无 Key 周问降级模板轻问；旧周报四键废止。
- [2026-07-29 20:35] feat: 周场接通 AI——收周默认 use_llm；生成 overview/pattern/next_focus/note；已收周可「请 AI 再过一遍」；无 Key/失败降级本地拼接。
- [2026-07-29 12:45] feat: 周场最小闭环——`weekly_reviews` 持久化；GET/PUT/POST `/api/weeks/*`；痕迹含「只存未收」日正文；0 天痕迹拒收、≥1 天可收；无 Key 本地拼接；前端提纲保存与收周；pytest 覆盖关键路径。
- [2026-07-29 12:35] fix/ui: 验收修补——本周页去掉对接点/API 字样，提纲可写草稿；今晚自问降为弱链接；设置模板说明与主界面解耦；回看点选后滚到详情。
- [2026-07-29 12:25] style/ui: 按 PRODUCT 落地「枕边薄册」双轨前端——导航今晚/本周/回看/设置；今晚极轻自由书写（无阶段门禁）；本周页七日格+提纲壳+近7日痕迹；复用日场 API，周场 API 未齐处标注对接点。
- [2026-07-29 12:16] docs: 确立「日轻·周重」产品宪法——新增 PRODUCT.md；README 改名为夜记并区分日轨已可用/周轨规划中；开发会话须先读 PRODUCT。
- [2026-07-29 10:25] copy: 前端可见文案从「教练复盘」对齐「夜记」调性——步骤条改为写下今天/问自己一句/收一收；去掉用户可见「教练」「带走复盘」等；业务流程未改。
- [2026-07-29 10:20] fix: 轮播题输入点不中——去掉 translateZ/perspective 击穿点击；仅当前 slide 接收指针，避免叠层与 soft-dim 误伤第 2/4 问。
- [2026-07-29 10:15] style: 视觉重塑方向 A「夜窗稿纸」——夜色侧栏+竖排日期印章、冷灰稿纸主区、楷体书写+淡红横线、去英文 eyebrow/圆角卡片模板；轮播与流程逻辑不变。
- [2026-07-29 09:10] style: 今日四问改为垂直 scroll-snap 轮播——滚轮/触控换题，距离驱动变短缩小，右侧点跳转，吸底操作条；输入区防误触换题。
- [2026-07-29 09:05] style: 今日四问改为单题轮播——当前卡聚焦，写完后上移变短缩小收纳，进度点可跳转；末题主按钮为提交并开始追问。
- [2026-07-29 08:55] style: 教练手账视觉升级——夜读青绿+琥珀追问高光、阶段条、固定题去卡片、追问对话式排版、日历素化与复盘条、三处微动效；侧栏/设置仅换 token。
- [2026-07-29 00:40] feat: 追问式复盘 V2——固定题后 AI 单点追问（最多 2 轮、可跳过），再生成概要/归因/下一步/教训；QA 增加 qa_type/round，Summary 增加新字段与旧库 ensure_schema；prompts 层落地；前端三步流程与重新复盘；测试与 README 同步。
- [2026-07-29 00:10] fix: 修复 code review 缺陷——调度 Provider 失败降级建会话并打日志；同日会话竞态 IntegrityError；SQLite 锚定项目根 + WAL/timeout；前端本地日期、保存失败中止总结、422 错误文案；`.dockerignore`；compose 仅绑 127.0.0.1；LLM 失败返回 502；question_time/Base URL 校验。
- [2026-07-28 23:10] fix: 再次修复设置页问题模板乱码（SQLite 中 `????`），读取时自动从 config.yaml 恢复；日历区分「今天」描边与「已记录」色块+圆点。
- [2026-07-28 00:00] fix: 修复本机设置中被错误代码页写入的中文问题模板；通过 SQLite 与 /api/settings UTF-8 回读验证，保留 V4-Pro 与既有日报。
- [2026-07-28 00:00] chore: 重启本机 FastAPI 服务并验证运行时设置为 DeepSeek V4-Pro，/api/health 返回正常。
- [2026-07-28 00:00] feat: 接入并验证本机 DeepSeek V4-Pro 配置，更新项目默认模型为 deepseek-v4-pro；密钥仅保存于本地 SQLite，未写入源码或日志。
- [2026-07-28 00:00] chore: 在本机 127.0.0.1:8000 启动 FastAPI 服务并通过 /api/health 健康检查；用于本地预览。
- [2026-07-28 00:00] chore: 项目根目录迁移至 D:\\desktop\\app；核对代码与配置均使用相对路径或动态根目录，无需硬编码宿主机路径替换。
- [2026-07-28 00:00] fix: 让演示脚本可按 README 命令直接执行，显式加入项目根目录到模块搜索路径；涉及 scripts/demo_review_flow.py。
- [2026-07-28 00:00] chore: 使用 requirements.txt 安装 SQLAlchemy 2 等依赖，并通过单元测试、演示脚本与 FastAPI API 冒烟检查；涉及 requirements.txt、tests/、scripts/。
- [2026-07-28 00:00] fix: 校准上下文测试断言，使其验证实际注入的历史总结内容；涉及 tests/test_review_service.py。
- [2026-07-28 00:00] docs: 完成 README、MIT 协议、配置示例及 Docker 使用说明，明确本地数据与 LLM 上传边界；涉及 README.md、LICENSE、.env.example、Dockerfile、docker-compose.yml。
- [2026-07-28 00:00] feat: 实现原生本地 Web 界面，含问答、日历回看和设置页；涉及 app/static/。
- [2026-07-28 00:00] feat: 搭建 AI 每日复盘助手核心脚手架，完成 FastAPI、SQLite 模型、可插拔 LLM、调度任务、通知抽象和核心测试；涉及 app/、tests/、scripts/。
- [2026-07-28 00:00] chore: 初始化项目开发日志与进度追踪机制；涉及 CHANGELOG.md、PROGRESS.md、TODO.md。
