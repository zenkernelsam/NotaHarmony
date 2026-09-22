# ADR-0523 — 原版库未索引笔记横幅与说明对话框

状态：Accepted（Phase 551）

## 背景

原版 `flc` SearchIndexingState 驱动 `elc.a` 索引状态横幅与 `n32`
Learn-more 说明对话框；未索引笔记不进入搜索（`EXISTS search_item`
语义在两端一致）。Harmony 已有 `search_item` 维护与 EXISTS 过滤，
但无任何"未索引"用户可见表面。

## 决策

1. `countUnindexedNotes()`：`deleted_at IS NULL` 且 `NOT EXISTS
   (search_item)` —— 正常保存路径必写 TITLE 型行，零行即
   neverIndexed。
2. `unindexedNoteCount` 在 `loadNotes` 尾部随列表刷新。
3. 横幅仅在计数 > 0 时出现：`%d Unindexed Note(s)`（单/复数双
   字符串变体，SDK 无同步 plural API）+ Learn More 链接。
4. Learn-more 对话框按 `n32` 还原：`unindexed_notes` 标题 + 崩溃
   说明正文 + Close。

## 差异

- 原版承载于多选 "Index Notes" 底部表单（含笔记列表）；Harmony
  无多选模型，横幅置于列表上方（登记适配）。
- 原版 indexing/queued/进度态与 "All notes indexed" 分支不移植
  （同步索引无异步流水线）。

## 验证

`d02-original-unindexed-notes-banner.mjs` 22/22；全套 replay 通过；
`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
