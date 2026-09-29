# ADR-1020：u09 六元 id 联合 + 解构器

## 状态

已接受（Phase 1076）。

## 决策

Harmony `u09` = sealed {`o09`实体|`r09`页|`p09` opId 引用|
`t09` tombstone|`q09` unit|`s09` asset-hash}；
`fsi.D`/`E` 提取 qo5/cxc 集，`tz9` 页引用。

## 依据

六变体载荷 + `F()` 产出 + `o14.t()` 穷尽检查。

## 后果

Harmony op→引用统一走 `u09` 联合（含 asset-hash 与
tombstone），同步/索引按变体消费。
