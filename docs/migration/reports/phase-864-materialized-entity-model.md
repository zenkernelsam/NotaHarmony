# Phase 864 报告 — 物化实体模型登记

## 范围

登记原版物化层：ly3/qg2/yy3/mz9 接口栈、7 个 `*Impl` 物化类、
`yc6` 赢家寄存器与 `u()` 重序列化；核对 Harmony 持久化式等价。
纯审计阶段，无源改动。

## 原版发现

- 实体接口栈：每实体 `O()` 携带来源 Op；`qg2.u()` 可将当前物化
  态折回新 Op；`mz9` 定义 Page 契约。
- 7 Impl：Page/Ink/Page-builder/RichText/Shape/Group/Recording。
- `wz9` PageImpl：op+payload+序号 + 三个 yc6 寄存器（background/
  bookmarked/pageInAsset），bookmark 由赢家物化，位置由
  op-id+序号派生。

## Harmony 核对

- `OperationIdentity`（u16/u32 校验 + op:ts:site 编码）、OpStoreImpl
  op_id/operation_index 溯源、赢家行物化 —— 持久化式等价成立。

## 产出

- 证据：`phase-864-materialized-entity-model.md`
- Fixture：`d02-materialized-entity-model.mjs`（28/28）
- ADR-0808；全量 Replay 与双 HAP 结果记录于提交。
