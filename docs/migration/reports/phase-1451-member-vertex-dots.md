# Phase 1451 报告：lsf 形状成员顶点圆点（qmm.d cpfVar.g）

## 原版行为（1.4.2 反编译证据）

`qmm.b(..., z)` 中 `z = msfVar instanceof lsf`——**仅点选型单元素
选区的形状成员**产顶点集 `cpf.g`（笔画成员恒空）；`qmm.d` 逐点绘
双层圆：白半径 `7.5dp/zoom`（`6dp·1.25`）+ `#FF4278FF` 半径
`6dp/zoom`。

顶点集（`m4g.b()` 族）：

- LINE：`[start, B(0.5) 加权中点（0.125/0.375/0.375/0.125，有控制
  点时）, end]`；
- POLYGON：全部顶点；
- ELLIPSE：包围盒四基向点。

## Harmony 缺口（修复前）

lsf 点选形状只有路径轮廓，无顶点圆点——顶点编辑暗示缺失。

## 本次改动

- `renderSelectionMemberChrome`：新增 `lsf` 判定（`!supportsDeselect
  Mode && selectedGroupIds==0 && memberCount==1`），形状成员描边后
  逐顶点绘双层圆。
- `shapeVertexDots(shape)`：LINE/POLYGON/ELLIPSE 顶点集局部坐标 →
  `transformMemberPoint` 世界化。

## 验证

- `d02-original-member-chrome-render.mjs` 扩至 28 断言。
- 证据：`evidence/phase-1451-member-vertex-dots.md`；ADR-1386。

## 结果

全量基线与双 HAP 构建见提交信息。
