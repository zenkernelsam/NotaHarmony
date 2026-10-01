# Phase 1435 — 内存压力缓存裁剪管线对齐 + 后台维护轴裁定

## 原版证据（decompiled_1.4.2）

### 裁剪注册表与级别

- `f1a.java`：级别枚举 `{BACKGROUNDED, CRITICAL}`。
- `h1a.java`：`MemoryTrimmable` 接口（`void a(f1a)`）。
- `g1a.java`：注册表——`a(h1a)` 登记进 `ConcurrentHashMap.KeySetView`；
  `b(f1a)` 遍历分发：单 trimmable 抛错不中断其余，收集异常后置日志
  （"MemoryTrimmable failed"），`Error`/`CancellationException` 上抛。
  分发前记 "Memory trim (<level>): releasing caches"。

### 触发门（NbApplication）

```java
onTrimMemory(i):  i>=40 → b(CRITICAL);  i>=20 → b(BACKGROUNDED)
onLowMemory():    → b(CRITICAL)
```

Android `i<20`（TRIM_MEMORY_RUNNING_MODERATE/LOW/CRITICAL，前台压力）
不触发裁剪 —— 原版只在 UI 隐藏/后台/系统级低内存时清缓存。

### 三枚 trimmable（`ehc` 合成类按 byte 分派，均忽略级别参数 = 全清）

| ehc | 动作 | 缓存 |
|-----|------|------|
| `ehc(0)` | `hhc.b.clear()` | 资源解码位图缓存（ConcurrentHashMap） |
| `ehc(1)` | `dpc.e.i(-1)` | 图片位图 LRU（`q01`，容量降到 -1 全逐出；
`dpc.e` 预算 41943040/83886080 按 `l24.a` 设备档） |
| `ehc(2)` | `ctc.q` | 铅笔 splat 渲染：`ctc.m`（SharedMemory/bv6，
SDK≥34）置空 + `ctc.o` 池排空（`ctc.p` 计数递减） |

登记点：`NbApplication.onCreate` 尾部 `g1aVar.a(dpc.c / hhc.c / ctc.q)`。

### 同轴：周期后台维护 —— fail-closed

- `BackgroundMaintenanceWorker`：WorkManager `enqueueUniquePeriodic`，
  12h 周期 + 4h flex；`cs0` 预算化 pass 编排（`hli` 时钟 / `fli` 预算
  j=8min,k=30s,l=3min,m=5s；`kq9` STOPPED/BUDGET_EXCEEDED）；
  `ForegroundReturned` CancellationException——前台返回即取消。
- 任务贡献方为 `k59/elf/dob/ag9/pj6/xnj/xad/fs0` 同步/存储协调器
  （SYNC 日志域；`dob` 为带 30s/30min 超时的同步状态机、`xad` 为
  连通性流、`fs0` 为前台标志流）——后端/同步域，维持 fail-closed。
- `StickerPackPrefetchWorker`：同启动段登记，贴纸轴 ADR-1364/1368
  已裁（InternalUserOnly + 无 asset-delivery 通路）。

## Harmony 实现

### 新增 `note/src/main/ets/data/MemoryTrimRegistry.ets`

- `MemoryTrimLevel { BACKGROUNDED, CRITICAL }`（f1a 端口）。
- `registerMemoryTrimmable(name, callback): token` /
  `unregisterMemoryTrimmable(token)`（g1a.a/注销）。
- `trimMemoryCaches(level)`：`forEach` 分发，单点 try/catch + hilog
  （g1a.b 失败隔离等价），先记 "Memory trim (level): releasing N caches"。

### `NoteAbility.onMemoryLevel`

```ts
MEMORY_LEVEL_CRITICAL(2) → trimMemoryCaches(CRITICAL)
MEMORY_LEVEL_LOW(1)      → trimMemoryCaches(BACKGROUNDED)
MEMORY_LEVEL_MODERATE(0) → 不动作（= 原版 i<20 前台压力不裁剪）
```

### 三枚 trimmable（对应原版三枚）

| 原版 | Harmony | 行为 |
|------|---------|------|
| `ehc(0)` hhc.b 资源解码缓存 | `LibraryPage` `library-thumbnail-bitmaps` | `thumbnailGeneration++` + 全量 release PixelMap + 清 `thumbMap`/`thumbRevisions`；`pageActive` 时 `refreshThumbnails()` 重建（原版逐出后下次绑定重解码等价） |
| `ehc(1)` dpc.e 图片 LRU | `NoteCanvasView` `editor-image-assets` | `releaseImageAssets()`（release+gen++）；`lifecycleActive` 时 `refreshImageAssets` 重载，非活动留待页面加载路径 |
| `ehc(2)` ctc.q 铅笔 splat 池 | `NoteCanvasView` `editor-pencil-splats` | `shapeRenderer.clearPencilCache()`（`pencilCache` LRU 清空） |

登记/注销：两组件 `aboutToAppear` 登记、`aboutToDisappear` 注销
（同 P1432 `EditorLifecycleFlush` 生命周期模式）。

## 已知差异登记

- 原版 `dpc.e` 是带容量预算的 LRU（40/80MB 设备档），日常逐出由预算
  驱动、压力事件清到 -1；Harmony `imageAssets`/`thumbMap` 无容量预算
  （仅压力全清）——日常 LRU 语义差异登记，压力路径等价。
- 原版 `ctc.q` 还释放 `SharedMemory`（SDK≥34）；Harmony
  `pencilCache` 是纯 Map 条目（无共享内存段），清 Map 即等价。
- 原版 PDF 页位图走 `dpc` LRU（压力时含当前页位图逐出——引用仍在
  由 View 侧持有故可视页不受影响）；Harmony `pdfBackground` 为单槽
  当前页字段（使用中），不在裁剪面——下次换页路径自带释放。
- `cs0`/`BackgroundMaintenanceWorker`（12h 预算化维护 pass，
  前台返回即取消）= 同步/后端域，fail-closed 不实现。

## 验证

- 新增 Replay：`d02-original-memory-trim.mjs`（17 checks）。
- 全量基线、`note@default`、`note@ohosTest`：见 Report/提交。
