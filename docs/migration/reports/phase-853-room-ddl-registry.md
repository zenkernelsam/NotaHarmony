# Phase 853 报告：Room DDL 语句级登记

## 范围

承接 Phase 822（库级拓扑），本阶段登记语句级 DDL：
反编译树中全部 `CREATE TABLE`/`CREATE INDEX` 原文的
宿主分布、迁移体重建模式、vendor SQL 隔离。

## 原版证据

- `*_Impl` 壳文件不含 DDL（仅 DAO 工厂）；应用 DDL 经 R8
  合并于 `defpackage/ca3`：**54 应用表 + 7 vendor 表 +
  18 CREATE INDEX**（含 `idx_clientop_agg_optimized`
  五列复合同步索引、转写 4 索引）。
- 迁移体 5 文件（wf1/yf1/r4a/zmb/fgf）呈 `_new_*`
  建表-拷数-改名模式：Calendar v1→v2（syllabus 双表 +
  calendarSelections/calendarDismissedEvents）、Learn
  `_new_SummaryEntity`、Search `IndexedNote` 重建、
  Toolbox `ToolStateEntity_new`、WorkManager `_new_WorkSpec`。
- vendor DDL 隔离：DataTransport(xbf)/Firebase(oal)/
  Intercom(cye)/Mixpanel(ao9)/room_master(ac3)。

## Harmony 对照

`DatabaseHelper.ets` 单库 RDB：88 条 CREATE TABLE、
**67 个唯一表名**（5 名有变体 DDL），覆盖原版 library/
ops/state/toolbox/search/asset/history 全部本地域。

无对应（fail-closed，与功能域登记一致）：Learn 7 表、
Calendar 4 表、GalleryMutation 2 表、Transcription 2 表、
全部 vendor SQL。

## 验证

- Replay `d02-room-ddl-registry.mjs`：**36/36**。
- ADR-0797。**Room DDL 面闭合。**
