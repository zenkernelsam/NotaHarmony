# Phase 1048 报告 — 形状/组操作载荷

## 范围

`ao2`/`le8` 形状、`cm2`/`vd8` 组、`t16`/`cmf`/`fqa`/`ife`/
`tmf` 类型。纯审计。

## 原版发现

- CreateShape/ModifyShape 各 17 字段（含 definition 子表、
  smartHighlight、positionLocked、inkEffects）。
- 校验：禁变宽墨迹、fillColor 禁零 alpha（用 nil）、
  inkEffects 仅 PEN/HIGHLIGHTER、shapes/members>0。
- `t16` = 墨迹样式 4 枚举（VARIABLE_WIDTH/FIXED_WIDTH/
  DASH/DOTS）；`cmf` = byte 色值类。

## Harmony 决策

字段+校验+枚举逐条保留。

## 产出

- 证据：`phase-1048-shape-group-ops.md`
- Fixture：`d02-shape-group-ops.mjs`（12/12）
- ADR-0992；全量 Replay 见本提交。
