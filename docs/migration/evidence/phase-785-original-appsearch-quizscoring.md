# Phase 785 证据：原版 1.4.2 AppSearch 引擎差 + QuizSession 计分列

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2`（`data/search/engine/appsearch/`、
`defpackage` ALTER 迁移）；`decompiled_1.0.3` 对照。
Replay：`docs/migration/replays/d02-original-appsearch-quizscoring.mjs`
ADR：`ADR-0729-original-appsearch-quizscoring.md`

## 1. 搜索引擎架构差

- 1.0.3：`data/search/engine/` 仅 `room/`——Room FTS 单引擎。
- 1.4.2：同目录增 `appsearch/`——Jetpack AppSearch 并列，
  `SearchResult` 为 `@Document` 文档类：
  `SearchResult(id, text, score, namespace, pageId)`。
- 与 Phase 777 的 `SearchIndex{PendingUpload,SyncState}` 合观：
  本地 AppSearch 索引 + 服务端索引上传队列的双层架构。

## 2. QuizSession 计分列（既有表增量）

`ALTER TABLE QuizSession ADD COLUMN` 四条新增：
`numCorrect`/`numIncorrect`/`numSkipped`/`spacedRepetitionTotal`——
进行中会话也带计分（与 Phase 777 CompletedQuizSession 档案配对）。

## 3. 更正登记

- `NoteStateEntity.lastCodeBlockLanguage`/`zoomViewShown`/
  `zoomViewSourceRect` 在 **1.0.3 已存在**（ba8 迁移 + e47 DDL），
  非 1.4.2 新增——排除 Phase 767 列清单的潜在误读。
- NoteStateEntity 真增量仅 `isTextOnly`（Phase 773 已登记）。

## 4. Harmony 现状

- 搜索实现 = `search_item` Room-FTS 移植（1.0.3 对齐）；
  无 AppSearch 等价物需求（HarmonyOS 无 AppSearch API，
  本地检索面已满足）。

## 5. 分类结论

- AppSearch 引擎：Android 专属库选型——登记为**平台边界**
  （端内能力已由 Room-FTS 移植覆盖，无需回移）。
- QuizSession 计分列：随 Learn 边界族登记。
- 服务端索引上传：fail-closed（Phase 777 已登记）。
