# Phase 1054 报告 — SET_METADATA 完整字段

## 范围

`l2d` 8 字段、`z2d`/`m2d` 包装、`tv6`/`dz0` 枚举。纯审计。

## 原版发现

- SetMetadata{title:z2d, pageBackground:m2d,
  handwritingLanguage:z2d, alignTextToLines:Boolean,
  defaultFontFamily, defaultFontSize, layoutMode:tv6,
  blockWrapSupport:dz0}。
- `z2d`=SetString{value} 通用包装；`tv6` PAGED/PAGELESS；
  `dz0` 三值含 LEGACY_WRAP_ENABLED=2。
- 校验全集（title≤256、字体族≤30、字号>0、模板单页）
  已在 Phase 1044 记录。

## Harmony 决策

字段/校验/枚举逐条保留；alignTextToLines 三态可空。

## 产出

- 证据：`phase-1054-setmetadata.md`
- Fixture：`d02-setmetadata.mjs`（11/11）
- ADR-0998；全量 Replay 见本提交。
