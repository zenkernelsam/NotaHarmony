# Phase 972 报告 — 写器字段数/required 槽总稽查

## 范围

41 个注册表写器逐一 `C(N)`+`z()` 对账。纯审计。

## 原版发现

- 全表写侧 C(N)/required 宽表建立（证据清单）。
- required 为读侧校验概念，写侧仅对核心键置位——
  e46/ln2/mqf/yda 等写侧零 required。
- `ys2.O`=平铺 19 参 dm2 工厂（C(20), req 4,6,18）。
- `v0j.d` 内嵌 b3d setter 写器现场实证（949 闭环）。
- 订正：le8/td8 f0 required；dm2 实为 C(20)。

## 产出

- 证据：`phase-972-writer-field-sweep.md`
- Fixture：`d02-writer-field-sweep.mjs`（46/46）
- ADR-0916；全量 Replay 见本提交。
