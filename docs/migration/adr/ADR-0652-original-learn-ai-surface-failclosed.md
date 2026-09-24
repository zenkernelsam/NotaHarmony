# ADR-0652 「Learn / AI 学习面」fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：703
- 接续：ADR-0651（YouTube 转录导入 fail-closed）、ADR-0626（Add GIF/
  Klipy fail-closed）、ADR-0644（POINTER/ZOOM/view-only 旗标域
  fail-closed）
- 证据：`docs/migration/evidence/original-learn-ai-surface-jadx-2026-09-24.md`

## 背景

原版 1.0.3 包含一整组 `feature_learn*` AI 学习面（字符串约 126
条：learn 17 + quiz 50 + summary 17 + transcription 15 +
ui_learn 27），覆盖四个子面：

1. **录音转录**（`feature_learn_transcription__*`）——"Transcripts"
   面板：Listening/Transcribing/Loading 状态、quota 提示
   （"Upgrade to transcribe older recordings"、too long/too short）、
   搜索转录文本。由 `ac4.u0`（SHOW_TRANSCRIPTS，36）/
   `ac4.v0`（LIVE_TRANSCRIPTION，37）门控（`x90:10475` 转录
   条目渲染处显式检查 `lc4.a(ac4.u0)`）。
2. **Smart Notes / 摘要**（`feature_learn_summary__*`）——AI
   从转录生成笔记（"AI Generating…/Analyzing Transcripts…"），
   由 `ac4.z0`（SMART_NOTES，41）+ `ac4.x0`（LEARN_SUMMARY，39）
   门控（`a99.java`：`z0 && x0 → w77 : k87`）。
3. **测验/记忆卡**（`feature_learn_quiz__*`）——四种学习模式
   Memorize/Practice/Test/MixAndMatchDevOnly（`w57.java`），
   QuizQuestion/Flashcard 序列化器（`z9b`/`s9b`/`o9b`/`lab`/`mab`/
   `lk`），由 `ac4.A0`（LEARN_QUIZZES，42）/`ac4.B0`
   （LEARN_FLASHCARD_RATING，43）门控（`hb7`/`lv4`/`n3`/`np0`）。
4. **聊天**（`feature_learn__chat_*`）——随问随答 UI（`t7`/`r22`
   输入框+发送按钮），由 `ac4.D0`（LEARN_CHAT，45）门控。

附加门控：`ac4.E0`（AI_REGION_ALLOWED，46，`ph.java` 地区
门）、`ac4.y0`（LEARN_LATEX，40）、`ac4.C0`（LEARN_OFFLINE，44）。

**后端依赖**：`com.gingerlabs.notability.data.learn` 包内
`b.java` 直接处理 `ApolloException`/`ApolloHttpException`/
`ApolloNetworkException`；`LearnError` 错误域含 `LLMBadResponse`/
`QuotaLimit`/`Subscription`/`AiDisabled`/`BatchNotFound`/
`JobFailed`/`Timeout`/`LearnRequestError`——整条 Learn 链路依赖
原版**私有 GraphQL LLM 后端** + 订阅/配额体系，与 ADR-0651
YouTube 转录同一结构类别。另有本地 `LearnDatabase`（Room）做
缓存，但缓存数据由后端生成。

## 决定

1. **不实现 Learn/AI 学习面**，登记结构性 fail-closed：核心能力
   （转录、Smart Notes、测验生成、聊天）全部依赖原版私有 LLM
   后端与订阅配额体系，无等价 Harmony 服务面。
2. **Harmony 不渲染任何 Learn 入口**：转录面板、Smart Notes、
   测验/记忆卡、聊天等价于旗标关闭态——与原版旗标评估为 false
   时的行为一致。
3. **录音管线不受影响**：录制/播放/导入导出等本地能力已完整
   移植（Phase 702 矩阵收口）；Learn 转录是叠加在录音之上的
   AI 层，缺失不改变录音本地语义。
4. **订阅/配额错误域（Subscription/QuotaLimit）属于已登记的
   paywall 边界之外**：本项目为单机笔记应用，不实现订阅体系。

## 后果

- 原版旗标域全部评估为 false 时的体验即 Harmony 当前体验；
  文档化差异而非缺陷。
- 若将来 Harmony 侧获得等价 LLM 服务面，本 ADR 可按旗标域逐项
  重开（转录/Smart Notes/测验/聊天相互独立门控）。
