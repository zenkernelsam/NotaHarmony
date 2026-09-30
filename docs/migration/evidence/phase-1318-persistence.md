# Phase 1318 证据 — Harmony 持久化层（RdbStore）

来源：`data/DatabaseManager.ets` + `*RepositoryImpl` +
`*Store` + `OpStoreImpl`。

## `DatabaseManager` = `relationalStore.RdbStore`

```
relationalStore.getRdbStore(context, {
  securityLevel: S1 })
PRAGMA foreign_keys = OFF/ON（迁移期）
executeSql(DDL/INSERT/索引)
local_editor_identity 表 —— CRDT site-ID（编辑器身份！）
```

→ Harmony 关系库持久化 —— 对应原版 Room（RdbStore
= 每特性 SQLite 等价物）；`local_editor_identity` 存
CRDT site-ID。

## 仓储 + 存储

```
NoteRepositoryImpl / FolderRepositoryImpl /
PageRepositoryImpl / AssetRepositoryImpl  实体仓储
OpStoreImpl                               CRDT op 日志存储
*Store（EditorSettings/HandwritingLanguage/
 Recording/PageOrder/PaperSettings/Asset
 Reference/OperationAudioTime/Onboarding
 Tooltip/ImageAssetPackage）             特性存储
```

## 语义

持久化 = `RdbStore`（S1 安全级+外键+DDL 迁移+site-ID）
+ 实体仓储 + op 日志 + 特性存储 —— 对应原版 Room
分库+DAO；site-ID 表是 CRDT 身份持久化。

## Harmony 决策

Room → `RdbStore`（relationalStore）+ 仓储/Store 分层
+ `local_editor_identity` CRDT site-ID —— 持久化语义
保真（单体 RdbStore 含全 schema vs 原版分库）。

## 产出

- fixture `d02-persistence.mjs`（10 断言）。
- ADR-1262；中文报告。
