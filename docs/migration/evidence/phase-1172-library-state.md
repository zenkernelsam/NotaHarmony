# Phase 1172 证据 — data/library/state（库状态持久化 + 导出 + 上传）

来源：`data/library/state/`（7 文件 + database/ + folders/）。

## 结构

- `ExportFileProvider extends ye4` = **FileProvider** —
  导出文件经 `content://` URI 共享（安卓 `FileProvider`
  跨应用文件共享）。
- `ExportSweepWorker extends CoroutineWorker` = 导出清理
  工人（扫清旧导出文件）；`b(ef2)` suspend。
- `LibraryStateUploaderWorker extends CoroutineWorker` =
  库状态上传工人。
- `database/RawLibraryStateDatabase extends x5c`（Room）+
  `_Impl` = 库状态持久化。

## 6 异常

```java
NoteAccessDeniedException  extends IOException
NoteNotFoundException      extends IOException
RetryableUploadException   extends Exception
UploadInProgressException  extends Exception
folders/InvalidFolderNameException
folders/MaxFolderDepthExceededException   // 文件夹深度限
```

## Harmony 决策

- `FileProvider`/`content://` → Harmony **`fileUri` +
  `createSharePolicy`/want 共享**（URI 授权共享）；
  或 `picker` 导出。
- Room `x5c` → Harmony **RDB**。
- 2 Worker → `BackgroundTask`/同步任务。
- `MaxFolderDepthExceeded`/`InvalidFolderName` = 库侧
  深度/命名约束 —— 语义保留。

## 产出

- fixture `d02-library-state.mjs`（10 断言）。
- ADR-1116；中文报告。
