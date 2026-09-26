# ADR-0808 — 物化实体模型登记（接口栈/7 Impl/yc6 寄存器）

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- 接口栈：`ly3`（`O()`→uq9 归属 Op、`getId()`→qo5、`I()` synced 判定）
  → `qg2`（`u()` 物化态重序列化为新 Op）→ `yy3`（builder+generation）
  → `mz9`（Page 契约：background/bookmarked/pageInAsset/position/payload）。
- 7 个物化实现：PageImpl(wz9)、InkImpl(s06)、Page builder(vz9)、
  RichTextImpl(m4c)、ShapeImpl(n5d)、GroupImpl(l85)、RecordingImpl(gkb)。
- 每实体携带来源 Op + 经 `yc6` 寄存器（`.K` 赢家槽）物化 LWW 字段；
  `wz9` 用 `nti.g(opId, pageInPayload)` 派生位置、`u()` 将当前态
  折回 CreatePage 变体 Op（undo/重放）。

## Harmony 决策

- 持久化式等价：op 行存 `op_id`+`operation_index`+`client_time`
  溯源；`OperationIdentity` 校验 u16/u32 边界 + `op:<ts>:<site>`
  编码；赢家行物化（bookmarkWinner 等）承担寄存器语义。
- 差异登记：原版内存实体持 Op 指针，Harmony 经持久层查询 —
  语义等价、形态不同。

## Parity 状态

等价（溯源/物化语义）；形态差异已登记。

## 验证

- `d02-materialized-entity-model.mjs`：28/28 通过。
- 全量 Replay 与双 HAP 构建见 Phase 864 报告/提交。
