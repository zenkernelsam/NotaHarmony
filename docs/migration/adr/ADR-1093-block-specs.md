# ADR-1093：块 spec（图像/纸）

## 状态

已接受（Phase 1149）。

## 决策

- `hp5` = 图像块：`cropRect`(Rect)、`imageFlippedV/H`
  (bool)、`m4c` 成员集合；`xy0,be5,bf0,ce5,oy0`。
- `cie` = 纸块：`paper`(Paper)、`resizesWidthToFitText`、
  `m4c`；`xy0,xhe,be5,bf0,ce5`。
- `w1b` 泄漏 `core.flatbuffers.{Rect,Paper}` 真名。

## 依据

`fl6[]` 描述符真属性名 + `m4c` 成员 + iface 集。

## 后果

Harmony：图像块 `{cropRect,flipV/H,members}`；纸块
`{paper,resizesW,members}`；`Rect`/`Paper` FlatBuffers 表。
