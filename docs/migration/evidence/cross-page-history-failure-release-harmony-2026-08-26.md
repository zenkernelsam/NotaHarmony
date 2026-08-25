# Harmony 证据 — 跨页历史失败租约释放

- 文件：`note/src/main/ets/ui/editor/NoteCanvasView.ets`、
  `note/src/main/ets/ui/editor/NotePage.ets`
- 原缺口：Phase 442 后跨页 undo/redo 通过 `onRequestPage()` 设置
  `NotePage.historyPending = true`。只有 `switchPageData()` 成功加载目标页并调用
  `resumePendingHistory()` 才会发布 settled=false；catch 恢复源页或进入加载失败态
  时没有对应释放。
- 失败链：切页失败 → 源页快照恢复或 `enterLoadFailureState()` →
  `historyPending` 保持 true → `runPageOperation()` 被 Phase 442 三重门禁永久
  拒绝 → 新增/删除/移动/背景全部不可用。
- 修复：`resumePendingHistory()` 的异常退出分支在清空 pending 方向后立即调用
  `onPageHistorySettled(false)`；`switchPageData()` 的 catch 在错误投影后检查并
  清理挂起方向，同样发布 settled=false。
- 相邻边界：成功路径仍会继续执行挂起命令；删除期间的 `pageStructureLeaseActive`
  标题保存飞行计数、页面操作互斥和历史回调路由不变。
- 结论：静态回放与 ArkTS fixture 锁定失败释放契约；真实设备切页中断矩阵仍开放。
