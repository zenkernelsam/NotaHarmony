# ADR-1046：实体-map 构建管线

## 状态

已接受（Phase 1102）。

## 决策

- `via` = builder：pending LinkedHashMap + `fm8` mutex + `a()`
  折叠进 `wia` → `vz` 快照。
- `wia` = store：`sia` 空间索引 + `igf` packed-long map +
  `b(long,v)` 写入。
- `uia extends vz` = 只读 Map 快照；`tia` 具体 builder；
  `xia` 游标；`lia` 集合视图。

## 依据

写挂 map 有序折叠、mutex 物化、packed-long 键、快照只读。

## 后果

v69 实体 map = pending→store→snapshot 三段式；Harmony 用
Map 累积 + 索引 store + frozen 快照复刻。
