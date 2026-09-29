# ADR-0943 — 同步编排器（nr1 / wq1 / q93 / pzb-ozb）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `nr1` = 同步引擎：deps `{oq1 上传, nce 同步库,
  ssf, qr1, jl3, sxa, v2f}`；三条 Room
  InvalidationTracker 共享 Flow（`ys2.r`+`cq.u0`
  shareIn replay=1）watch ClientOp/{ClientOp,
  DraftNote}；`em8` Mutex×2 + LinkedHashMap 在途 +
  `bsd.a(0)` 信号量。
- `nr1.a`：op→`zp1` 实体 + `l96.L0` withTransaction。
- `nr1.b`：Mutex 串行 WAL 消费 + `File.delete`。
- `q93` = {CREATE, APPEND, BUNDLE_DOWNLOAD,
  SYNC_DOWNLOAD} 错误类目。
- `pzb`/`ozb` = Kotlin Result/Failure；
  `pzb.a`=exceptionOrNull。
- `wq1` = Dagger Provider。

## Harmony 决策

编排逻辑平移到 relationalStore dataChange + ArkTS
并发原语；网络端点 fail-closed。

## Parity 状态

fail-closed（同步服务器缺失）。

## 验证

- `d02-sync-orchestrator.mjs`：16/16 通过。
