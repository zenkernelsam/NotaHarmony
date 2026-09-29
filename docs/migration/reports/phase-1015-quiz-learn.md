# Phase 1015 报告 — 测验/学习子系统

## 范围

QuizSession/QuizOp/SummaryEntity/LearnJob/
StudyItemsInfo 五表 + 写形。纯审计。

## 原版发现

- `QuizSession` PK(noteId,mode)，questions TEXT JSON
  + 进度/恢复列。
- `QuizOp` ABORT 账本：三答题列 + 会话/题序/状态。
- `SummaryEntity` markdown 摘要；`LearnJob` ASR
  幂等哈希；`StudyItemsInfo` 度量。

## Harmony 决策

存储等价；AI/ASR fail-closed。

## 产出

- 证据：`phase-1015-quiz-learn.md`
- Fixture：`d02-quiz-learn.mjs`（11/11）
- ADR-0959；全量 Replay 见本提交。
