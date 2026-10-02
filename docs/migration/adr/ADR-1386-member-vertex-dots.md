# ADR-1386: lsf 形状成员顶点圆点（qmm.d cpfVar.g / m4g.b 族）

## 状态

已接受（2026-08，Phase 1451）

## 背景

`qmm.b` 的 `z` 参（= `msfVar instanceof lsf`）仅对形状 `f5g` 成员
装配 `cpf.g` 顶点集；`qmm.d` 逐点绘双层圆——`gsf.b` 白半径
`(6dp/zoom)·1.25 = 7.5dp/zoom` + `gsf.a` 蓝半径 `6dp/zoom`。

顶点集语义（`m4g.b()` 族）：

- LINE（q89）：直=[start,end]；带控制点=[start, B(0.5) 加权中点, end]；
- POLYGON（l4g）：全部顶点；
- ELLIPSE（k4g）：包围盒四基向点。

Harmony Phase 1449 实现成员轮廓后未绘顶点圆点——lsf 点选形状时缺
顶点编辑暗示。

## 决策

`renderSelectionMemberChrome` 形状支内增 lsf 门控顶点圆点：
`shapeVertexDots(shape)` 按 LINE（start/加权中点/end）、POLYGON
（顶点）、ELLIPSE（旋转基向点）产局部点、乘 `shape.transform` 至
世界系，白 `7.5/zoom` + 蓝 `6/zoom` 双层圆。笔画成员永不产点
（`em4.F` 空集对齐）。

## 验证

- Fixture：`d02-original-member-chrome-render.mjs` 扩至 28 断言。
- 证据：`evidence/phase-1451-member-vertex-dots.md`。
