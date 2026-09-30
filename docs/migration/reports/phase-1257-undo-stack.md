# Phase 1257 报告 — 有界撤销栈

## 完成内容

- `nnf{cap, ekd undo, ekd redo}`=有界双栈+容量守卫；
- `ekd`=Parcelable+nsd SnapshotStateList（compose-
  reactive+跨进程 op 栈）；`dve`=逆操作 `{pos,before/
  after text,ts,oje}` —— 撤销/重做栈+逆操作物化。

## 产出

- evidence `phase-1257-undo-stack.md`
- fixture `d02-undo-stack.mjs`（10/10）
- ADR-1201
