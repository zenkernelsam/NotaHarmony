# Phase 1016 报告 — WorkManager 售卖 schema + worker 名册

## 范围

六张 androidx.work impl_db 表 + 4 个 app worker。
纯审计 —— 关闭 Room DDL 盘点。

## 原版发现

- WorkSpec ~30 列（WorkManager 2.9+ spec）+ Tag/
  Name/Progress/SystemIdInfo/Dependency 五副表
  全 FK CASCADE→WorkSpec；无应用数据。
- worker 名册：`NoteOpsUpdaterWorker`（ops 上传）、
  `ExtractionWorker`（索引抽取）、`ExportSweepWorker`、
  `HandwritingPackDownloadWorker`。

## Harmony 决策

库表不平移；worker 语义以 Harmony
WORK_SCHEDULER/TASK_GROUP 等价；语言包 fail-closed。

## 产出

- 证据：`phase-1016-workmanager-schema.md`
- Fixture：`d02-workmanager-schema.mjs`（9/9）
- ADR-0960；**39 表 DDL 盘点完成（33 app+6 vendored）**。
