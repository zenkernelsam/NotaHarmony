# ADR-0851 — `sdf`/`vq9` 读契约钉死

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `sdf` = TransientInteraction{interactionId:qo5@c(4)必填,
  timeout:mmf@c(6)UInt}。
- `vq9` = OpAck{id:qo5@c(4), timestampedOp:uq9@c(6),
  nakError:String@c(8), duplicate:Boolean@c(10)}。
- 读法：内联结构/标量/间接表三类同 uq9。

## Harmony 决策

瞬态交互槽与 ack 解析四字段对齐。

## Parity 状态

等价（读表族 accessor 图基本齐）。

## 验证

- `d02-sdf-vq9-maps.mjs`：12/12 通过。
- 全量 Replay 780 文件绿，见 Phase 907 提交。
