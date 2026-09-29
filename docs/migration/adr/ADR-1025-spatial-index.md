# ADR-1025：空间索引 = igf long-map + sia 代次

## 状态

已接受（Phase 1081）。

## 决策

Harmony 包围盒空间索引 = `ue4→sia{igf,int gen}` →
`igf`（long[] 键/Object[] 值开放 map，packed opId 键）→
`vnd` Comparable 节点（实体快照+4-float 包围）；
`und{qo5,long}` 键包装。

## 依据

`sia.c` 空单例 + `vnd` 节点字段 + `igf` 数组结构。

## 后果

Harmony 用等价 long-keyed 空间 map；`sia.b` 代次戳失效。
