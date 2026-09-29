# ADR-1049：实体-map 谱系（builder↔snapshot MVCC）

## 状态

已接受（Phase 1105）。

## 决策

- `aja`/`tia` = `via` builder；`bja`/`uia` = `vz` 快照。
- `bja.W0(wia)→via` = 快照派生 builder（MVCC fork）。
- `qja extends jja` = `hja` 因果 store 上的只读 Map。

## 依据

`via`(pending+fold) ↔ `vz`(只读) 双向；`jja` 包装 `hja`。

## 后果

v69 实体 map = MVCC：快照→builder→mutate→快照；
Harmony 用 pending-Map + frozen 快照复刻。
