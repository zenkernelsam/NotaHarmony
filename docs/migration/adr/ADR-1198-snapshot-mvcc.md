# ADR-1198：Compose 快照 MVCC

## 状态

已接受（Phase 1254）。

## 决策

`tjd` 全局快照+`osd`/`zjd` 版本化记录+`p6a` MutableState
（`akd` policy+3-way merge）→ Harmony `@State`/自研
版本化 state。

## 理由

`tjd`=MVCC 快照（`rjd` 当前+`e` 计数+锁+observers）；
`zjd`=snapshot-id 版本记录；`p6a`=`MutableState`（3-way
merge+Parcelable）—— 快照隔离+冲突合并。

## 后果

Harmony 状态 = @State+版本化 —— MVCC 语义保真。
