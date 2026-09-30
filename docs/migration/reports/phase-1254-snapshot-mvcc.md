# Phase 1254 报告 — Compose 快照 MVCC

## 完成内容

- `tjd`=全局快照（`rjd` 当前+`e` 计数+锁+observers）；
- `osd`=StateObjectImpl+`zjd`=snapshot-id 版本记录；
- `p6a`=MutableState（`akd` policy+`e` 3-way merge+
  Parcelable）—— Compose MVCC 快照隔离+冲突合并。

## 产出

- evidence `phase-1254-snapshot-mvcc.md`
- fixture `d02-snapshot-mvcc.mjs`（10/10）
- ADR-1198
