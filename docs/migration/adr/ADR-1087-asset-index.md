# ADR-1087：v69.a 资产索引写

## 状态

已接受（Phase 1143）。

## 决策

- `v69.a(pa0,list)` = 资产索引写：`pa0→ua0` 资产哈希键
  →`gja` 注解图→`za0{qa0 type, Set}`（新建或 copy-with
  `ys2.J` 并入）。
- `w/x` = suspend 收集辅助（`t69` 委托）。

## 依据

`pa0.a().j()→ua0` + `h().get/put` + `za0.a(qa0,Set)` +
`ua0 extends xwd`（FlatBuffers 表）。

## 后果

Harmony：Map<assetHash,{type,Set}> 注解索引；附件→
实体引用追踪。
