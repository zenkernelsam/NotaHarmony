# Phase 985 — Defer 写路径：schema 门控 + 原子文件+行提交

来源：`decompiled_1.0.3/sources/defpackage/{nce,crb,w63,ebe,fsi}.java`

## 1. `nce.g(ttf,zae,z,…)` = synced-op ingest 门控

```java
if (ba6.w(zae.b() & 0xFFFF, rgc.a & 0xFFFF) > 0) {
    // 文件 schema > 本端 → 不物化，转存 defer
    ByteBuffer blob = zae.c();
    long size = blob.limit();
    if (size <= 0) → "Cannot defer empty blob" 返回 null
    u(ttf, zae, size, fsi.r(blob, 64K-scratch), null,
      new crb(blob, 17)/*文件写λ*/, coroutine)
    return ebe.I   // SUCCESS
} else {
    // schema ≤ 本端 → 物化 ops + Room 事务(pv2.c)
    // + b()/c() 后处理；hnb.I 标记 → ebe.J
}
```

**比本端新的笔记只存原 blob + 元数据行，绝不本地物化**
——前向兼容的核心机制。

## 2. `nce.u` = 原子 defer 提交

```java
x63 fmt = zae.a();
if (fmt == null) throw IllegalStateException(
    "Should be impossible: " + ymf.a(schema) + " > " + ymf.a(rgc.a));
pv2.c(this.d, new hce(pae, this, ttf, zae, fmt, size, crc32, writer, null))
// Room 事务内：文件写 + SyncedOpMetadata 行插入
log "Deferred ops for note" {note.id,new.schema,current.schema}
```

## 3. `crb` case 17 = blob 文件写λ

```java
fsi.z(file);  // 确保父目录
FileChannel.open(path, WRITE, CREATE_NEW);  // ★排他创建
duplicate.position(0); while(hasRemaining) write(buf);
```

**CREATE_NEW** = 已存在即 FileAlreadyExistsException
（覆盖保护）；`fsi.z` 仅 mkdirs 父目录。

## 4. `crb` case 18 = qud 下载落盘

`fag.m0(qud.M, target)` 原子改名 + `qud.N=true`
（"StreamedDownload already moved" 防二次移动）。

## 5. `w63.a(String)` = x63 枚举转换器

`"NOTE_BUNDLE"→I` `"OPS_BUNDLE"→J`
`"RECEIVE_OPS_EVENT"→K`，未知→`o14.r` 抛错。
SyncedOpMetadata 的格式列存**枚举名**。

## 6. `ebe` = ingest 结果枚举

`SUCCESS=0` / `CORRUPT_NEEDS_REDOWNLOAD=1`
（hnb.I 标记路径返回 J → 上层重新下载）。

## 7. Harmony 对齐

等价：schema 门控 defer + CREATE_NEW 排他写 +
事务内文件+行原子提交 + CRC32/size 入库。

## 8. 验证

`d02-defer-write-path.mjs` 静态断言。
