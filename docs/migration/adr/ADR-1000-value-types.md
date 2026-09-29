# ADR-1000 — 值类型清单

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 几何 struct：`fqa` Point、`qed` Size（**d()=width,
  c()=height 访问器序相反**）、`bmb` Rect、
  `vy7` Margins（非负校验）。
- `hu1` Color byte×4（bitsR/G/B/A）；`k3a` Paper 6 字段
  （alpha==1 + legacyPaperIndex）。
- `tmf` Comparable long 包装（时间戳/zIndex）。

## Harmony 决策

struct 布局/校验保留；qed 访问器序差异注意；
Paper alpha 校验保留。

## Parity 状态

等价。

## 验证

- `d02-value-types.mjs`：12/12 通过。
