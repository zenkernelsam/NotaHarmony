# ADR-0402：页面结构事务互斥租约

## 状态

已接受（2026-08-25，Phase 430）。

## 背景

Phase 424 为当前页删除引入 `pageRemovalLeaseActive`，但该租约只覆盖删除。新增、移动和
背景设置仍由 `pageOperationBusy` 只串行化 NotePage 自身入口；工具栏 Undo/Redo 不检查该状态，
画布跨页历史也可通过 `onRequestPage()` 改写选中页。因此 durable 页面操作与页面级历史命令
仍可能并发改写页列表、选中页或同一 SQLite 记录。

## 决策

1. 将 Phase 424 租约泛化为 `pageStructureLeaseActive`，继续由删除 wrapper 预检后占用并在 finally 统一释放。
2. 删除期间保留导航、历史请求和离开/标题提交阻断；Undo/Redo 改由 `pageOperationBusy` 串行化。
3. 页面增删移动与背景设置继续使用 `pageOperationBusy`；其进行中同时拒绝历史请求改写选中页，
   但保留 Undo/Redo 的非页面元素命令，不扩大到整个编辑器。
4. 不把租约发布为 UI state；失败、stale 和 disposed 仍由既有 owning wrapper 清理。

## 后果

删除拥有更强的结构互斥；其他 durable 页面操作至少阻止历史跨页改选，避免把历史 pending 指向
正在变化的事务。后续若需要完全统一所有页面级历史与结构操作，应在同一租约边界内扩展，
而不是重新分散布尔判断。
