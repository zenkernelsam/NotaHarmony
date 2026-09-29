# ADR-0992 — 形状/组操作载荷

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ao2` CreateShape/`le8` ModifyShape 各 17 字段（definition
  子表/原点/缩放/样式/边宽/填充/zIndex/锁定/effects）。
- 校验：禁 VARIABLE_WIDTH、fillColor 禁零 alpha、
  inkEffects 仅 PEN/HIGHLIGHTER、shapes/members>0。
- `cm2`/`vd8` 组操作 members>0。
- `t16` 墨迹样式 4 值；`cmf` byte 色值；`fqa`/`ife`/`tmf`
  原点/胶带/层序类型。

## Harmony 决策

字段与校验逐条保留；t16 wire 对齐。

## Parity 状态

等价。

## 验证

- `d02-shape-group-ops.mjs`：12/12 通过。
