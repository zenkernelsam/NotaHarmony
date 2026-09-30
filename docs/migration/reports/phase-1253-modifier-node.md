# Phase 1253 报告 — Modifier.Node 基座

## 完成内容

- `od8`=Compose Modifier.Node 基类：`I`=self/`L`=kind
  -mask/`K`=kind-set/`M`/`N`=parent-child/`P`=LayoutNode/
  `J`=节点协程域；`U0`=`xc6` Job、`X0` detach 时
  `ModifierNodeDetachedCancellationException` cancel —
  — 节点基座（attach/detach 双重守卫）。

## 产出

- evidence `phase-1253-modifier-node.md`
- fixture `d02-modifier-node.mjs`（10/10）
- ADR-1197
