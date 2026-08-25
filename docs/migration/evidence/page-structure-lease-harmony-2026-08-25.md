# Phase 430 页面结构事务互斥租约 Harmony 证据（2026-08-25）

## 源码顺序

- `NotePage.ets`：`deleteCurrentPage()` 预检通过后设置 `pageStructureLeaseActive`，
  包裹整个 `deleteCurrentPageLocked()`，finally 统一释放。
- `performLeaveEditor()`、`commitTitle()` 在结构租约活跃时保持阻断。
- 上一页/下一页继续要求 `!pageLoading && !pageOperationBusy && !historyPending &&
  !pageStructureLeaseActive`。
- `onRequestPage()` 现在在 `pageOperationBusy || pageStructureLeaseActive` 时直接返回；
  不改写选中页，也不设置历史 pending。
- 工具栏 Undo/Redo 改为检查 `!pageOperationBusy`：增删移动与背景事务期间拒绝派发；
  删除租约中因删除本身位于同一 busy wrapper 内也自然拒绝。

## 缺口

Phase 424 的删除专用租约不能表达“其他页面结构操作进行中”。新增、移动和背景设置等待
durable SQLite 结果时，画布跨页历史仍可调用 `onRequestPage()` 改写选中页并挂起历史方向；
工具栏 Undo/Redo 也未检查 `pageOperationBusy`。

## 断言

- 新增专项 Replay `d02-page-structure-lease-bound.mjs`（9/9）：字段迁移、删除 wrapper
  一次释放、removal prepare/delete/cancel 顺序、双导航门禁、Undo/Redo busy 门禁和历史请求门禁。
- 加强既有 `d02-page-delete-removal-lease-bound.mjs` 为新租约语义，仍为 9/9。

## 边界

本阶段不启动模拟器、虚拟机、真机或 Hypium；T-042 继续 Goal 最后任务。
