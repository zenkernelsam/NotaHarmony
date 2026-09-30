# Phase 1274 报告 — FlatBuffers 表

## 完成内容

- `cee`=FlatBuffers Table 基类（bb_pos/ByteBuffer/
  vtable/__offset/__string/__reset+`zq6.i()` decoder）；
  `uq9`=顶层 op 表（qo5 实体 ID+long ts+tmf/haa/sdf
  嵌套载荷）；`qo5`=ID 记录（String/short/int）；
  `vq9`=op 载荷表→uq9 —— CRDT 文档变更编码。

## 产出

- evidence `phase-1274-flatbuffers-tables.md`
- fixture `d02-flatbuffers-tables.mjs`（10/10）
- ADR-1218
