# Harmony 证据 — 录音会话收口所有权边界

- 文件：`note/src/main/ets/ui/editor/NotePage.ets`、
  `note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets`
- 现场状态：Phase 440 后窄审录音会话退出收口，重点比较 `finishRecordingSession()`、
  `performLeaveEditor()` 与 `aboutToDisappear()` 的所有权。
- 页面链：`finishRecordingSession()` 先捕获当前会话，再同步置空页面指针并取消刷新定时器；
  第二次进入只能看到 `null` 并返回成功。释放失败继续输出警告并返回 `false`。
- 离开链：`performLeaveEditor()` 在标题/历史/工具状态和删除队列冲刷后检查销毁态，随后等待
  会话收口，再释放播放器并导航返回。`editorLeavePromise` 继续阻止重复离开流程。
- 销毁链：`aboutToDisappear()` 先置位 `editorDisposed`、递增代际并取消定时器；fire-and-forget
  收口只负责资源终态。迟到快照与定时器回调受销毁门禁或空指针拒绝。
- 控制器链：start/pause/resume/stop/interrupted-stop/finish 全部经 `AsyncMutex` 排队；
  `finishAndRelease()` 在互斥区内保存活动采集、解除监听、释放采集并发布终态，然后清除 listener。
  `released` 是终态门禁，后续控制不会再次触碰采集。
- 相邻裁决：对话框后的麦克风或内录入口都重新检查 `editorDisposed`；即使会话在对话框期间被销毁
  收口，控制器 `released` 门禁也会使后续 `start()` fail closed。
- 结论：无新生产缺陷，不引入代码改动；新增专项 Replay 锁定当前三层所有权语义。
