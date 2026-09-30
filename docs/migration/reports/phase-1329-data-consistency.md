# Phase 1329 报告 — 数据一致性

## 完成内容

- `OriginalInkPathCodec`（`decodeElements`：element type→
  pointCount+float32-LE x/y 逐点解码；canonical/
  replacement/auxiliary/append 4 变体——float32 无损
  往返对照原版二进制路径格式）+ FlatBuffer op 编解码
  —— 序列化往返保真（f32 精度+字段完整+op 结构）。

## 产出

- evidence `phase-1329-data-consistency.md`
- fixture `d02-data-consistency.mjs`（10/10）
- ADR-1273
