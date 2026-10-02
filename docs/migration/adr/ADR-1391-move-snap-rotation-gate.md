# ADR-1391：移动拖拽吸附的旋转禁用门（guf.b / twm.e）

## 状态

已实施（Phase 1456）。

## 背景

原版 `guf.b(xtf, j)` 在移动拖拽每帧对拖拽位移做对齐吸附，但前置
`!twm.e(fJ)` 门——`twm.e` 判定 `fJ != null ∧ fJ != 0`：选区态旋转
（ksf 支 `ksf.g()`）或 lsf 元素自身旋转（`hv6.j()`）非零时**整体
跳过吸附**，原样返回位移。

Harmony 的 `planSelectionSnap` 无此门——旋转选区/旋转元素拖拽
时仍对 AABB 锚点吸附，产生原版不存在的吸附跳变与误导性导线。

## 决定

- 新增 `selectionSnapRotation()`：先取 `state.transform` 旋转分量
  （`atan2(m3,m0)`，ksf 支 `ksf.g()` 等价）；为零且恰为单元素
  选区时取成员自身旋转（形状 `shapeVertexRotation`、笔画 transform
  旋转、文本/图片/数学 `rotationRadians`——`hv6.j()` 等价）。
- `planSelectionSnap`：旋转 |θ|>1e-4 时清空导线并返回零校正
  （= `guf.b` 的 `return j` 原样位移语义）。

## 登记差异

- lsf 支原版吸附锚点用元素轮廓点集（`og0.e`/`s40.t` 路径点 +
  `og0.h/i` 中心），Harmony 用 `originalSnapMoveAnchors(bounds)`
  界锚点——门控本身已对齐，锚点粒度差异保留。
- `ne1` 会话期引擎在会话开始即装配页几何（`guf.d`/`og0.d`），
  Harmony 每帧重采集可见候选——语义等价（帧级新鲜），无行为差。

## 后果

- 旋转后的选区/单元素拖拽不再吸附——与原版一致。
- 非旋转场景吸附行为不变。

## 验证

- `d02-original-snap-to-grid.mjs` 扩至 47 项（旋转门存在性 +
  ksf/lsf 双路旋转源 + 门先于候选规划断言）。
