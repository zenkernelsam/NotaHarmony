# Harmony 证据 — 数学确认绕过照片导入租约缺口

- 缺陷时序：
  - 用户先打开数学编辑或插入会话；
  - 照片导入持有父级与 Canvas 共享租约；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - 编辑确认可替换 Math 并推入 TRANSFORM 撤销记录；
  - 插入确认可新增 Math、更新 elementOrder 并推入 ADD_ELEMENTS 记录。
- 影响边界：Phase 452 已阻止新插入入口；本缺口覆盖导入前已存在会话的启动编辑与确认路径。
- 修复事实：`startMathEditing()`、`confirmMathEditing()` 和 `confirmMathInsert()` 在
  `historyBusy` 前检查 `photoImportBusy`。不新增状态字段，不改变 CRDT 预览、页上下文校验
  或失败恢复。
- 验证：新增 `d02-math-commit-shared-lease-bound.mjs` 锁定三入口守卫顺序与插入副作用；
  当前输出 `TOTAL=9 FAILED=0`。
