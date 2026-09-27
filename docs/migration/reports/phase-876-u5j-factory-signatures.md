# Phase 876 报告 — `u5j` 工厂签名登记

## 范围

登记原版 op 工厂 `u5j` 全部公开签名（~24 方法）；核对
Harmony 编码器入参形态。纯审计阶段，无源改动。

## 原版发现

- 签名与 payload 字段精确对应：H=l2d 八 setter、n=td8
  十八参、k=s83 四向量、u=he8 exc 区间对、g=dm2 十六参。
- 参数模式：`?2d`/`nl8` 可空 setter、`xgb` 创建挂钟、
  `exc` 位置抽象、`v4d`/`mmf`/`z66` 专项参数。
- `haj.a(null,nz9,1,oz9,16)` 另族助手留档。

## Harmony 核对

编码器/Operation 入参形态与工厂可空更新语义对应。

## 产出

- 证据：`phase-876-u5j-factory-signatures.md`
- Fixture：`d02-u5j-factory-signatures.mjs`（29/29）
- ADR-0820；全量 Replay 与双 HAP 结果记录于提交。
