# Harmony 证据 — 画布触摸绕过照片导入租约缺口

- 缺陷时序：
  - 照片导入持有父级 `photoImportLeaseActive` 和 Canvas `photoImportBusy`；
  - 异步图片持久化完成后先释放 `historyBusy`；
  - 外层 `finally` 尚未清除共享租约或回报父页；
  - `onCanvasTouch()` 原不检查 `photoImportBusy`；
  - DEFAULT 工具双击可命中复选框替换或创建文本块，二者都会推入撤销栈并触发持久化；
  - 书写、擦除和选区拖拽也可在该窗口启动，结束提交时与照片收口竞争。
- 影响边界：选区菜单、数学插入和选区样式已在 Phase 451-453 关闭。本缺口集中在画布
  统一触摸入口这一剩余直接文档变更源。
- 修复事实：触摸入口在健康和数据失败检查后、内部历史门禁前拒绝 `photoImportBusy`。
  不新增状态字段，不改变手势识别或各工具下游逻辑。
- 验证：新增 `d02-canvas-touch-shared-lease-bound.mjs` 锁定守卫存在、顺序及触摸可达的
  下游函数；当前输出 `TOTAL=11 FAILED=0`。
