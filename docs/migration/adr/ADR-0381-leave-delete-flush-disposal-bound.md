# ADR-0381：离开删除清理销毁绑定

- 状态：已接受（2026-08-25）
- 场景：`performLeaveEditor()` 在画布 flush 销毁检查后继续等待 `recordingDeleteController.flush()`。该 await 期间发生 dispose 时，迟到续体仍会终止录音会话并释放播放控制器，与组件销毁路径并发执行同类清理。
- 决策：删除队列 flush 返回后增加销毁复查；已销毁则停止会话结束和播放器永久释放，交由 `aboutToDisappear()` 已启动的异步兜底处理。
- 结果：避免迟到离开续体与销毁兜底重复释放共享录音资源；正常离开顺序和画布 flush 门禁保持不变。
