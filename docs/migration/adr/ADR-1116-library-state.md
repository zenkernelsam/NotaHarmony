# ADR-1116：data/library/state — 库状态 + 导出 + 上传

## 状态

已接受（Phase 1172）。

## 决策

- `ExportFileProvider`（`ye4` FileProvider）→ Harmony
  `fileUri` + URI 授权共享/`picker`。
- `RawLibraryStateDatabase`（Room `x5c`）→ Harmony RDB。
- `ExportSweep`/`LibraryStateUploader`（CoroutineWorker）
  → Harmony 后台任务。
- 6 异常语义保留（access-denied/not-found/retry/
  in-progress/folder-name/depth-limit）。

## 理由

`extends ye4`/`extends CoroutineWorker`/`extends x5c`/
`extends IOException` 命名类。

## 后果

库状态持久化 → RDB；导出共享 → fileUri；上传/清理 →
后台任务；深度/命名校验语义不变。
