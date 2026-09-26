# Phase 785 — 原版 1.4.2 AppSearch 引擎与计分列登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-785-original-appsearch-quizscoring.md`
ADR：`ADR-0729-original-appsearch-quizscoring.md`
Replay：`d02-original-appsearch-quizscoring.mjs`（6/6）

## 本阶段做了什么

登记 `data/search/engine/appsearch` 新引擎包与 QuizSession
既有表的四计分列增量；穷尽共享库列级差。

## 发现

- 1.4.2 搜索 = Room FTS + Jetpack AppSearch 双引擎；
  SearchResult @Document(id/text/score/namespace/pageId)。
- QuizSession +numCorrect/numIncorrect/numSkipped/
  spacedRepetitionTotal（进行中会话也计分）；
  CompletedQuizSession 同增三列。
- 更正：zoomView*/lastCodeBlockLanguage 为 1.0.3 存量；
  NoteStateEntity 真增量仅 isTextOnly。
- Harmony search_item Room-FTS 移植已覆盖端内检索。

## 分类

- AppSearch：Android 平台边界；无回移需求。
- 计分列：Learn 边界族随登。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
