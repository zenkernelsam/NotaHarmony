# ADR-1388：选区旋转柄 90° 角度吸附（guf.e / twm.d）

## 状态

已实施（Phase 1453）。

## 背景

1.4.2 选区变换会话分三类：`xtf`（Move）、`vtf`（Rotate 旋转柄）、
`wtf`（Scale 角柄）。`vtf` 旋转会话的每帧角度由 `guf.e` 计算：

```
atan2(pointer − centerAbsolute) → 对 n={-π,-π/2,0,π/2,π} 吸附
（|差|<m=fq9.z(5f)=5°）→ 减 startingRadians
```

`twm.d` 在捏合会话（`guf.v`）执行同款吸附：`round(θ/(π/2))·(π/2)`，
阈值 5°。Harmony 此前旋转柄为纯自由角——无吸附，是行为缺口。

## 决定

- `applySelectionResize` 的 `resizeIsRotate`（旋转柄）支：
  绝对指针角先 `round(θ/(π/2))·(π/2)` 吸附（|差|≤5° 弧度阈值
  `SELECTION_ROTATE_SNAP_RAD`），再减 `atan2(start−anchor)`。
  吸附在**绝对角**上实施（原版 guf.e 语义）——已旋转选区上旋转，
  落地角度对齐全局 0/±90/±180°。
- 角柄支维持 1.0.3 `htc.e` 自由变换语义：1.4.2 `wtf` 会话无角度
  字段且 `guf.f` 产 (sx,sy) 双轴缩放对，但 `guf.r/s` 应用路径反编译
  失败——非等比缩放与"角柄不旋转"的合并语义无法确证，登记差异
  不改行为。

## 后果

- 旋转柄拖拽在 ±5° 内自动贴齐 0/90/180/270°——与原版一致。
- 捏合旋转吸附（`twm.d` 于 utf 会话）无双指变换面，不适用。
- RTL 左柄 +π 起始角（ms1:525 `yj8.G`）依赖 RTL 柄锚，登记。

## 验证

- `d02-original-selection-rotate-snap.mjs` 13 项（常量/吸附结构/
  边界语义 + 可执行数学模型：88°→90°、2°→0°、±176°→±180°、
  40°/50° 自由、5° 边界）。
- `d02-original-selection-resize.mjs` 29 项（旧 pin 更新为
  `curRadians` 表达式）。
