# Phase 973 报告 — ie8 ModifyPosition + w0j 写器

## 范围

ie8/w0j。纯审计。

## 原版发现

- `ie8` = ModifyPosition 6 字段（target 必需 + page/
  origin + rotation/scale setter 子表 + zIndex long）。
- `w0j.e` 写器完整解剖；`w0j.f` 层序映射助手。
- zIndex=long（tmf.I）位宽差异再证。

## 产出

- 证据：`phase-973-modify-position.md`
- Fixture：`d02-modify-position.mjs`（15/15）
- ADR-0917；全量 Replay 见本提交。
