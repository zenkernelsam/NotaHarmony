# ADR-1106：data/library 库仓储

## 状态

已接受（Phase 1162）。

## 决策

- `RawLibraryStateDatabase`（Room）→ relationalStore +
  手写 DAO；`ExportFileProvider`（`ye4`）→ Harmony
  fileshare；Workers → `@ohos.work.scheduler`。
- 7 域异常（InvalidFolderName/MaxFolderDepthExceeded/
  NoteAccessDenied/NoteNotFound/MissingAssets/
  RetryableUpload/UploadInProgress）语义保。

## 依据

命名 `data/library/` Room/Worker/FileProvider/异常类。

## 后果

Harmony：库态 relationalStore + 导出 fileshare + 后台
Worker + 同名域异常（深限/权限/上传态）。
