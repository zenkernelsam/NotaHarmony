# Phase 1423：Unindexed Notes 管理对话框（l8n.h 复刻）报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 26 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1423-unindexed-notes-dialog.md`
- 决策：`docs/migration/adr/ADR-1359-unindexed-notes-dialog.md`
- Replay：`docs/migration/replays/d02-original-unindexed-notes-dialog.mjs`

## 目标

把原版库主页 "N unindexed note(s)" 横幅的 Learn More 入口从纯
说明弹窗升级为原版的**管理对话框**（`l8n.h`）：可选笔记列表 +
Select All/Deselect All + "N notes selected" + Close/Index Notes
重建动作 —— 补上 Harmony 缺失的 unindexed 恢复通路。

## 原版证据链

- `zsb` 打开条件 `whf.b 非空 && whf.c 空`，行投影 `qcn.c`，
  初始选集 = 全部 id。
- `l8n.h` = `m8n.a` 对话框 + `p6f` case15 内容：
  LazyColumn（粘性头 `aq8.j0`+`ubm.a`=`ig2(4)` 标题+说明）+
  底栏全选切换 + 复数计数 + `g8n.a` 按钮盒。
- `uq5` case8 → `l8n.g` 行：checkmark_circle /
  circle_empty_med_outline + 标题 + `qbn.h` 日期 +
  `select_note` cd，整行 clickable。
- `y73` default：Close + Index Notes（`ubm.b`=`ig2(5)`=
  `feature_library__index_notes`），enabled=选集非空；
  `z73` default：`bz5(selection)`（dsb 重建协程 `psb`）+
  dismiss。

## Harmony 实现

### 数据层（`NoteRepositoryImpl` + `RepositoryInterfaces`）
- `getUnindexedNotes()`：与 `countUnindexedNotes` 同谓词
  （`deleted_at IS NULL AND NOT EXISTS search_item`）的完整
  `NoteMeta` 投影，updated_at DESC。
- `reindexUnindexedNotes(noteIds)`：`databaseWriteMutex` 串行 +
  逐笔记事务——TITLE 项（`upsertTitleSearchItem`）+ 每页
  `page_element_snapshot` payload 经 `searchTextForElement`
  （新导出）解出的 TEXT_BLOCK 项 + `search_page_state.
  indexed_revision`；单笔记失败回滚不影响其余。

### 呈现层（`LibraryViewModel` + `LibraryPage`）
- `unindexedNotes: NoteMeta[]` 与计数同批加载；
  `reindexUnindexedNotes` 走 `enqueueMutation` 并刷新列表/计数。
- `UnindexedNotesDialog` 升级：固定标题+说明头、Scroll 可选行
  （双 glyph + 标题 + updatedAt 日期 + select_note a11y）、
  Select All/Deselect All 文本行、note_selected_singular/
  notes_selected 复数计数、Close + Index Notes
  （默认全选；enabled=选集非空 && !indexing）。
- 新键 `index_notes`（en "Index Notes" / zh "为笔记编制索引"）。

## 忠实边界（fail-closed）

- INK/PDF 搜索项无本地可重放源（识别服务/导入期抽取），重建不
  覆盖 —— 与原版后台索引器的差序已写入 ADR-1359。
- 原版 `vhf` 的 "Indexing N notes"/"All notes indexed" 进度态
  依赖 WorkManager 队列语义，Harmony 同步落库无此状态。

## 验证

- `d02-original-unindexed-notes-dialog.mjs`：26 项全过
  （原版锚点 12 + Harmony 锚点 14）。
- 全量基线、`note@default`、clean `note@ohosTest` 见末节。
