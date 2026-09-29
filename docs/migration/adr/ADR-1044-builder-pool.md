# ADR-1044：builder 池 + SharedMemory arena + qo5 值语义

## 状态

已接受（Phase 1100）。

## 决策

- `dk4` = `cz8` 池化 16KB LE scratch ByteBuffer（`ra(28)`），
  复用前 `ByteBuffer::clear`（`ck4.P`）。
- `c8d` = `AutoCloseable` arena，持 `k1a{ByteBuffer,SharedMemory}`，
  close 时 unmap+close —— 原版 opId 序列化进 ashmem 零拷贝。
- `qo5` = `{site:UShort, timestamp:UInt}`，eq/hash/toString 固定。

## 依据

16KB 池 + SharedMemory unmap + 值类语义。

## 后果

Harmony：ArrayBuffer 池替代（无 ashmem 需求 → fail-closed 记录）；
qo5 等值/哈希语义完全保留。
