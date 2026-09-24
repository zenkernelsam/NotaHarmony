# Phase 703：原版 Learn / AI 学习面 fail-closed 登记

继续 feature_ 家族扫描：`feature_learn*`（约 126 条字符串）为原版
1.0.3 的 AI 学习面，之前未登记。本轮完成 JADX 证据固化并登记
结构性 fail-closed（ADR-0652）。

## 原版面

- **录音转录**（`feature_learn_transcription__*`，15 条）：
  Transcripts 面板 + Listening/Transcribing 状态 + quota 提示，
  `ac4.u0`/`v0` 门控（`x90:10475` 显式 `lc4.a(ac4.u0)`）。
- **Smart Notes/摘要**（`feature_learn_summary__*`，17 条）：
  AI 从转录生成笔记，`ac4.z0`+`x0` 门控（`a99` 变体选择）。
- **测验/记忆卡**（`feature_learn_quiz__*`，50 条）：
  Memorize/Practice/Test/MixAndMatchDevOnly 四模式（`w57`），
  `ac4.A0`/`B0` 门控。
- **聊天**（`feature_learn__chat_*`）：随问随答 UI（`t7`/`r22`），
  `ac4.D0` 门控。
- 附加门控：`ac4.E0` AI_REGION_ALLOWED、`y0` LEARN_LATEX、
  `C0` LEARN_OFFLINE。

## fail-closed 理由

- `com.gingerlabs.notability.data.learn.b` 直接处理 Apollo
  GraphQL 异常——私有后端；
- `LearnError` 错误域含 LLMBadResponse/QuotaLimit/Subscription/
  AiDisabled——LLM + 订阅 + 配额 + AI 开关四重外部依赖；
- `LearnDatabase` 仅为本地缓存，内容由后端生成；
- Harmony 侧 grep 零 Learn 实现，等价旗标关闭态；
- 录音本地管线（Phase 702 收口）不受影响——Learn 转录是叠加
  AI 层。

## 产物

- `docs/migration/adr/ADR-0652-original-learn-ai-surface-failclosed.md`
- `docs/migration/evidence/original-learn-ai-surface-jadx-2026-09-24.md`
- `docs/migration/replays/d05-original-learn-ai-surface-fail-closed.mjs`
  （14 断言：字符串面/旗标域/Apollo+错误域证据/Harmony 零实现）

## 验证

- 专项 14/14；全套件重跑通过后记录于修复总纲；双 HAP 0 错误。
