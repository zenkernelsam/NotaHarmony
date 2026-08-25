# Harmony 证据 — 选区样式绕过照片导入租约缺口

- 缺陷时序：
  - 照片导入持有父级 `photoImportLeaseActive` 和 Canvas `photoImportBusy`；
  - 异步图片持久化提交后释放 `historyBusy`；
  - 外层 `finally` 尚未清除 `photoImportBusy` 或回报父页；
  - 工具栏样式/颜色/宽度回调原会直接更新本地值并递增信号；
  - Canvas watcher 原只经 `modifySelectedInkRegisters()` 检查 `historyBusy`；
  - 该窗口内的替换数组、撤销记录和后续照片结果可产生合并与重绘竞争。
- 影响边界：选区菜单已在 Phase 451 关闭；本缺口集中在同一工具栏的三个选区样式
  回调。页面结构、手动导航和跨页历史请求已被既有共享租约阻止。
- 修复事实：父页三入口统一检查四类租约；Canvas 三 watcher 统一先拒绝
  `photoImportBusy` 再执行历史、数据加载、健康与页身份条件。不新增状态字段，
  不改变颜色映射、宽度边界或撤销动作类型。
- 验证：新增 `d02-selection-style-shared-lease-bound.mjs` 锁定三入口双层守卫与
  调用顺序；当前输出 `TOTAL=15 FAILED=0`。
