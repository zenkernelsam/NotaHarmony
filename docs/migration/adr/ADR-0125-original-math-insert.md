# ADR-0125: 原版 Math 插入与 CREATE_BLOCK 出站

## 状态

已采纳，2026-08-12。本文关闭 ADR-0063/0124 中 Math `CREATE_BLOCK` 本地 authoring 未完成的边界；
公式测量与排版引擎仍保持为明确后续边界。

## 原版证据

- `y08` 是独立的 `Insert` 状态；`z39` 从工具入口设置该状态。
- `fh3` 对 Edit 预填当前 LaTeX，对 Insert 使用空字符串；`n07` 的 Done 将状态与 draft 交给异步提交。
- `g18.U` 定义最大测量框 `240x120`；`g18.j()` 要求 viewport center 位于页面内，把测量结果居中到该点，
  再创建 `cz0.MATH`，默认颜色为不透明黑色。
- `s18` 通过私有 `GLMathNative.nativeMeasure` 测量公式，并按比例约束到 `240x120` 内。
- `u5j.f()` 创建普通 positionable Math Block，默认 SQUARE、无 rotation/scale、PIXEL_ALIGN、caption/lock false。

## 决策

- 工具栏提供 Math 入口；宽屏直接显示，紧凑模式进入更多工具菜单。入口打开空 draft，复用 Phase 147 的
  Cancel/Done/失败保留 overlay 生命周期；切页会取消未提交会话，防止草稿串页。
- `OriginalMathInsertPlan` 只负责可验证的纯几何和默认字段。viewport center 必须位于页面内；Math 居中放置，
  默认黑色、SQUARE、无旋转、caption/lock false。
- Harmony 当前没有原版私有公式引擎，因此暂以 `240x120` 原版最大测量框作为保守尺寸。规划函数接受未来引擎
  返回的更小测量值，但拒绝零值、非有限值或超过原版上限的结果。该边界不是实际公式测量结果。
- persistence 在共享 editor mutex 和单一 SQLite transaction 中读取 canonical 页面、分配 operation identity、
  编码 type-22 `CREATE_BLOCK`、调用生产 reducer、写 upload-immediate operation、推进一次 page revision、
  核对 canonical materialization、更新 search state，并追加持久 history companion；任一步失败整体回滚。
- UI 只在 durable transaction 成功后压入 Undo、安装 canonical Math/order、选择新元素并重绘。失败保留 draft；
  页面 generation 已变化时不污染新页内存，但已提交历史仍绑定原 pageId。

## 验证边界

本阶段不把 raw LaTeX 文本伪装成公式，也不声称 `240x120` 是公式的真实尺寸。完整语法 Invalid/Ok、原生公式
排版、真实尺寸回写、缩放像素质量和设备交互必须在引入等价引擎后验收。

## 验证

- `d02-local-math-insert.mjs` 锁定原版 Insert 状态、空 editor、测量边界、viewport center、CREATE_BLOCK、
  durable-before-UI、切页取消和失败回滚证据。
- `OriginalMathInsertPlan.test.ets` 覆盖默认最大框、未来引擎测量值、页面中心与非法尺寸拒绝。
- clean 双 HAP、专项及全量 replay 结果记录在 Phase 148 总结；未启动模拟器、虚拟机、真机或 Hypium。
