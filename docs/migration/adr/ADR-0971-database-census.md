# ADR-0971 — Room 数据库清点

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- **按功能分库**：NoteBundleMetadata（57）/
  RawLibraryState（40）/Toolbox（40）/SearchIndex/
  Transcription/Learn/NoteAsset 七个主库 +
  WorkManager vendored。
- `e47` = 主 DB RoomOpenHelper（51 CREATE TABLE，
  含迁移重复+验证）。
- `wp1 extends njj` = Room EntityInsertionAdapter。

## Harmony 决策

分库结构保留（relationalStore 按域分文件）；
e47 聚合 DDL 用 migrator/init 复刻。

## Parity 状态

结构等价。

## 验证

- `d02-database-census.mjs`：10/10 通过。
