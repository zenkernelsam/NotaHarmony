# ADR-0960 — WorkManager vendored schema + worker 名册

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 六张 androidx.work impl_db 表（WorkSpec ~30 列
  2.9+ spec + Tag/Name/Progress/SystemIdInfo/
  Dependency，全 FK CASCADE→WorkSpec）——
  库内部，无应用数据。
- 4 个 app worker：`NoteOpsUpdaterWorker`（ops
  上传）、`ExtractionWorker`（索引抽取）、
  `ExportSweepWorker`、`HandwritingPackDownloadWorker`。

## Harmony 决策

- **WorkManager 表不平移**——以 Harmony
  `WORK_SCHEDULER`/`TASK_GROUP` 等价调度。
- ops 上传/抽取/导出清扫保留语义；手写语言包
  fail-closed（服务端资产分发）。

## Parity 状态

调度语义等价；WorkManager 库表不迁移（库内部）。

## 验证

- `d02-workmanager-schema.mjs`：9/9 通过。
- **至此 39 张 DDL 全表盘点完毕（33 app + 6 vendored）。**
