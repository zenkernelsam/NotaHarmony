# Phase 942 报告 — 样式 op 偏移图

## 范围

me8/he8/io1 全槽位钉死。纯审计。

## 原版发现

- me8=ModifyStyle 15 字段（v01+qo5+12 setter）。
- he8=ModifyParagraphStyle 10 字段（**cxc** 范围）。
- io1=ClearStyle 4 字段。
- v01↔cxc 范围类型层级差异确认。

## 产出

- 证据：`phase-942-style-ops.md`
- Fixture：`d02-style-ops.mjs`（30/30）
- ADR-0886；全量 Replay 815 文件绿。
