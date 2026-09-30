# ADR-1218：FlatBuffers 表编码

## 状态

已接受（Phase 1274）。

## 决策

`cee`/`uq9`/`qo5`/`vq9` FlatBuffers 表 → Harmony 手写
二进制 read/write 保格式或 `flatbuffers` TS 移植。

## 理由

`cee`=FlatBuffers Table（bb_pos/ByteBuffer/vtable/
__offset/__string/__reset）；`uq9`=顶层 op（qo5 实体
ID+ts+tmf/haa/sdf 嵌套载荷）；`qo5`=ID 记录 —— CRDT
文档变更的 FlatBuffers 编码。

## 后果

Harmony 文档编码 = 手写 FlatBuffers 格式（vtable+
ByteBuffer+UTF-8）—— op 编码语义保真。
