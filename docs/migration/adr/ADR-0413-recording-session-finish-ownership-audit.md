# ADR-0413: 录音会话收口所有权审计裁决

日期：2026-08-25

## 状态

Accepted

## 背景

Phase 440 后继续窄审编辑页退出时的录音会话生命周期。需要证明同一会话不会被重复
`finishAndRelease()`，排队中的控制或中断停止也不能在释放后触碰采集；同时确认释放失败的
可见性与对话框期间销毁的启动入口安全。

## 决策

1. 页面侧 `finishRecordingSession()` 采用捕获-清空所有权：同一页面实例第二次调用只能看到
   `null`，立即返回成功；刷新定时器在等待控制器释放前取消。
2. 控制器所有异步控制与终态释放继续通过单一 `AsyncMutex` 排队。`finishAndRelease()` 在互斥区
   内先保存活动采集，再解除焦点、监听器并释放采集；最后发布快照并清除 listener。
3. `released` 是不可逆终态门禁：后续 start/pause/resume/stop 或排队的 interrupted-stop 只能
   fail closed，不会重新打开或再次释放底层采集。
4. `aboutToDisappear()` 保持同步销毁标记、代际推进、定时器取消和 fire-and-forget 收口；
   `performLeaveEditor()` 保持删除冲刷后的销毁检查，并在导航前显式等待会话收口与播放器释放。
5. 音频源对话框后的两个启动分支必须重新检查 `editorDisposed()`；若销毁流程已在对话框期间完成，
   控制器终态门禁提供第二道防线。

## 结果

未发现新的生产缺陷；Phase 441 以文档、中文证据与专项 Replay 固化现有架构，不改写生产代码。
