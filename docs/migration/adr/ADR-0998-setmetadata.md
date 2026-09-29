# ADR-0998 — SET_METADATA 完整字段与包装枚举

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `l2d` 8 字段：title/pageBackground/handwritingLanguage/
  alignTextToLines/defaultFontFamily/defaultFontSize/
  layoutMode/blockWrapSupport。
- `z2d`=SetString、`m2d`=SetPageBackground 包装层；
  `tv6`{PAGED,PAGELESS}、`dz0`{WRAP_ENABLED,
  WRAP_DISABLED,LEGACY_WRAP_ENABLED}。

## Harmony 决策

字段+校验（256/30/>0/模板单页）保留；PAGELESS/
LEGACY_WRAP 枚举值保留（旧数据可携带）。

## Parity 状态

等价。

## 验证

- `d02-setmetadata.mjs`：11/11 通过。
