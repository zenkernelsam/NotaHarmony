# ADR-0401：当前页删除期间的移除租约

## 状态

已接受（2026-08-25，Phase 424；Phase 425 补全历史请求入口）。

## 背景

`deleteCurrentPage()` 先捕获页身份，再等待 flush，随后进入快照与持久化删除。
`preparePageRemoval()` 只在删除事务前把该页设为跳过保存并显示加载态；它不能阻止页面导航，
也不能阻止撤销/重做在该窗口内启动另一个页面级事务。

若用户在 flush 等待期间点击上一页/下一页，旧删除流程会继续删除用户刚选中的目标页；
若撤销或重做在 `deletePageWithCheckpoint()` 期间执行，两个页面级 SQLite 事务可并发竞争。
`pageOperationBusy` 只串行化同一 NotePage 的增删移动入口，无法约束画布发起的历史命令。

## 决策

1. 删除当前页使用独立的 `pageRemovalLeaseActive` 租约，从预检通过后占用，到整个流程结束 finally 释放。
2. 租约活跃时拒绝上一页、下一页、Undo/Redo 信号派发，以及画布 `onRequestPage()` 的选中页改写；
   不改变新增、移动和背景设置的既有 busy 语义。
3. 删除成功、失败、stale 或 disposed 都由 owning wrapper 统一释放租约。
4. 不把租约发布为 UI state，避免引入不必要的组件重建。

## 后果

`preparePageRemoval()` 的保护态不再被并发导航绕过；删除事务期间也不会启动第二个页面级历史命令。
后续若需要更细粒度的页面结构互斥，应扩展同一租约边界，而不是重新依赖分散的布尔检查。
