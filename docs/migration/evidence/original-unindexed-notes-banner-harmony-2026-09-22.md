# Phase 551 — 原版库“未索引笔记”横幅与说明对话框（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/data/RepositoryInterfaces.ets`、
`NoteRepositoryImpl.ets`、`LibraryViewModel.ets`、`LibraryPage.ets`、
双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

- `flc.java` = `SearchIndexingState(indexingNotes=a, queuedNotes=b,
  neverIndexedNotes=c)`；`c()` = 三集合大小之和（待索引总数）。
- `elc.a`（索引状态横幅）：
  - `c() == 0` → `all_notes_indexed`（"All notes indexed"）。
  - 索引进行中（`gl8` = `a` 非空）→ `indexing_notes` 复数
    "Indexing %d notes" + 进度指示。
  - 否则（有 queued/neverIndexed、无进行中）→ `unindexed_note`
    复数 "%d Unindexed Note(s)"；`b`/`c` 非空时追加 `learn_more`
    （"Learn More"）链接。
- `n32.java`：Learn-more 对话框 = `unindexed_notes` 标题 +
  "If the note causes the app to crash, it will be unindexed.
  Unindexed notes will not appear in search." + Close；
  `index_notes` 为承载表单的标题。
- `yj9.java`/`hof.java`：原版承载面是多选工具栏内的 "Index Notes"
  底部表单（列出 unindexed 笔记行）。
- `vmc.java`：原版后台索引器会 "Re-enqueue stranded unindexed
  notes"——queued/indexing 为异步流水线状态。

## Harmony 落地

- `NoteRepository.countUnindexedNotes()`：`deleted_at IS NULL` 且
  `NOT EXISTS (search_item)` 的笔记数——每条走正常保存路径的笔记
  都会得到 TITLE 型 search_item 行，零行即"从未索引"，与原版
  `neverIndexedNotes` 语义一致。
- `LibraryViewModel.unindexedNoteCount` 在 `loadNotes` 守卫尾部刷新
  （generation 校验后写入；查询失败保持原值）。
- `LibraryPage` 在笔记列表上方渲染横幅：`%d Unindexed Note(s)` +
  `Learn More`；点击打开 `UnindexedNotesDialog`（`unindexed_notes`
  标题 + 崩溃说明正文 + `close`）。

## 差异登记

- 原版承载于多选工具栏内的 "Index Notes" 底部表单（含 unindexed
  笔记列表）；Harmony 库无多选模型，横幅直接呈现在列表上方，
  说明对话框保留原版标题/正文/关闭按钮。
- 原版 `indexingNotes`/`queuedNotes` 异步流水线状态在 Harmony 不
  存在（同步索引）；"All notes indexed" 与 "Indexing %d notes"
  分支登记为不移植——横幅仅在存在未索引笔记时出现。
