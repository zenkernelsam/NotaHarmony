# ADR-1115：SharedMemoryByteArena + NbLog + learn

## 状态

已接受（Phase 1171）。

## 决策

- `SharedMemoryByteArena`（=`c8d` 真实名）— ashmem 区
  暂存 FlatBuffers 结构体（零拷贝/binder 可共享）。
  Harmony：可退化为**池化 ByteBuffer/`ArrayBuffer`**
  （FlatBuffers 暂存仅需线程局部缓冲；跨进程共享
  时才需 IPC SharedBuffer）—— 语义保留 arena 分配/
  ArenaClosed 守卫。
- `NbLog`（`fp7` sink + `FatalLogError`）→ Harmony
  `HiLog` 门面 + fatal→`Error`。
- learn `Room`（`LearnDatabase` 3 DAO + `AiDisabled`）→
  Preferences/RDB。

## 理由

`SharedMemory.create/mapReadWrite/unmap` + `b(int)` 切片 +
`ReferenceQueue` 跟踪 + `bytes_allocated` 遥测。

## 后果

Harmony 暂存层：普通池化 ByteBuffer（不跨进程时）；
保留 ArenaClosedException 等价守卫语义。
