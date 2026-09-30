# Phase 1145 报告 — k85/l85 成员集合

## 完成内容

- `k85` = live 成员集合：`fqb` "members" LWW reg 持
  List<opId>；`M()`=reg 值。
- `l85` = spec（CREATE 造、`xj2.v` 委托、Companion j0）；
  spec↔live↔snapshot 三段。

## 产出

- evidence `phase-1145-k85-member.md`
- fixture `d02-k85-member.mjs`（10/10）
- ADR-1089
