# Phase 854 — Room DAO SQL 契约层登记（查询语义 vs Harmony 实现）

Phase 822/853 闭合了库拓扑与 DDL；本阶段下沉到 **DAO 查询层**：
原版 Room 生成的 `@Query` SQL 实体分布在混淆 `defpackage`
宿主类中，逐条登记宿主分布与旗舰查询语义。

## 宿主分布

`decompiled_1.4.2/sources/defpackage/` 中含 `SELECT` 字面的
文件共 102 个；剔除 Phase 853 已登记的 12 个 DDL 宿主后，
引用应用表（52 个实体名，FROM/INTO/UPDATE/JOIN 命中）的
**67 个为纯 DAO 实现宿主**（R8 将每个 DAO 方法编译为独立
`*Impl` 类），合计 **278 条** SELECT/UPDATE/DELETE/INSERT
语句。其余为 vendor DAO（WorkManager/DataTransport/Firebase/
Mixpanel/Intercom 等）。

## 旗舰契约：`ws3` — SyncedOpMetadata 笔记元数据投影

原版笔记列表/库页的元数据由一条 CTE 聚合查询生成
（`ws3.java`，17 处 SELECT），把 **服务端已同步元数据**
（`SyncedOpMetadata`）与 **本地未上传 ops**（`ClientOp`）
读出即合并：

```
WITH MaxTitleOpId AS (SELECT noteId, MAX(opId) ... WHERE hasTitle=1),
     ClientTitleData AS (SELECT c.title, (c.opId >> 32) AS ts ...),
     ClientAgg AS (MAX(hasTitle), MAX(opId>>32), MAX/MIN(clientTime))
SELECT COALESCE(som.id,?) ... ,
  CASE WHEN som.titleOpId IS NULL THEN (hasTitle? clientTitle)
       WHEN ctd.ts IS NULL THEN som.title
       WHEN som.titleOpId >= ((ctd.ts<<32)|siteId) THEN som.title
       ELSE clientTitle END AS finalTitle, ...
FROM SyncedOpMetadata som LEFT JOIN ClientAgg ... UNION ALL
(ClientAgg-only 分支：无 SyncedOpMetadata 行时同样成立)
```

### opId 编码契约

`opId` 为 INTEGER = `(timestamp << 32) | siteId`（32+32 打包）；
`opId >> 32` 取回时间戳，比较运算即 (timestamp, siteId) 字典序。
`titleOpId` 比较决定"服务端标题 vs 本地最新标题"谁赢——
LWW-Register 语义的 SQL 内联实现。

同文件其它查询：`DeferredSyncedOps`、`DraftNote`、`LearnJob`
探测、`NoteIndexableChanges` 分页拉取、`hasServerData` 存在性
检查。

## Harmony 对照

| 原版 | Harmony |
|---|---|
| opId = INTEGER `(ts<<32)\|siteId` | `op:<hex-ts>:<hex-site>` TEXT
+ 独立 `op_timestamp`/`editor_site_id` 列 |
| 读出时 CTE 合并 server+client | 应用时物化 `note_meta` +
`*_winner` 寄存器表（LWW 决胜表） |
| SQL 内联 `>=` 比较打包 int | `compareOperationIdentity()` =
(timestamp,siteId) 显式字典序，siteId≤65535 |
| — | 发散自检：`title winner and materialized
projection diverged` 抛错（原版无此检查） |

`OriginalNoteTitlePersistence`/`OriginalSetMetadataOperation`：
readTitleState LEFT JOIN `original_note_title_winner`，
`compareOperationIdentity` 决胜、相等时校验载荷一致性、
冲突即 `SET_METADATA_TITLE_IDENTITY_CONFLICT` defer —
与原版 CASE 链同语义，且多了物化投影一致性断言。

## 发现的差异（登记，非新增缺陷）

1. **v7 历史迁移** `DatabaseHelper` 用
   `previous.op_id < current.op_id` 对 client_op 排序：
   `op:hex` 字符串字典序对变长 hex 不安全（`op:f:x` >
   `op:10:x`）。仅影响 DB≤v6 存量数据的同 client_time 页内
   element_order；`client_op` 表 v7 已 DROP，属一次性历史
   迁移路径，登记为已知偏差。
2. **查询时合并 vs 应用时物化**——架构策略不同但 LWW
   语义等价；Harmony 额外加发散自检，更严格。

## 结论

原版 278 条 DAO SQL 落在 67 个混淆宿主，逐域可考；
元数据投影/标题 LWW/同步队列语义已在 Harmony 以等价物化
+寄存器+自检实现。**DAO 查询契约面闭合。**
