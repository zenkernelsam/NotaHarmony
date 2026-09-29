# Phase 984 — Deferred-Ops 文件校验读 + `x63` 格式枚举 + `fsi.r` CRC32

来源：`decompiled_1.0.3/sources/defpackage/{nce,u63,x63,jwh,fsi}.java`

## 1. `u63` = deferred-ops 文件引用实体

```java
u63(long rowId, ttf noteId, short ?, x63 format, long fileSize, int crc32)
a()=crc32  b()=fileSize  c()=rowId  d()=noteId  e()=short  f()=format
```

↔ `SyncedOpMetadata` 列：`opFileSize`=e、`opsChecksum`=f、
`schemaVersion`=c(short)。

## 2. `x63` = 文件格式枚举（3 序数）

`jwh.a(MappedByteBuffer, x63)` 多态根读：

| ordinal | root | 返回 view |
|---------|------|----------|
| 0 | `r29` NoteBundle | `uae` |
| 1 | `vt9` OpsBundle | `yae` |
| 2 | `zgb` ReceiveOpsEvent | `uae` |

均 `order(LITTLE_ENDIAN)` + `d(pos+getInt(pos))` 标准根读。

## 3. `nce.A(u63, scratch)` = 校验 mmap 读

```java
FileChannel.open(path, READ);               // path = a(noteId,rowId)
size==0        → IOException("empty for row")
size!=u63.e    → IOException("size mismatch: expected e, got size")
map READ_ONLY 0..size
fsi.r(map,scratch)!=u63.f → log "checksum mismatch" + return null
NoSuchFileException → IOException("missing for row")
```

校验链：**行元数据（期望 size+crc32）→ mmap → CRC32 复算**。
checksum 失败 = fail-soft（log+null），size/empty/missing = fail-hard。

## 4. `fsi.r(ByteBuffer, byte[])` = CRC32

```java
CRC32 crc = new CRC32();
duplicate.position(0);
while (hasRemaining) { min(rem,scratch.len); get; crc.update; }
return (int) crc.getValue();   // 截取低 32 位
```

## 5. Harmony 对齐

等价语义：size+CRC32 双校验、mmap 只读、格式枚举
多态根读；checksum 失败 fail-soft（与原版一致）。

## 6. 验证

`d02-deferred-ops-file.mjs` 静态断言。
