# Phase 993 报告 — `z5c.x` apply 分派 + 信封访问器

## 范围

z5c.x/uq9.q·r·toString/aq1/gk4.m·o。纯审计。

## 原版发现

- `z5c.x` = **32-case 序数→载荷类物化全表**，
  与 Phase 964 `zq9.a` 反向表对偶闭合；NONE(0)
  fail-loud。
- `uq9` 访问器：`q`=f5 payload、`r`=f6
  transientInteraction；toString 实证字段名。
- `aq1` = ClientOp 行（blob 可空+opId+length——
  LENGTH(op) 超限分流）。
- `gk4.m/o` = qo5 long 解包+列表解码。

## 产出

- 证据：`phase-993-apply-dispatcher.md`
- Fixture：`d02-apply-dispatcher.mjs`（39/39）
- ADR-0937；全量 Replay 见本提交。
