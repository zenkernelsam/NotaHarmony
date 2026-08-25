# Harmony 证据 — Undo/Redo 挂起跨页历史门禁缺口

- 跨页历史协议：
  - `NoteCanvasView.performHistory()` 对非当前页 action 设置
    `pendingHistoryDirection`，调用 `onPageHistorySettled(true)` 后请求切页；
  - 父页 `onRequestPage` 设置 `currentPageIndex` 并置 `historyPending=true`；
  - 目标页加载成功后 `resumePendingHistory()` 清方向、发布 settled=false 并执行历史。
- 缺陷时序：上述挂起窗口中，父页工具栏 `onUndo/onRedo` 原来只检查
  `pageOperationBusy`。第二次 Undo/Redo 信号可进入 Canvas；`performHistory()`
  不检查父页 `historyPending`，因此新历史命令可能与挂起方向竞争。
- 影响边界：页面结构操作已被 Phase 442 门禁阻止；照片导入已被 Phase 447 租约阻止；
  本缺口集中在工具栏 undo/redo 触发器本身。
- 修复事实：`onUndo` 与 `onRedo` 改为同时要求 `!historyPending && !pageOperationBusy`
  才递增信号。Canvas 内部防御不变，避免重复信任单一状态源。
- 验证：扩展 `d02-page-history-command-lease-bound.mjs` 锁定两个回调中的
  historyPending 门禁和信号前最近守卫；当前输出 `TOTAL=9 FAILED=0`。
