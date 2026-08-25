# Harmony 证据 — 已展开选区菜单绕过共享租约的交互缺口

- 缺陷时序：
  - 用户先打开选区菜单；
  - 照片导入随后持有父级与 Canvas 共享租约；
  - 异步持久化完成后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - 菜单按钮原不感知共享导入活动；
  - 点击 COPY 可调用 `prepareSelectedClipboard()` 并基于当前元素数组发布剪贴板快照。
- 影响边界：DELETE/CUT/排序等变更动作已被 Phase 451 统一入口拒绝；缺口集中在 COPY 这一允许
  通过的无文档写入动作，以及按钮可点击性本身。
- 修复事实：菜单按钮由 `menuEnabled` 禁用，条件覆盖共享导入、历史、健康、加载失败和页身份；
  统一入口守卫保留。不改变剪贴板内容、action 分支或状态字段。
- 验证：新增 `d02-selection-menu-button-shared-lease-bound.mjs` 锁定属性、按钮 enabled 绑定、
  六项条件和第二层守卫；当前输出 `TOTAL=10 FAILED=0`。
