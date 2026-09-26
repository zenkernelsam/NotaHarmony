# Phase 845 — Worker + DataStore Initializer 清单闭合

证据：`decompiled_1.4.2` 全包 `*Worker`/`*Initializer` 盘点。

## 一、WorkManager Worker 清单（15 类；12 直系 CoroutineWorker，
NoteAsset Download/Upload 继承 `NoteAssetTransferWorker` 基类，
`UnresolvableWorker` 为普通 Worker 占位桩）

| Worker | 域 | 状态 |
|--------|-----|------|
| BackgroundMaintenanceWorker | 12h 周期维护（828） | fail-closed（无 WorkManager） |
| DemoResetWorker | 零售演示重置（返回 Result.success 桩） | fail-closed |
| GalleryMutationUploaderWorker | gallery outbox 上传 | fail-closed（后端） |
| HandwritingPackDownloadWorker | MyScript 语言包下载 | fail-closed（Play AssetDelivery） |
| ExportSweepWorker | 导出临时文件清扫 | 本地可移植（未实现，登记） |
| LibraryStateUploaderWorker | 库状态上传 | fail-closed（后端） |
| NoteOpsUpdaterWorker | 笔记 ops 拉取 | fail-closed（sync） |
| NoteAssetDownload/Transfer/UploadWorker ×3 | 笔记资产管线 | fail-closed（sync/后端） |
| TemplatePageSyncWorker | 模板页同步 | fail-closed（sync） |
| CustomTemplateSyncWorker | 自定义模板同步 | fail-closed（sync） |
| StickerPackDownload/PrefetchWorker ×2 | 贴纸包获取（783） | fail-closed（后端） |
| UnresolvableWorker | DI 解析失败占位（`return success`） | 平台构造 |

约束在混淆调用方（enqueue 站点不可读），类型面完整。

## 二、Initializer 清单（6 类）

DataStore 域：`UserDataStoreInitializer`（core/user）、
`ThemeDataStoreInitializer`、`NoteEditorSettingsInitializer`、
`HapticPreferencesInitializer`；
androidx.startup 域（836）：`AppStartupInitializer`、
`LoggingInitializer`。

→ Harmony 对应面：`ThemeStore.init()`（NoteAbility onCreate）、
`EditorSettingsStore`/`OriginalPaperSettingsStore` 等 DataStore-
preferences 惰性装载——初始化时机差异已文档化（828）。

## 三、Harmony 后台执行面

- `backgroundTaskManager` 连续任务（AUDIO_RECORDING，834）；
- 无 `workScheduler`/`transientTask` 使用——一次性/周期后台
  域无对等实现，全部 fail-closed 登记。

## 四、结论

Worker×15 + Initializer×6 全归因；仅 ExportSweep 属本地
可移植但登记为未实现（低价值清杂）。后台调度面闭合。
