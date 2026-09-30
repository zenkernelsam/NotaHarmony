# Phase 1283 证据 — com.gingerlabs.notability 数据层普查

来源：`com/gingerlabs/notability/`（122 文件，非混淆
真实包名）。

## 数据层（Room DB + 同步 + 特性）

```
data/note/assets/    NoteAssetDatabase + Download/
                     Transfer/Upload Worker  ← 资产同步
data/note/ops/database/  NoteBundleMetadataDatabase
data/note/ops/synced/    ← CRDT 同步冲突：
  AccessDenied / CorruptedSyncedOp / NoteHasNoOps /
  NoteOpsNotFound / StaleSyncedNote
data/note/state/     NoteStateDatabase
data/library/state/  LibraryStateUploader + database +
                     folders/notes/ntb（.ntb 笔记格式+
                     MissingAssets）
data/learn/          LearnDatabase + LearnError（学习）
data/search/         SearchDatabase + SearchIndexDatabase
                     + AppSearch SearchResult（FTS 索引）
data/transcription/  LiveTranscriptionHttpException +
                     upload/GCSUploadException → GCS
                     （实时转写→Google Cloud Storage）
data/settings/ data/toolbar/ToolboxDatabase data/theme/
data/billing/ + data/samsungbilling/   Play+Samsung IAP
domain/subscription/ Purchase/Restore/SamsungIap 异常
```

## core/ 基础设施

```
core/analytics/NbPerformance        // 性能 span
core/common/logging/NbLog           // 日志（FatalLogError）
core/common/memory/SharedMemoryByteArena  // 共享内存
core/flatbuffers/ValidationException
core/glmath/GLMathNative + GLMathTextMeasurer + MathDrawTarget
                                    // 数学公式 GL 渲染！
core/model/CopyPasteException
core/network/HttpStatus/NoConnectivity/NotAuthenticated
core/retrofit/HttpFailureException   // Retrofit REST
core/user/UserDataStoreInitializer
```

## app/ 壳

`MainActivity`/`NbApplication`/`MissingNativeLibraryActivity`/
`AppUpgradeReceiver` + `app/widgets/`×5（CreateNote/
CreateRecording/FolderNotes/NoteThumbnail/RecentNotes
桌面 widget）+ `initializers/`。

## 语义

**完整数据层架构** —— Room 数据库群（笔记状态/资产/
学习/搜索索引/设置/工具箱/转写）+ CRDT 同步冲突异常
+ 资产上传/下载 Worker + 转写→GCS + 双 IAP + Retrofit
REST + 共享内存 + GL 数学渲染 + 桌面 widget。

## Harmony 决策

Room → `relationalStore`/preferences；Worker → `WorkScheduler`；
Retrofit → `rcp`/`http`；widget → FormExtensionAbility；
GCS/billing → fail-closed —— 数据层语义映射。

## 产出

- fixture `d02-data-layer.mjs`（10 断言）。
- ADR-1227；中文报告。
