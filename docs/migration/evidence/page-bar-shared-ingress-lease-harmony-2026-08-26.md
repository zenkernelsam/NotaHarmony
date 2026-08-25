# Harmony 证据 — 页面管理条绕过共享租约的结构缺口

- 缺陷时序：
  - 照片导入持有父级 `photoImportLeaseActive`；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除共享租约或回报父页；
  - 页面管理条原只感知 `pageOperationBusy`，按钮仍可点击；
  - 新增/删除/移动页被 `runPageOperation()` 第二层拒绝，但设置弹层可保持展开；
  - 背景应用路径缺少显式结构租约防御。
- 影响边界：页序、当前选择、NOTE_BACKGROUND 历史和页面快照可在照片收口前变化，
  造成部分成功提示与并发合并风险。
- 修复事实：父页传入并计算共享租约 busy；页面管理条全部结构入口禁用；
  背景应用显式拒绝共享导入与结构租约。持久化语义不变。
- 验证：新增 `d02-page-bar-shared-lease-bound.mjs` 锁定调用绑定、六处按钮禁用、
  统一入口和背景防御；当前输出 `TOTAL=10 FAILED=0`。
