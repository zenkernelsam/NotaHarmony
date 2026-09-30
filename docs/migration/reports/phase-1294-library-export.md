# Phase 1294 报告 — 库导出/上传 + 文件夹规则

## 完成内容

- `ExportFileProvider`（ye4=FileProvider，`exports/`
  URI+ParcelFileDescriptor+OnClose 回收跟踪）；
  `ExportSweepWorker`/`LibraryStateUploaderWorker`；
  `folders/InvalidFolderName`+`MaxFolderDepthExceeded`；
  `RawLibraryStateDatabase`+AccessDenied/Retryable/
  UploadInProgress —— 库结构同步+导出+文件夹约束。

## 产出

- evidence `phase-1294-library-export.md`
- fixture `d02-library-export.mjs`（10/10）
- ADR-1238
