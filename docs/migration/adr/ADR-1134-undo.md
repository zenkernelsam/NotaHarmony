# ADR-1134：undo/redo 历史（nnf 有界 op 栈）

## 状态

已接受（Phase 1190）。

## 决策

`nnf{capacity, ekd undo, ekd redo}` = **有界 undo/redo op
栈**（共占 capacity，op 级逆变换）+ `ekd`=`Parcelable,
List,RandomAccess` op-list → Harmony 有界 undo/redo op
栈（op 逆变换 apply）+ sendable/wantParams 状态保存。

## 理由

`nnf(int,List,List)` + capacity/size guards + `ekd`
Parcelable+RandomAccess + `isd` 背。

## 后果

撤销 = op 逆变换（CRDT 天然可逆）；有界栈；Parcelable
→ Harmony 进程重建状态保存；语义保真。
