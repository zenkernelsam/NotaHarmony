# ADR-0899 — `dk4`/`c8d`：池化 builder + ashmem 分配器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `dk4.a(c8d)` = 池化 builder：cz8 池回收初始 ByteBuffer
  （`ByteBuffer::clear` 复位），`new a(c8d, bb)`。
- `c8d` = **SharedMemory 分配器**：`l2`=`SharedMemory.create
  ("fbb-shm")`+`mapReadWrite`+LE，`v2`/`close`=unmap+close；
  `R`=k1a{bb,shm} 追踪。笔记 FlatBuffer 构建于 ashmem。

## Harmony 决策

`SharedMemory` 无对应物 → Harmony 用普通 ByteBuffer/ArrayBuffer。
分配器为内存管理细节，**序列化字节逐位一致**——平台委托，
非线协议差异。

## Parity 状态

线格式等价；分配器平台差异已记录。

## 验证

- `d02-dk4-c8d-allocator.mjs`：12/12 通过。
- 全量 Replay 828 文件绿，见 Phase 955 提交。
