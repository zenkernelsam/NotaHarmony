# Phase 1161 证据 — data/note Room + Worker + 同步异常层

来源：`data/note/` 命名类。

## `data/note/assets/` = 资产 Room + WorkManager

- `NoteAssetDatabase extends x5c` = Room `@Database`
  （`x5c`=obf `RoomDatabase`）；`u()→g19` DAO；
  `NoteAssetDatabase_Impl` = Room 生成实现。
- `NoteAssetDownloadWorker`/`UploadWorker`/`TransferWorker`
  = `androidx.work` 资产上/下载 + 抽象基（`p29` 仓储）。

## `data/note/ops/` = op bundle 元数据 Room + 同步异常

- `NoteBundleMetadataDatabase`：3 DAO `u/v/w()`
  （`kq1`/`w63`/`hl3`）+ `_Impl`。
- `synced/` 异常分类：
  `AccessDeniedException`(q93,p93,String)、
  `CorruptedSyncedOpException`、`NoteHasNoOpsException`、
  `NoteOpsNotFoundException`、`StaleSyncedNoteException`
  —— 同步失败语义。

## `data/note/state/`

`NoteStateDatabase` + `_Impl` —— 笔记 UI 态 Room。

## 语义

`data/note` = 笔记持久层：
- Room `@Database`（`x5c`）×3 + 生成 `_Impl` + DAO。
- `androidx.work` 资产传输 Worker。
- 同步异常分类（权限/损坏/无 op/未找到/陈旧）。

## Harmony 决策

- Room → `@ohos.data.relationalStore` + 手写 DAO；
  `_Impl` 由 Harmony 手写（无 Room codegen）。
- WorkManager → `@ohos.work.scheduler` / 后台任务。
- 同步异常语义保（同名异常类 + 字段）。

## 产出

- fixture `d02-note-repo.mjs`（10 断言）。
- ADR-1105；中文报告。
