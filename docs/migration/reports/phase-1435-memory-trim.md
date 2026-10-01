# Phase 1435 — 内存压力缓存裁剪管线 + 后台维护轴裁定

## 范围

`NbApplication.onCreate` 尾部复查发现两条此前未裁轴：

1. **内存压力缓存裁剪**：`g1a`/`f1a`/`h1a`/`ehc` 管线 —— Harmony 完全
   缺失，实现型差距。
2. **周期后台维护**：`BackgroundMaintenanceWorker`（12h）+ `cs0`
   预算化 pass —— 同步/后端域，fail-closed。

## 原版证据要点

- `f1a`={BACKGROUNDED,CRITICAL}；`h1a`=单回调接口；`g1a`=注册表，
  `b(level)` 逐 trimmable 分发、失败隔离、汇总日志。
- `onTrimMemory`：i≥20→BACKGROUNDED、i≥40→CRITICAL；`onLowMemory`
  →CRITICAL；i<20 前台档不裁剪。
- 三枚 `ehc`：`hhc.b.clear()`（资源解码位图）、`dpc.e.i(-1)`（图片
  LRU 全逐出）、`ctc.q`（铅笔 splat 池+SharedMemory）——均全清，
  级别参数不进缓存逻辑。
- `cs0`：预算化编排（8min/30s/3min/5s 四级预算），任务来自
  同步/存储协调器，前台返回即取消（ForegroundReturned），
  SYNC 日志域。

## Harmony 实现

- 新 `data/MemoryTrimRegistry.ets`：级别枚举 + token 登记/注销 +
  失败隔离分发。
- `NoteAbility.onMemoryLevel`：CRITICAL→CRITICAL、LOW→BACKGROUNDED、
  MODERATE→不动作（对齐原版 i<20 不裁剪）。
- 三枚 trimmable：
  - `LibraryPage` `library-thumbnail-bitmaps`：`thumbMap` 全清 +
    `thumbnailGeneration++`；`pageActive` 时重建。
  - `NoteCanvasView` `editor-image-assets`：`releaseImageAssets()` +
    `lifecycleActive` 时 `refreshImageAssets` 重载。
  - `NoteCanvasView` `editor-pencil-splats`：`shapeRenderer.clearPencilCache()`。
- 生命周期：`aboutToAppear` 登记、`aboutToDisappear` 注销（P1432
  `EditorLifecycleFlush` 同模式）。

## 裁定

- `BackgroundMaintenanceWorker`/`cs0`（预算化周期维护、SYNC 域、
  前台返回取消）：同步/后端边界，**fail-closed**。
- `StickerPackPrefetchWorker`：ADR-1364/1368 已裁，不重复。

## 交付物

- `data/MemoryTrimRegistry.ets`（新）
- `noteability/NoteAbility.ets`（onMemoryLevel）
- `ui/library/LibraryPage.ets`（thumbnail trimmable）
- `ui/editor/NoteCanvasView.ets`（image-assets + pencil-splats trimmable）
- 证据 `phase-1435-memory-trim.md`、ADR-1370、本报告
- Replay `d02-original-memory-trim.mjs`（17 checks）

## 验证

- 专项 fixture：17/17。
- 全量 Replay：1286/1286（1285+1）。
- `note@default` / `note@ohosTest` clean 构建成功。

## 差异登记

- `dpc.e` 容量预算 LRU（40/80MB）日常逐出未移植——Harmony 仅压力
  全清（无预算驱动的日常逐出）。
- `ctc.q` SharedMemory 释放无对应（Harmony pencilCache 纯 Map）。
- `pdfBackground` 使用中位图不入裁剪面（原版引用持有语义一致）。
