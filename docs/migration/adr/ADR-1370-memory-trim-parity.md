# ADR-1370：内存压力缓存裁剪管线（g1a/ehc → MemoryTrimRegistry + onMemoryLevel）

## 状态

Accepted — 2026-09（Phase 1435）

## 背景

原版 `NbApplication` 登记一套内存压力裁剪管线：`g1a` MemoryTrimmable
注册表 + `f1a`{BACKGROUNDED,CRITICAL} 级别 + 三枚 `ehc` trimmable
（`hhc.b` 资源解码位图缓存全清 / `dpc.e.i(-1)` 图片位图 LRU 全逐出 /
`ctc.q` 铅笔 splat 池+SharedMemory 释放）。触发门：`onTrimMemory(i)`
i≥20→BACKGROUNDED、i≥40→CRITICAL，`onLowMemory`→CRITICAL；i<20
前台压力档不裁剪。

Harmony 侧此前无任何对应：`UIAbility.onMemoryLevel` 未实现，库页
`thumbMap`（全部笔记封面 PixelMap）、编辑器 `imageAssets`（页内图
PixelMap）与 `shapeRenderer.pencilCache`（形状 splat LRU）只增不减，
低内存时无回收路径。

## 决定

移植管线（实现型 Phase）：

1. 新 `MemoryTrimRegistry.ets`：`MemoryTrimLevel`（f1a）+ token 制
   `registerMemoryTrimmable`/`unregisterMemoryTrimmable`（g1a.a）+
   `trimMemoryCaches`（g1a.b：逐回调分发、单点失败不中断、汇总 hilog）。
2. `NoteAbility.onMemoryLevel`：CRITICAL→CRITICAL、LOW→BACKGROUNDED、
   MODERATE→不动作（=原版 i<20 前台档不裁剪，避免可视帧内清缓存抖动）。
3. 三枚 trimmable 对应原版三枚：
   - `library-thumbnail-bitmaps`（LibraryPage.thumbMap ↔ hhc.b/dpc 域）
   - `editor-image-assets`（NoteCanvasView.imageAssets ↔ dpc.e）
   - `editor-pencil-splats`（NoteCanvasView.shapeRenderer.pencilCache ↔ ctc.q）

   均 `aboutToAppear` 登记、`aboutToDisappear` 注销；清后活动页触发
   重建（原版逐出后绑定期重解码等价），非活动页留空待下次显示。

## 同轴裁定：fail-closed

- `BackgroundMaintenanceWorker`（12h WorkManager 周期）+ `cs0` 预算化
  维护 pass（j=8min 总预算 / k=30s 步长 / ForegroundReturned 前台返回
  即取消）：任务贡献方为同步/存储协调器（k59/elf/dob/ag9/pj6/xnj/
  xad/fs0），SYNC 域——后端/同步边界，不实现。
- `StickerPackPrefetchWorker`：ADR-1364/1368 已裁。

## 已知差异

- 原版 `dpc.e` 带 40/80MB 容量预算的日常 LRU 逐出；Harmony 缓存无
  容量预算（仅压力全清）——日常语义差异登记。
- 原版 ctc.q 释放 SharedMemory（SDK≥34 门）；Harmony pencilCache 为
  纯 Map，无共享内存段。
- `pdfBackground` 当前页单槽位图属使用中资源，不入裁剪面（原版被
  逐出的同一张位图仍由 View 引用持有，语义一致）。

## 验证

- `d02-original-memory-trim.mjs`：17 checks 全绿。
- 全量 Replay 基线、`note@default`/`note@ohosTest` 构建：见
  `reports/phase-1435-memory-trim.md`。

## 交叉引用

- ADR-1367（ON_BACKGROUND 冲刷，同生命周期注册表模式）
- ADR-1364/1368（StickerPackPrefetchWorker 裁定）
- 证据：`phase-1435-memory-trim.md`
