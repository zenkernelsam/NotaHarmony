# Phase 1100 证据 — dk4/cz8 builder 池 + c8d SharedMemory arena + qo5 值语义

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `dk4` = FlatBufferBuilder 池

```java
cz8 b = new cz8(new ra(28), ck4.P);
a a(c8d c8d) {
  ByteBuffer bb = x82.x(b, FB_BYTE_BUFFER_HOLDER);
  return new a(c8d, bb);
}
```

- `ra(28)` case = `ByteBuffer.allocate(16384).order(LITTLE_ENDIAN)` ——
  **16KB 小端 scratch buffer**，线程本地缓存复用。
- `ck4.P` = `ByteBuffer::clear` 方法引用 —— 复用前 clear 复位。
- `cz8` = 属性委托缓存（`x82.x` 取值）。

## `c8d extends ldj implements AutoCloseable` = SharedMemory arena

```java
ArrayList R;  // k1a{ByteBuffer I, SharedMemory J}
close() { for each: SharedMemory.unmap(bb); sharedMemory.close(); }
```

**opId/anchor 序列化进 android.os.SharedMemory（ashmem）** ——
零拷贝、可跨进程 binder 共享的 buffer；`close()` 时 unmap+close。

## `qo5` 值语义

- `d()`=timestamp（`mmf`=UInt int），`c()`=site（`ymf`=UShort short）。
- equals = 两字段相等；hashCode = `Short.hashCode(c()) + Integer.hashCode(d())*31`。
- toString = `Id(site=, timestamp=)`。

## Harmony 决策

- builder 池：16KB LE scratch + clear 复位（Harmony 用 ArrayBuffer 池）。
- SharedMemory arena → Harmony 用普通 ArrayBuffer（无 ashmem；跨进程需求为零，
  fail-closed 记录差异）。
- qo5 hash/eq 保持 `(site, timestamp)` 语义。

## 产出

- fixture `d02-builder-pool.mjs`（10 断言）。
- ADR-1044；中文报告。
