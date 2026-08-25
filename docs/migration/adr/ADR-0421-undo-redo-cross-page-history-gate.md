# ADR-0421: 工具栏 Undo/Redo 等待跨页历史命令收口

日期：2026-08-26

## 状态

Accepted

## 背景

跨页 undo/redo 先设置 `pendingHistoryDirection` 并把父页 `historyPending` 置真，
再通过切页加载目标页，最后在 `resumePendingHistory()` 中执行历史。父级工具栏的
Undo/Redo 回调原来只检查 `pageOperationBusy`，不检查 `historyPending`；因此挂起
命令尚未 resume 时再次点击 Undo 或 Redo 会向 Canvas 发送新信号。

`performHistory()` 只拒绝 `historyBusy` 和本组件内已有 pending 方向，无法感知父级
`historyPending` 已被外部切页请求置真。迟到信号可能改变内存 undo/redo 游标或触发
另一条历史路径，破坏“一次跨页历史命令必须完整收口”的串行化假设。

## 决策

工具栏 Undo 与 Redo 在发信号前同时检查 `historyPending` 和 `pageOperationBusy`。
挂起的跨页历史命令完成并发布 settled=false 后，工具栏才允许派发下一个撤销/重做
信号。Canvas 内部既有 `historyBusy`、pending direction 和 stale-context 防御保留，
作为第二层兜底。

## 结果

同一时刻最多只有一条用户触发的跨页历史命令处于挂起状态；迟到的工具栏信号不再能
绕过父级导航租约。专项 Replay 扩展锁定两个回调门禁与信号位置，原有恢复失败释放
语义不变。
