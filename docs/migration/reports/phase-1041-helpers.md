# Phase 1041 报告 — xag/cxc/ee8 助手与类型

## 范围

`xag` hex 助手 + `cxc` pageId + `ee8`/`cee` op。
纯审计。

## 原版发现

- `xag` = hex 格式化写器（`c(long,bArr,i,i2,i3)`）。
- `cxc extends xwd implements ka4,exc` = pageId
  （`C()→int`+`a()`）。
- `ee8 extends cee` = MODIFY_PDF_FIELD op；
  `cee` = op-payload 基类；`exc` = 页 iface。

## Harmony 决策

hex/pageId/op 类型同构保留。

## 产出

- 证据：`phase-1041-helpers.md`
- Fixture：`d02-helpers.mjs`（10/10）
- ADR-0985；全量 Replay 见本提交。
