# ADR-0432: 撤销重做工具栏纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 459 后继续盘点照片导入共享租约的副作用入口，发现工具栏撤销/重做回调只拒绝
页面操作和历史待定状态。照片导入异步持久化释放内部 `historyBusy` 后、外层 `finally`
清除 `photoImportBusy` 前，用户仍可触发撤销或重做。该路径会取消既有裁剪会话，检查
元素或跨页历史并推进撤销栈；跨页分支还会请求切页，可与照片收口竞争。

## 决策

`NotePage` 的 `onUndo()` 与 `onRedo()` 在发信号前先拒绝 `photoImportLeaseActive`，
保留页面操作和历史待定门禁。Canvas `performHistory()` 在内部 `historyBusy` 前拒绝
`photoImportBusy`，作为第二层防御。不改变历史分组、跨页恢复、裁剪取消或持久化语义。

## 结果

照片导入收口前不能通过撤销/重做改写元素、页序或切换页面；导入完成后工具栏恢复。
焦点 Replay 锁定两个父页回调、Canvas 统一历史入口的守卫顺序及副作用路径。未启动
模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
