# Phase 1329 证据 — 数据一致性（序列化往返保真）

来源：`data/{OriginalInkPathCodec,PersistedElementCodec,
StrokePersistence}.ets`。

## `OriginalInkPathCodec` = float32-LE 笔画路径编解码

```
decodeElements(bytes, minCount):
  element type → pointCount（type 0/4 = 3 点/…）
  每点 getFloat32(0)/getFloat32(4) —— float32 LE (x,y)
decodeCanonicalInkPath / Replacement / Auxiliary / Append
  —— 多种路径变体（canonical/replacement/auxiliary/append）
```

→ **float32 二进制路径编解码** —— 对照原版二进制
路径格式（float32 x/y，逐点无损往返）。

## 数据一致性语义

- **浮点精度**：float32 存储+读取 —— 与原版 float 存储
  一致（无精度损失，f32 往返无损）。
- **元素类型→点数**：`decodeElements` 按 type 查点数
  —— 结构字段无遗漏。
- **FlatBuffer op 编码**：`*PayloadEncoder` + `Original
  SyncedOperationFlatBuffer` —— op 往返保真（Phase 1309）。

## Harmony 决策

序列化 = float32-LE 二进制 + FlatBuffer op —— 往返
无损（f32 精度 + 字段完整 + op 结构保真）。

## 产出

- fixture `d02-data-consistency.mjs`（10 断言）。
- ADR-1273；中文报告。
