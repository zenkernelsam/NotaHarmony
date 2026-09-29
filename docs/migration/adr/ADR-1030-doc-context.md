# ADR-1030：文档上下文 — ny3 包围盒服务 + al2 tombstone

## 状态

已接受（Phase 1086）。

## 决策

- `ny3` = 包围盒服务 iface（`a(qo5,int,k11)`/`e` set/get，
  id+子序号寻址）。
- `al2` = tombstone 因果 Map（`ba6.K` 查的表；`gja` 内层
  + 脏集追踪）。
- `jm5` = 文档临时槽；`a79` 常量。

## 依据

`v69` 字段类型 + `ny3`/`al2` 实现签名。

## 后果

Harmony 包围盒走 `ny3` 服务（空间索引后端）；删除标记
独立 `al2` map。
