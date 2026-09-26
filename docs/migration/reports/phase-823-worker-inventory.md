# Phase 823 — WorkManager 后台任务清单闭合

## 范围

原版 `*Worker.java` 全量清单 + 版本差分 + Harmony 后台任务等价核验。

## 原版证据

### 版本差（7 → 15）

1.0.1/1.0.3 既有 7 个均为同步/资源型：LibraryStateUploader、NoteOpsUpdater、
NoteAssetUpload/Download/Transfer、HandwritingPackDownload、ExportSweep。

1.4.2 新增 8 个，全部落入已登记集群：

- `BackgroundMaintenanceWorker`（775 后台维护）
- `CustomTemplateSyncWorker`/`TemplatePageSyncWorker`（822 模板库配套）
- `GalleryMutationUploaderWorker`（822 PendingLike/PendingFollow outbox 配套）
- `StickerPackDownloadWorker`/`StickerPackPrefetchWorker`（763/775 贴纸 CDN）
- `DemoResetWorker`（`app/demo` 零售演示机重置——无 UI，headless）
- `UnresolvableWorker`（`core/workmanager` 容错终结器，返回 success）

全部 CoroutineWorker，经 `k4a` WorkerFactory 映射入队。

## Harmony 核验

`ets/` 全量扫描：无 workScheduler/reminderAgent 注册；仅录音
AUDIO_RECORDING 连续任务（820 已登记）。15 个 worker 全部为
后端绑定（同步/上传/CDN）或平台机制特有（容错壳/演示重置），
Harmony 无对应注册需求——fail-closed 一致。

## 交付物

- 证据：`docs/migration/evidence/phase-823-worker-inventory.md`
- ADR：`docs/migration/adr/ADR-0767-worker-inventory.md`
- Replay：`docs/migration/replays/d02-worker-inventory.mjs`（9 项断言）

## 验证

- 新增 Replay：9/9 一次通过。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

后台调度面闭合。候选轴：broadcast receiver 清单（AppUpgradeReceiver
MY_PACKAGE_REPLACED 等已见）、Service 声明明细、或 baseline.prof
热点方法抽样。
