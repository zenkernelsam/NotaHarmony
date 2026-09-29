# Phase 998 证据 — 下载/同步管线（ko.n/o/B + pcd + z5c.k）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ko`（mega-merge，implements fo0/ald/ba4/svb/cwf/da4）

下载相关成员：

- `Object n(ttf noteId, long j, int i, ff2)` =
  **downloadIncrementalOpsBundle** 协程。
- `Object o(ttf noteId, ff2)` = 整 bundle 下载协程。
- `qud B(ttf, InputStream)` = 流→mmap blob 物化。
- `this.M` = `ConcurrentHashMap.KeySetView` 在途集合，
  元素 `o69(ttf)`；成功后 `remove`。
- `v(ttf, Throwable, q93)` 错误上报；
  `q93.L`=sync 失败、`q93.K`=bundle 失败。

## 下载 URL（手工拼接，非 Retrofit）

- sync：`z5c.k + "/collab-api/note/" + noteId
  + "/sync?clientMaxServerTime=" + njj.j0(10, j)
  + "&clientOpCount=" + i`（`ko.n` 行 ~729-741）。
- bundle：`z5c.k + "/collab-api/note/" + noteId
  + "/bundle?deviceId=" + je3.a`（行 812/849 两处）。
- `z5c.k` = `volatile String = "https://notability.com"`
  （可配置基址）。

## `pcd` HTTP GET helper

```java
final class pcd { ConnectivityManager a; lw8 b; vs4 c; dt4 d }
Object a(pcd, String url, ff2, int mask) // GET→InputStream
Object b(String url, long, long, long, ff2) // 参数化变体
```

- `lw8` = okhttp3.OkHttpClient；`vs4`/`dt4` =
  dispatcher/计量器。

## `ko.B(ttf, InputStream) → qud`（核心物化）

1. `File = dbe.b()/<noteId>.tmp`；`fsi.z` 建父目录。
2. CRC32 + BufferedOutputStream(8192) +
   `byte[65536]` 循环：stream→文件 + 同步 CRC。
3. 中途异常 → `file.delete()` 重抛。
4. `length==0` → 删文件 + `SERVER_PERSISTENCE` 记
   "Server returned empty ops bundle" + IOException。
5. `FileChannel.open(READ)` → `map(READ_ONLY,0,length)`
   → `new qud(map, (int)crc32.getValue(), length, file)`。

`qud extends zac` 构造：`qud(MappedByteBuffer, int crc32,
long length, File)`——下载 blob 自带 CRC32 校验值。

## 与上传管线对接

```
GET /sync?clientMaxServerTime&clientOpCount → pcd.a
  → InputStream → ko.B → qud(MBE, crc32, len, .tmp)
  → 后续同 Phase 979/984 的 uhj.n/uae/lv2.T 链
GET /bundle?deviceId → 同上（q93.K 通道）
成功后 this.M.remove(o69(noteId))
```

## HarmonyOS 决策

- 与上传管线同：后端依赖 fail-closed。
- `ko.B` 的「流→临时文件→CRC32→mmap→qud」语义可
  平移到 `@ohos.net.http` 流式下载 +
  `@ohos.file.fs` mmap/随机读；CRC32+空文件守卫
  应原样保留。

## 产出

- fixture `d02-download-pipeline.mjs`（18 断言）。
- ADR-0942；中文报告。
