# ADR-0417: 跨页历史失败租约释放裁决

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 442 让页面结构操作在 `historyPending` 活跃期间 fail closed，防止跨页
undo/redo 等待目标页时被新增、删除、移动或背景操作重定向。但该租约只在目标页
成功加载并进入 `resumePendingHistory()` 后释放；`switchPageData()` 的 catch
路径可能恢复源页或进入加载失败态，却从未通知父组件清除 `historyPending`。

一旦切页失败，`historyPending` 会保持 true。此后所有 add/delete/move/background
都会被 Phase 442 门禁拒绝，用户即使手动翻页也不会恢复，形成可复现的编辑器锁死。

## 决策

1. `resumePendingHistory()` 在生命周期失效、未加载、加载中、加载失败或历史忙碌
   时清空本地 pending 方向后，必须同步调用 `onPageHistorySettled(false)`，
   释放父组件的跨页导航租约。
2. `switchPageData()` 的 catch 路径在恢复源页或进入失败态后检查
   `pendingHistoryDirection`。若仍有挂起方向，先清空再发布
   `onPageHistorySettled(false)`。
3. 既有成功加载后的自动 resume、删除结构租约、标题保存飞行计数和
   `runPageOperation()` 三重门禁不变。

## 结果

跨页历史的等待租约从“只覆盖成功路径”扩展为“成功、恢复失败、加载失败与销毁
边界都可终止”。切页失败不再把页面操作永久锁死；durable 历史、当前页快照和
Phase 442 结构互斥语义保留。
