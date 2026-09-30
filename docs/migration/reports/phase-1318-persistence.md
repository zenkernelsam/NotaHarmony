# Phase 1318 报告 — 持久化层

## 完成内容

- `DatabaseManager`（`relationalStore.RdbStore`+S1 安全
  级+foreign_keys pragma+DDL 迁移+`local_editor_
  identity` CRDT site-ID 表）+ 实体仓储（Note/Folder/
  Page/Asset `*RepositoryImpl`）+ `OpStoreImpl`（CRDT
  op 日志）+ 10+ 特性 Store（EditorSettings/Recording/
  PageOrder/PaperSettings/AssetReference/Onboarding 等）
  —— Harmony 持久化对照原版 Room 分库+DAO。

## 产出

- evidence `phase-1318-persistence.md`
- fixture `d02-persistence.mjs`（10/10）
- ADR-1262
