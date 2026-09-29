# ADR-0973 — manifest.json 字段 + w59 续体修正

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `yk9` manifest.json 键：`version`+`noteBundle`+
  `assets/`+资产 wa0 元数据（Phase 996）。
- `w59 extends ff2` = **suspend 续体状态**
  {ttf,String,lq4,Closeable,bool,int,y59 P}——
  **修正 Phase 1028**：`w59` 是续体参数，非回调
  sink；导出经 suspend 返回。

## Harmony 决策

manifest 字段保留；suspend 导出→ArkTS async。

## Parity 状态

等价（修正后）。

## 验证

- `d02-manifest-fields.mjs`：10/10 通过。
