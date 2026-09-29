# ADR-0959 — 测验/学习子系统

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `QuizSession` PK(noteId,mode)：进度+恢复+
  questions JSON。
- `QuizOp`：ABORT 账本，三答题列（MC/填空/卡片
  评级）+ sessionId/questionIndex/status。
- `SummaryEntity`：AI markdown 摘要。
- `LearnJob`：batchId+asrHashes 幂等（服务端 ASR）。
- `StudyItemsInfo`：内容度量+audioHashes。

## Harmony 决策

表平移；AI 生成/ASR 后端 fail-closed；JSON 文本列
保留。

## Parity 状态

存储等价；AI 功能不可用。

## 验证

- `d02-quiz-learn.mjs`：11/11 通过。
