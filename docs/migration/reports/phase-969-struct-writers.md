# Phase 969 报告 — 内联结构写器字节序

## 范围

wtf/rz1/apb/y5j/efj 写器。纯审计。

## 原版发现

- 5 个内联结构写器字节序逐一实证：utf/v01/qed/hd1/cwb
  全部与读侧镜像（自底向上逆序推字段）。
- 写↔读对称性取证链闭合（qo5/cxc/v01/utf/fqa/qed/
  hd1/cwb 全系覆盖）。

## 产出

- 证据：`phase-969-struct-writers.md`
- Fixture：`d02-struct-writers.mjs`（13/13）
- ADR-0913；全量 Replay 见本提交。
