# Phase 1190 证据 — undo/redo 历史（nnf cap 栈 + ekd op-list）

来源：`defpackage/{nnf,ekd}.java`。

## `nnf` = 有界 undo/redo 操作栈

```java
nnf(int capacity, List undo, List redo):
  a = capacity                    // 上限
  b = ekd(undo)                   // undo op-list
  c = ekd(redo)                   // redo op-list
  guard: capacity>=0 且 undo+redo<=capacity
   ("Capacity must be a positive integer" /
    "Initial list of undo and redo operations have a
     size greater than the given capacity")
```

**有界撤销历史**：undo 与 redo 共占 `capacity` ——
op 级撤销（非快照）—— CRDT op 天然可逆。

## `ekd implements Parcelable,nsd,List,RandomAccess,jk6`

`Parcelable` op-list（`isd I` 背、跨进程/Bundle 保存）——
op 列表可 Parcelable → undo 栈随 activity-state 保存。

## 判定

**撤销 = op 栈**：新 op → push undo、清 redo；undo →
pop undo、逆 op apply、push redo —— 有界 `nnf` +
Parcelable `ekd`（进程重建可恢复）。

## Harmony 决策

- `nnf`/`ekd` → Harmony 有界 undo/redo op 栈（op 逆
  变换 apply）。
- `Parcelable` → Harmony `sendable`/wantParams 状态保存。

## 产出

- fixture `d02-undo.mjs`（10 断言）。
- ADR-1134；中文报告。
