# ADR-1262：持久化层

## 状态

已接受（Phase 1318）。

## 决策

Room → `relationalStore.RdbStore`（S1+外键+DDL 迁移）
+ 仓储/Store 分层 + `local_editor_identity` CRDT
site-ID —— 持久化语义保真。

## 理由

`DatabaseManager`（RdbStore+getRdbStore+S1+foreign_keys
+DDL）+ `local_editor_identity`（CRDT site-ID 表）+
Note/Folder/Page/Asset 仓储 + `OpStoreImpl`（op 日志）
+ 10+ 特性 Store —— Harmony 关系库持久化对照原版
Room 分库。

## 后果

持久化用单体 RdbStore（含全 schema+site-ID）vs 原版
模块化分库 —— 语义保真（schema/事务/迁移等价）。
