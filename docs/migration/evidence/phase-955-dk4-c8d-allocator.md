# Phase 955 — `dk4`/`c8d`：池化 FlatBuffer 构建器 + ashmem 分配器

来源：`decompiled_1.0.3/sources/defpackage/dk4.java`、`c8d.java`、
`k1a.java`、`ldj.java`、`ck4.java`

## 1. `dk4.a(c8d) → a` — 池化 builder 工厂

```
fl6[] a = {"FB_BYTE_BUFFER_HOLDER" → ByteBuffer}  // 池属性
cz8 b = new cz8(ra(28), ck4.P);                   // 池(工厂,重置λ)
a(c8d):
  ByteBuffer bb = x82.x(b, a[0]);   // acquire
  return new a(c8dVar, bb);         // builder(allocator, 初始BB)
```

- `ra(28)` = ByteBuffer.allocate 工厂λ（合并类 case 28）
- `ck4.P` = `ByteBuffer::clear` 方法引用——**归还时 clear 复用**

每个序列化工厂（`vej.a`、`rh8.b`、`ys2.d`、o0j.a 等）首句
`dk4.a(c8dVar)` = 池化拿初始缓冲；尾部 `rh8.q(c8d,null)` 归还。

## 2. `c8d extends ldj implements AutoCloseable` — SharedMemory 分配器

FlatBuffers `ldj`（ByteBufferFactory）的 Android 特化：

```java
ArrayList R = k1a{ByteBuffer, SharedMemory} 追踪表;

l2(i):  // newByteBuffer 覆写 —— builder 扩容回调
  shm = SharedMemory.create("fbb-shm", i);
  bb  = shm.mapReadWrite().order(LITTLE_ENDIAN);
  R.add(k1a(bb, shm));  return bb;
  // ErrnoException → IOException("SharedMemory.mapReadWrite/create
  //    failed for capacity=")

v2(bb):  // releaseByteBuffer 覆写
  找 k1a → SharedMemory.unmap(bb) + shm.close() + R.remove

close(): R 全量 unmap+close+clear
```

**关键事实：原版笔记的 FlatBuffer 序列化直接写入 ashmem
（`"fbb-shm"` SharedMemory 段）**，而非堆 ByteBuffer——大型笔记
构建走共享内存，段生命周期由 `R` 追踪 + AutoCloseable 兜底。

## 3. 角色分工

- `dk4.b` 池复用**初始** ByteBuffer（小，clear 复用）
- `c8d.l2` 处理**扩容**（builder 满时 newByteBuffer 回调 → ashmem）
- `k1a` = (BB, shm) 追踪对；`ldj` = 抽象分配器基类（含静态归并）

## 4. Harmony 决策

`SharedMemory`/ashmem 无 ArkTS 对应物；Harmony FlatBuffer 构建器
写普通 ByteBuffer。**分配器是内存管理细节，非线格式**——
序列化字节逐位一致；共享内存为零拷贝/大内存优化。

**平台委托**：Harmony 用 ArrayBuffer；若未来需跨进程共享笔记
缓冲，可评估 Harmony `SharedArrayBuffer`+锁或 ohos 共享内存
NDK，但线协议层无差异。

## 5. 验证

- `d02-dk4-c8d-allocator.mjs` 静态断言。
