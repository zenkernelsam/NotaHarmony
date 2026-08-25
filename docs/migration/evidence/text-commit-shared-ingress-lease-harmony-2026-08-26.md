# Harmony 证据 — 文本提交绕过照片导入租约缺口

- 缺陷时序：
  - 用户先打开文本编辑会话；
  - 照片导入随后持有父级与 Canvas 共享租约；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - 统一确认回调原只检查 `historyBusy`；
  - 新建/本地替换/原版替换路径都可改写 `textBlocks` 或 `elementOrder`、推入撤销栈并触发
    持久化。
- 影响边界：触摸入口已阻止新交互；裁剪等直接提交已串行化。本缺口集中在导入前已存在的
  文本会话确认路径。
- 修复事实：`onTextCommit()` 在 `historyBusy` 前检查 `photoImportBusy` 并返回 false；
  草稿与会话状态保留，不改变空文本取消、CRDT 预览或页上下文防御。
- 验证：新增 `d02-text-commit-shared-lease-bound.mjs` 锁定守卫存在、顺序及提交副作用路径；
  当前输出 `TOTAL=7 FAILED=0`。
