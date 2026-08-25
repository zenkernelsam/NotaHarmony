# Harmony 证据 — 数学插入绕过照片导入租约缺口

- 缺陷时序：
  - 照片导入持有父页 `photoImportLeaseActive` 和 Canvas `photoImportBusy`；
  - `insertOriginalPhotos` 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未执行 `photoImportBusy=false` 和父级回报；
  - 工具栏 `onInsertMath()` 原来无条件递增 `mathInsertSignal`；
  - `startMathInsert()` 原来不检查 `photoImportBusy`，可在窗口内打开数学编辑器；
  - 用户确认插入时，数学持久化与照片收口竞争 `elementOrder`、撤销栈和选区状态。
- 影响边界：页面结构、手动导航和跨页历史已被父级共享租约阻止；缺口集中在工具栏
  数学信号这一同步入口。Phase 451 已覆盖选区菜单，本修复补齐相邻工具栏路径。
- 修复事实：父页回调先检查 `photoImportLeaseActive`、`pageOperationBusy`、
  `historyPending` 和 `pageStructureLeaseActive`；Canvas 方法在 `historyBusy` 前检查
  `photoImportBusy`。不新增生产状态字段，不改变数学确认与照片收口逻辑。
- 验证：新增 `d02-math-insert-shared-lease-bound.mjs` 锁定两侧守卫存在与顺序；
  当前输出 `TOTAL=10 FAILED=0`。
