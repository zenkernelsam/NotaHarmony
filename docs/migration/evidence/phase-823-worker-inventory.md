# Phase 823 — WorkManager 后台任务清单闭合

证据来源：`decompiled_1.0.3/1.4.2` `com.gingerlabs` 下 `*Worker.java`（CoroutineWorker
子类）；Harmony `ets/` 后台任务 API 扫描。

## 一、原版 Worker 清单（1.0.3 为 7 个 → 1.4.2 为 15 个）

### 既有 7 个（1.0.1/1.0.3 即存在）

| Worker | 职责 |
|---|---|
| LibraryStateUploaderWorker | 库状态上传（RawLibraryState outbox） |
| NoteOpsUpdaterWorker | 笔记 op 上传（NoteBundleMetadata outbox） |
| NoteAssetUploadWorker / NoteAssetDownloadWorker / NoteAssetTransferWorker | 笔记资源上传/下载/转移 |
| HandwritingPackDownloadWorker | MyScript 手写识别包下载 |
| ExportSweepWorker | 导出残留清扫（817 登记的 ExportFileProvider 配套） |

### 1.4.2 新增 8 个

| Worker | 归属集群 |
|---|---|
| BackgroundMaintenanceWorker | 后台维护（775 已登记） |
| CustomTemplateSyncWorker / TemplatePageSyncWorker | 自定义模板同步（822 CustomTemplatesDatabase） |
| GalleryMutationUploaderWorker | 画廊变更上传（822 PendingLike/PendingFollow outbox） |
| StickerPackDownloadWorker / StickerPackPrefetchWorker | 贴纸包 CDN 预取（763/775 已登记，启动时 enqueue） |
| DemoResetWorker | `app/demo` 零售演示机重置（无 UI 字符串——headless 调度器） |
| UnresolvableWorker | `core/workmanager` 兜底——不可解析工作项的无毒终结（返回 success） |

## 二、调度形态

全部为 `CoroutineWorker`（协程型 Worker），经 `k4a`（WorkerFactory 映射）
与 WorkManager 唯一工作名入队。周期性/一次性混用；`StickerPackPrefetchWorker`
在 `NbApplication` 启动链入队（channel 化下载编排器 `hwg`）。

## 三、Harmony 等价判定

Harmony 无 WorkManager 对应 API；全盘 `ets/` 仅录音使用
`backgroundTaskManager` AUDIO_RECORDING 连续任务，无 workScheduler/
reminderAgent 任务注册。

| 原版 worker 族 | Harmony 处置 |
|---|---|
| 同步上传/下载/转移 6 个 | 后端绑定——与同步层 fail-closed 集群一致（本地优先无云同步） |
| HandwritingPackDownloadWorker | MyScript 包 CDN 下载——Harmony 端识别包打包或平台引擎承担，不需要下载器 |
| CustomTemplateSync/TemplatePageSync | 模板云同步——fail-closed |
| GalleryMutationUploaderWorker | 画廊后端——fail-closed |
| StickerPack 下载/预取 | 贴纸 CDN——fail-closed（763） |
| DemoResetWorker | 零售演示——Harmony 分发形态无对应需求 |
| UnresolvableWorker | WorkManager 容错壳——平台机制不存在则无需对应物 |
| ExportSweepWorker | 导出清扫语义由 Harmony 侧临时文件生命周期吸收 |

## 四、结论

Worker 表面闭合：15 个原版 worker 全部归类——7 个既有同步型 +
8 个 1.4.2 新增全部落入已登记集群（维护/模板/画廊/贴纸/演示/容错）。
Harmony 端无对应任务注册需求，全部为后端绑定或平台机制差异，
fail-closed 一致。
