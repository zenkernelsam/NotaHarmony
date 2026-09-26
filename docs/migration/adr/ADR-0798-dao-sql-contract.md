# ADR-0798：DAO SQL 契约层登记与 opId 编码等价性确认

## 状态

已接受（2026-09-23，Phase 854）

## 背景

Phase 853 闭合 DDL 语句层；DAO 查询层（`@Query` SQL 实体）
仍未登记。原版 R8 将 DAO 方法编译为混淆 `defpackage`
`*Impl` 类，SQL 字面量散于其中。

## 决定

以宿主分布登记原版 DAO 查询契约：102 个 `SELECT` 宿主中
67 个为纯应用 DAO（12 个 DDL 宿主已在 853 归口），合计
278 条应用表 SQL。

旗舰契约 `ws3` = SyncedOpMetadata 笔记元数据投影：读出时
CTE 合并服务端元数据与本地未上传 ops，`opId` 以
`(timestamp<<32)|siteId` INTEGER 打包实现 LWW 决胜
（finalTitle CASE 链 + UNION ALL 双分支）。

**等价性结论**：Harmony 不以 SQL CTE 读出合并，改为
应用时物化 + `*_winner` 寄存器表 + `compareOperationIdentity`
(timestamp,siteId) 显式字典序——与原版打包 int 比较同语义；
另增加物化投影发散自检（原版无）。opId 载体不同
（`op:hex:hex` TEXT vs INTEGER）但仅作身份键，不参与
LWW 比较，语义等价。

**已登记偏差**：`DatabaseHelper` v7 历史迁移以
`previous.op_id < current.op_id` 字符串排序——对变长
hex 不安全；仅影响 DB≤v6 存量 client_op 行的同
client_time 页内次序，表已于 v7 废弃，属一次性历史路径。

## 依据

- `decompiled_1.4.2/sources/defpackage/`（ws3 等 67 DAO 宿主）
- `note/src/main/ets/data/OperationIdentity.ets`
- `note/src/main/ets/data/OriginalNoteTitlePersistence.ets`
- `note/src/main/ets/data/OriginalSetMetadataOperation.ets`
- `note/src/main/ets/data/DatabaseHelper.ets`（v7 迁移）

## 后果

- Replay `d02-dao-sql-contract.mjs`：16 项断言。
- 数据库证据链闭合至三级：拓扑(822) → 语句 DDL(853) →
  查询契约(854)。
