# Phase 998 报告 — 下载/同步管线

## 范围

ko.n（增量 sync）、ko.o（整 bundle）、ko.B（流→qud）、
pcd HTTP helper、z5c.k 基址、qud 构造。纯审计。

## 原版发现

- **四端点完整闭环**：上传（append/create，Phase 997）
  + 下载（sync/bundle，本 Phase）。
- `ko.n` = downloadIncrementalOpsBundle：
  `sync?clientMaxServerTime={j}&clientOpCount={i}`。
- `ko.o` = `bundle?deviceId={je3.a}`（两处调用点）。
- `ko.B` 物化：流→`{id}.tmp`（CRC32+64KB 块）→
  空文件守卫 IOException→mmap→`qud(map,crc,len,file)`。
- 在途去重：`ConcurrentHashMap.KeySetView` +
  `o69(noteId)`；成功移除，失败 `v()` 上报
  （q93.L/K 区分 sync/bundle）。
- `z5c.k` = volatile `"https://notability.com"` 可变基址。
- `pcd` = OkHttp GET 封装（ConnectivityManager+lw8）。

## Harmony 决策

后端依赖 fail-closed；格式/守卫语义完整保留记录。

## 产出

- 证据：`phase-998-download-pipeline.md`
- Fixture：`d02-download-pipeline.mjs`（18/18）
- ADR-0942；全量 Replay 见本提交。
