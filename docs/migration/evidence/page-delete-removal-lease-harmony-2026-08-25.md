# Phase 424 页面删除移除租约 Harmony 证据（2026-08-25）

## 源码顺序

- `note/src/main/ets/ui/editor/NotePage.ets:1279`：`deleteCurrentPage()` 预检后进入租约包裹的
  `deleteCurrentPageLocked()`。
- 同函数内：先 await `historyBridge.flushCurrentPage()`，再校验当前页身份、捕获快照、
  prepare history、调用 `preparePageRemoval(pageId)`，最后等待 `deletePageWithCheckpoint()`。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets:438`：`preparePageRemoval()` 设置
  `skipSavePageId` 并对当前页开启 loading；但没有任何全局互斥阻止页面导航或历史命令。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets:2650`：Undo/Redo 只检查自身
  `historyBusy` 与 pending 方向，因此可在页面删除事务中再次进入 `applyPageHistory()`。

## 缺口

页面导航只检查 `pageLoading/pageOperationBusy/historyPending`；这些状态都不能表达
“当前页删除已在移除保护态中”。同样，工具栏 Undo/Redo 信号也没有移除租约门禁。

## 断言

- `docs/migration/replays/d02-page-delete-removal-lease-bound.mjs`：
  - 租约字段存在，且只在删除 wrapper finally 中释放一次。
  - 快照、`preparePageRemoval`、durable delete 和失败取消保持原顺序。
  - 上一页/下一页必须包含 `!pageRemovalLeaseActive`。
  - Undo/Redo 派发必须在租约活跃时被阻断。
- 全量 Desktop Replay 与双 HAP 构建通过后补录统计。
