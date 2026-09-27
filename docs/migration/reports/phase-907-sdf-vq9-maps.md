# Phase 907 报告 — `sdf`/`vq9` 读契约实名

## 范围

钉死 TransientInteraction 与 OpAck 的 accessor 偏移。
纯审计。

## 原版发现

- `sdf` = TransientInteraction{interactionId:qo5@0,
  timeout:mmf@1(UInt)}。
- `vq9` = OpAck{id:qo5@0, timestampedOp:uq9@1,
  nakError:str@2, duplicate:Boolean@3}。

## Harmony 核对

瞬态槽/ack 字段对齐。

## 产出

- 证据：`phase-907-sdf-vq9-maps.md`
- Fixture：`d02-sdf-vq9-maps.mjs`（12/12）
- ADR-0851；全量 Replay 780 文件绿。
