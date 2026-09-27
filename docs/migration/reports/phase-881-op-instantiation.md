# Phase 881 报告 — `wq9`/`xq9` op 实例化层

## 范围

登记原版 op 创建/应用调用链 `xq9Var.a(new wq9(payload,...))`
（47 处调用点）。纯审计，无源改动。

## 原版发现

- `wq9` = `OpCreationMetadata`（toString 实证）：
  payload/transient/inProgressTransientId/transientTimeout/
  audioTime；存根掩码 30 全默认；transientTimeout = 被省略
  参数序号 3。
- 自动 transient：显式 z 或 transientId 或 payload 类型
  ∈{26,29}。
- `xq9.a` = 实例化 lambda：双计数器（瞬态/持久分占）、
  `rh8.b(counter,site)`→qo5、transient→sdf{transientId}、
  `zq9.e`→uq9 信封、返回新 op-id。
- `rh8.b`/`rh8.O` = qo5 构造/序列化原语。

## Harmony 核对

`OpStoreImpl`/`nextOperationTimestamp` = 序号分配；
`StrokePersistence` 已引 xq9 transaction；sdf/zq9.e 与
PeerInteraction 及信封编码器对齐。

## 产出

- 证据：`phase-881-op-instantiation.md`
- Fixture：`d02-op-instantiation.mjs`（22/22）
- ADR-0825；全量 Replay 与双 HAP 结果记录于提交。
