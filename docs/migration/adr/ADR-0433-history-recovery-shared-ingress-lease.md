# ADR-0433: 历史恢复重置纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 460 后继续盘点共享照片导入租约，发现历史损坏恢复对话框的“重置 Undo 历史”
入口只检查生命周期、恢复需求、恢复忙、内部历史忙和数据库状态。照片导入异步持久化
释放 `historyBusy` 后、外层 `finally` 清除 `photoImportBusy` 前，用户可确认重置。
该路径会设置双重忙碌状态、清空内存 Undo/Redo 并执行持久历史重置事务，与照片收口竞争。

## 决策

`requestPersistentHistoryReset()` 和 `resetPersistentHistory()` 都在内部
`historyBusy` 前拒绝 `photoImportBusy`。对话框仍只能通过带门禁的 request 入口调用；
恢复提示、失败保留、生命周期绑定和 finally 释放不变。新增 Hypium fixture 以模型层
锁定同一互斥语义。

## 结果

照片导入收口前不能清空或重置撤销历史；导入完成后用户可重新确认重置。焦点 Replay
锁定两个入口的守卫顺序和 fixture 行为。未启动模拟器、虚拟机、真机或 Hypium；
T-042 保持 Goal 最后任务。
