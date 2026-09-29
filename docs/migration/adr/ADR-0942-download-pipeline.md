# ADR-0942 — 下载/同步管线（ko.n/o/B + pcd）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ko.n` = downloadIncrementalOpsBundle：
  GET `z5c.k + /collab-api/note/{id}/sync?
  clientMaxServerTime={j}&clientOpCount={i}`
  （`pv2.a` 串行锁 + `pcd.a` GET→InputStream）。
- `ko.o` = bundle 下载：GET `.../bundle?deviceId=`。
- `ko.B` = 流→`<dbe.b()>/{id}.tmp`（64KB 块 +
  运行 CRC32 + 8KB 缓冲）；空文件→IOException；
  mmap READ_ONLY → `qud(map,crc32,len,file)`。
- `this.M` = `o69(ttf)` 在途集合；成功 remove。
- `v(ttf,th,q93.L/K)` 错误上报（L=sync、K=bundle）。
- `z5c.k` = volatile `"https://notability.com"`。

## Harmony 决策

- 后端依赖 fail-closed（同 ADR-0941）。
- 流→tmp→CRC32→mmap 语义可平移 http.fs；
  空文件守卫与 CRC 保留。

## Parity 状态

fail-closed（无服务器）；格式与守卫完整记录。

## 验证

- `d02-download-pipeline.mjs`：18/18 通过。
