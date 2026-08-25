# Harmony 证据 — 选区菜单绕过照片导入租约缺口

- 缺陷时序：
  - Phase 447 的照片导入持有父级 `photoImportLeaseActive` 和 Canvas
    `photoImportBusy`；
  - 异步图片持久化提交完成时先释放 Canvas `historyBusy`；
  - 选区菜单 `onSelectionMenuAction()` 原来不检查 `photoImportBusy`；
  - 导入 `finally` 收口前可执行 CUT/GROUP/UNGROUP/REORDER/FLIP/LOCK/PASTE，
    改写元素数组、`elementOrder` 或撤销栈；
  - 随后照片插入按捕获上下文合并结果，产生顺序/选择状态竞争。
- 影响边界：页结构、手动导航、跨页历史请求已被共享租约阻止；本缺口集中在
  Canvas 选区菜单这一同步元素变更入口。COPY 只发布内存剪贴板，但为避免入口语义
  分裂一并等待。
- 修复事实：选区菜单统一入口在 `historyBusy` 前检查 `photoImportBusy` 并直接返回；
  不新增状态字段，不改变各 action 的既有验证。
- 验证：新增 `d02-selection-menu-shared-lease-bound.mjs` 锁定守卫存在与顺序；
  当前输出 `TOTAL=5 FAILED=0`。
