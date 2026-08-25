# Harmony 证据 — 跨页历史失败后的选页恢复顺序

- 缺陷协议：
  - 跨页 Undo/Redo 设置方向并由父页 `onRequestPage` 置 `historyPending=true`；
  - 目标页加载失败进入 `switchPageData()` catch；
  - Canvas 还原源页快照并把 `loadedPageId` 改回源页；
  - 原 `onRequestPage(fromPageId)` 先发出，父页因 `historyPending` 仍为真拒绝；
  - 随后才执行 `onPageHistorySettled(false)`。
- 影响：父级 `currentPageIndex` 停留在失败目标页，而画布内存与 `loadedPageId`
  已回到源页；后续交互可能对错误页上下文取值或写入。
- 修复事实：仅当需要向父页请求恢复源页时，先清 `pendingHistoryDirection` 并发布
  settled=false，再发恢复请求；catch 末尾残留方向守卫保持不变。
- 边界：成功 resume 仍按原顺序读取方向、释放租约再 `performHistory()`；加载终态
  失败继续走异常释放；无新增共享状态或回调绕行。
- 验证：`d02-pending-history-resume-context-bound.mjs` 扩展锁定三步顺序和末尾
  守卫位置；当前输出 `TOTAL=6 FAILED=0`。
