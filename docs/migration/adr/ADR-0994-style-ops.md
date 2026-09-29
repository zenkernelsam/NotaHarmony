# ADR-0994 — 样式操作载荷与段落枚举

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `me8` ModifyStyle 15 字段（bold…code），familyName 非空、
  size>0；字段经 `z1d`/`v01`/`z2d`/`g2d`/`k2d` 包装类型。
- `he8` ModifyParagraphStyle 10 字段（alignment/indent/
  spacing/decorator/language/direction），isChecked 已废弃
  →UpdateCheckbox、空范围拒绝、无样式拒绝。
- `io1` ClearStyle 校验 start/end 锚点类型。
- 段落枚举：`r4a` 对齐 **1 基**（LEFT/CENTER/RIGHT）、
  `fy2` 装饰 6 值、`bcg` 方向 2 值；`o2d`/`j2d`/`b3d`
  byte 包装器。

## Harmony 决策

字段/校验/枚举 wire 保留；r4a 1 基编码注意。

## Parity 状态

等价。

## 验证

- `d02-style-ops.mjs`：12/12 通过。
