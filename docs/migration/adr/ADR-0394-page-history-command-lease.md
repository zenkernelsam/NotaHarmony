# ADR-0394：跨页历史命令租约

- 状态：已接受（2026-08-25）
- 场景：跨页 undo/redo 会保存 pending 方向并请求目标页；加载完成前，底部上一页/下一页只检查
  `pageLoading` 和 `pageOperationBusy`，可再次改页并启动新页面加载。旧 pending 方向随后可能在非目标页恢复，
  或因健康门禁被静默消费。
- 决策：把 `pendingHistoryDirection` 视为跨页历史命令租约。Canvas 在设置方向并发出 `onRequestPage` 前先通知
  NotePage 持有租约；`resumePendingHistory()` 消费方向后立即释放。NotePage 的上一页/下一页回调在
  loading、operation busy 之外增加 history-pending 门禁。
- 结果：跨页命令独占翻页入口直到目标数据就绪；正常自动恢复不变，失败和销毁仍由既有 Phase 402 健康门禁
  fail closed。原版 1.0.3 的文本 undo 队列同样要求队列空闲才执行 rollback（`dd8.a()`），
  本修复使导航与该原子语义一致。
