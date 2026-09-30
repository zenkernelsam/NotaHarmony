# Phase 1294 证据 — library/state 导出/上传+文件夹规则

来源：`data/library/state/*`。

## `ExportFileProvider extends ye4`（FileProvider）

```java
openFile(Uri,"r") {
    pathSegments[0]=="exports" → ParcelFileDescriptor.open
    + wrap(fd, handler, OnCloseListener)  // 关闭回收跟踪
    // "Could not reclaim export descriptor"
}
```

→ **导出文件 ContentProvider** —— `content://…/exports/*`
喂分享/保存；`OnCloseListener` 跟踪描述符回收。

## `ExportSweepWorker` = 导出清理 Worker（扫过期导出）。

## `LibraryStateUploaderWorker` = 库结构上传 Worker
（folders+notes 元数据→云端）。

## `folders/` = 文件夹规则

`InvalidFolderNameException` + `MaxFolderDepthExceeded
Exception` —— 文件夹命名校验+最大嵌套深度。

## `RawLibraryStateDatabase`（Room）= 原始库状态 DB。

## 异常

`NoteAccessDenied`/`NoteNotFound`/`RetryableUpload`/
`UploadInProgress` —— 上传并发/重试语义。

## 语义

**库状态同步+导出** —— FileProvider 喂导出文件 +
Worker 上传库结构+清理导出 + 文件夹名/深度约束 —
— 库结构同步与分享导出管线。

## Harmony 决策

FileProvider → Harmony `fileShare`/`FileUri`+`ShareExtension`；
Worker → `WorkScheduler`；文件夹约束保留 ——
导出/上传语义保真。

## 产出

- fixture `d02-library-export.mjs`（10 断言）。
- ADR-1238；中文报告。
