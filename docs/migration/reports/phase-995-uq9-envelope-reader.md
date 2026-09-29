# Phase 995 报告 — `uq9` 信封读侧访问器表

## 范围

uq9.java 全访问器。纯审计。

## 原版发现

- 七字段读侧表完整：id(必需,slot4)/clientTime(6)/
  serverTime(8)/audioTime(10)/payloadType(12)/
  payload(14)/transientInteraction(16)——与 `zq9.d`
  写序严格镜像。
- `m()` = byte→haa **界外回退 NONE**（随后 z5c.x
  NONE fail-loud——两阶段安全降级）。

## 产出

- 证据：`phase-995-uq9-envelope-reader.md`
- Fixture：`d02-uq9-envelope-reader.mjs`（13/13）
- ADR-0939；全量 Replay 见本提交。
