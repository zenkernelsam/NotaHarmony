# Phase 1162 证据 — data/library 库仓储 + Worker + 域异常

来源：`data/library/` 命名类。

## `state/database/` = 库态 Room

`RawLibraryStateDatabase extends x5c`（Room `x5c`基）——
3 DAO `u()→jp1`/`v()→xp1`/`w()→n78` + `_Impl` 生成。

## `state/` Workers + FileProvider

- `ExportFileProvider extends ye4` = 导出 `FileProvider`
  （`ye4`=obf androidx FileProvider）。
- `ExportSweepWorker extends CoroutineWorker` = 导出清理
  （`g64` 导出仓储）。
- `LibraryStateUploaderWorker` = 库态上传。
- `notes/NoteOpsUpdaterWorker` = 笔记 op 更新。

## 域异常分类

- `folders/InvalidFolderNameException`（名非法）
- `folders/MaxFolderDepthExceededException(int)`（深超限）
- `NoteAccessDeniedException`（无权限）
- `NoteNotFoundException`（未找到）
- `ntb/MissingAssetsException`（ntb 缺资产）
- `RetryableUploadException`（可重试上传）
- `UploadInProgressException`（上传中）

## 语义

`data/library` = 库（笔记列表/文件夹）持久 + 导出 +
同步：Room 库态 + androidx.work 上传/清理 +
FileProvider 导出 + 7 域异常。

## Harmony 决策

- 库态 Room → relationalStore + 手写 DAO；
  Workers → `@ohos.work.scheduler`。
- FileProvider → Harmony `fileshare`/`FileUri`。
- 域异常语义保（同名 + 深度限 `MaxFolderDepthExceeded`）。

## 产出

- fixture `d02-library-repo.mjs`（10 断言）。
- ADR-1106；中文报告。
