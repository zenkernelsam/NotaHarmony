# Harmony 证据 — 页面操作与页级历史租约边界

- 文件：`note/src/main/ets/ui/editor/NotePage.ets`、
  `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- 现场：Phase 441 后窄审 `historyPending` 只约束 prev/next 导航的缺口。
- 原缺口：跨页 undo/redo 通过 `onRequestPage()` 设置 `historyPending` 并等待目标页加载；
  `runPageOperation()` 当时仅看 `pageOperationBusy`，add/delete/move/background 可同时改写
  结构或选中页。
- 修复链：`runPageOperation()` 在入口同步拒绝 `pageOperationBusy`、`historyPending` 或
  `pageStructureLeaseActive` 活跃的操作。
- 历史链：`onApplyNoteTitleHistory()`、`onApplyNoteMetadataHistory()` 和通用
  `onApplyPageHistory()` 都经新的 `runPageHistoryOperation()` 包装器持有
  `pageOperationBusy`，直到 `applyPageHistory()` 成功或失败返回。
- 相邻裁决：标题与元数据的飞行计数门禁保留；删除期间 `pageStructureLeaseActive`、跨页
  导航请求门禁和 Canvas 成功/失败后的 `historyPending=false` 释放点不变。
- 结论：页级历史与页面结构操作共享同一互斥所有权；挂起命令不会被结构操作重定向，也不会
  在持久化应用期间让新结构操作插入。
