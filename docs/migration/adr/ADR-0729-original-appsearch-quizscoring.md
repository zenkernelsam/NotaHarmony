# ADR-0729 — 原版 1.4.2 AppSearch 引擎与 QuizSession 计分列登记

日期：2026-09-29
状态：已登记（平台边界 + 版本差；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-785-original-appsearch-quizscoring.md`
Replay：`docs/migration/replays/d02-original-appsearch-quizscoring.mjs`
上游：ADR-0711、ADR-0721

## 背景

1.4.2 在 Room 引擎旁新增 Jetpack AppSearch 引擎
（`SearchResult` `@Document`：id/text/score/namespace/pageId），
配合 SearchIndex 上传队列为本地+服务端双层检索；
QuizSession/CompletedQuizSession 均增四计分列。

## 决策

1. **AppSearch**：Android 专属库——平台边界登记；端内检索
   已由 Room-FTS 移植满足，无回移需求。
2. **计分列**：随 Learn 测验族边界登记。
3. 更正：NoteStateEntity 的 zoom*/lastCodeBlockLanguage 系
   1.0.3 存量，非 1.4.2 新增；isTextOnly 仍为唯一真增量。

## 后果

- 搜索架构双层化证据入 T-042；共享库列差至此穷尽。
