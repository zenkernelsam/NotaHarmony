# ADR-1201：nnf/ekd/dve 有界撤销栈

## 状态

已接受（Phase 1257）。

## 决策

`nnf{cap,ekd,ekd}` 有界双栈+`ekd`=SnapshotStateList+
Parcelable+`dve` 逆操作 → Harmony `@Observed`/`@State`
ArrayList 有界栈+逆操作。

## 理由

`nnf`=cap 守卫双栈；`ekd`=`Parcelable+nsd+List`
（snapshot-state-list+跨进程）；`dve`=逆操作 `{pos,
before/after,ts,oje}` —— 撤销栈。

## 后果

Harmony 撤销 = @Observed 有界栈+逆操作 —— 撤销
语义保真。
