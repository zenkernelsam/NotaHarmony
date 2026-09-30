# Phase 1171 证据 — core/common/memory+logging + data/learn

来源：`core/common/memory/`、`core/common/logging/`、
`data/learn/`。

## `SharedMemoryByteArena`（`a`）= c8d 真实命名源（证实）

```java
a implements AutoCloseable:
  SharedMemory.create(name, iMax)          // ashmem 区
  .mapReadWrite().order(J)                 // RW ByteBuffer
  ByteBuffer b(int) {                      // 子分配切片
    if (closed) throw ArenaClosedException;
    …slice…
  }
  SharedMemory.unmap(a8d.b)                // close 释放
  ReferenceQueue + ArrayList + HashSet     // 缓冲跟踪
  xn7.put("bytes_allocated")               // 遥测
```

`SharedMemoryByteArena$ArenaClosedException extends
IllegalStateException` —— 证实 Phase-1100 `c8d` =
ashmem FlatBuffers 暂存区（opId/anchor 结构体写入
SharedMemory 零拷贝区）。

## `NbLog`（logging `a`）= 日志门面

```java
ArrayList a,b = fp7 日志槽；a(ep7,yn7)=过滤；b/c=写
NbLog$FatalLogError extends Error      // 致命日志→crash
ep7/yn7 = level/tag；ix4 lambda 惰性消息
```

## `data/learn` = learn/onboarding Room

- `LearnError extends Exception` sealed — **`AiDisabled`
  data-object**（AI-禁用 learn 错误）。
- `LearnDatabase extends x5c`（Room）+ `_Impl`：3 DAO
  （`q47`/`e57`/`a9b`）。

## Harmony 决策

- `SharedMemory` → Harmony **`IPC`/`SharedBuffer` 或堆
  ByteBuffer** —— FlatBuffers 暂存可退化为普通池化
  ByteBuffer（零拷贝/binder 语义非必需时可简化）。
- `NbLog` → Harmony `HiLog` 门面。
- learn Room → Preferences/RDB。

## 产出

- fixture `d02-common-memory.mjs`（10 断言）。
- ADR-1115；中文报告。
