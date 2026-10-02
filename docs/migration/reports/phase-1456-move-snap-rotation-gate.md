# Phase 1456 报告：移动拖拽吸附旋转禁用门（guf.b / twm.e / ne1.w）

## 触发

变换会话族 `xtf`(Move) 收尾审计：Harmony 已有移动吸附管线
（`planSelectionSnap`/`planOriginalSnapMove`/accent 导线渲染），
但 `guf.b` 的 `twm.e` 旋转门缺失。

## 原版证据链

1. **`guf.b`（guf.java:104-160）**：`this.j`（ne1 吸附引擎）非空时
   取旋转 `fJ`——ksf 支 `ksf.g()` 选区态、lsf 支 `hv6.j()` 元素自身；
   `!twm.e(fJ)`（旋转为 null/0）才进吸附：候选点=选区界四角+中心
   （ksf）或元素轮廓点+中心（lsf），`ne1.w(origin, j, list)` 产
   `mkg(校正偏移, 导线集)`，`z()` 渲染导线。
2. **`twm.e`**：`f != null && f != 0`——旋转非零 → 吸附禁用。
3. **`ne1.w`**：每轴独立胜者，返回校正偏移与对齐导线；
   `guf.d` 会话期构造吸附目标（页几何+缩放容差）。
4. **`guf.z`**：导线转屏幕坐标送渲染通道。

## Harmony 修改

`NoteCanvasView` 新增 `selectionSnapRotation()`——`state.transform`
旋转分量优先，零时单元素选区回退成员自身旋转（形状
`shapeVertexRotation`、笔画 transform、文/图/数学 `rotationRadians`）；
`planSelectionSnap` 入口 |θ|>1e-4 → 清空导线返回零校正。

## 登记差异（ADR-1391）

- lsf 吸附锚点原版为元素轮廓点集，Harmony 用界锚点（粒度差，
  门控语义不受影响）；
- 原版吸附引擎会话期装配，Harmony 帧级重采集（语义等价）。

## 验证

- `d02-original-snap-to-grid`：47 项绿（新增 6 项旋转门断言）。
- 全量基线 / 双 HAP：随提交前流程执行。
