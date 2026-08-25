# Harmony 证据 — 文本取消绕过照片导入租约缺口

- 缺陷时序：
  - 用户先通过 DEFAULT 工具新建空文本块；
  - 照片导入持有父级与 Canvas 共享租约；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - `onTextCancel()` 原只检查 `historyBusy`，可删除该文本块并同步 `elementOrder`；
  - 取消还会调用 `persist()`，与随后照片插入的元素数组/顺序合并竞争。
- 影响边界：Phase 456 已阻止提交；本缺口集中在同一既有会话的取消分支，尤其是放弃新建
  空文本时的文档删除副作用。
- 修复事实：取消入口在 `historyBusy` 前检查 `photoImportBusy` 并保留会话；不新增状态字段，
  不改变空新建撤销语义或原始墨迹预约刷新。
- 验证：新增 `d02-text-cancel-shared-lease-bound.mjs` 锁定守卫存在、顺序及删除/持久化副作用；
  当前输出 `TOTAL=7 FAILED=0`。
