# Phase 1027 报告 — Room 数据库清点

## 范围

Room 数据库清单 + DAO→DB 绑定器映射。纯审计。

## 原版发现

- **至少 7 个 distinct DB**（按域分库）：
  NoteBundleMetadata（57 引用）/RawLibraryState/
  Toolbox/SearchIndex/Transcription/Learn/NoteAsset。
- `e47` = 主 DB RoomOpenHelper——51 CREATE TABLE
  （含迁移重复+验证）；`wp1 extends njj` 插入适配器。
- 分库 = 模块化隔离（sync/library/toolbox/search/
  transcription/learn/asset 各独立）。

## Harmony 决策

分库结构保留；e47 聚合 DDL 用 migrator/init 复刻。

## 产出

- 证据：`phase-1027-database-census.md`
- Fixture：`d02-database-census.mjs`（10/10）
- ADR-0971；全量 Replay 见本提交。
