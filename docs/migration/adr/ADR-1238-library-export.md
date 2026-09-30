# ADR-1238：库导出/上传 + 文件夹规则

## 状态

已接受（Phase 1294）。

## 决策

FileProvider → Harmony `fileShare`/`FileUri`+`ShareExtension`；
Worker → `WorkScheduler`；文件夹名/深度约束保留。

## 理由

`ExportFileProvider`(ye4=FileProvider) 喂 `exports/`
URI+OnClose 回收；`ExportSweepWorker`/`LibraryState
UploaderWorker`；`InvalidFolderName`/`MaxFolderDepth`
文件夹约束 —— 库同步+导出管线。

## 后果

Harmony 库导出 = fileShare+WorkScheduler —— 导出/
上传/文件夹语义保真。
