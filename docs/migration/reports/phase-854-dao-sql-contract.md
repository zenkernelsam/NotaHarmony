# Phase 854 报告：Room DAO SQL 契约层登记

## 范围

承接 Phase 853（DDL 语句层），下沉到 DAO 查询层：
混淆 `defpackage` 宿主中全部应用表 SQL 的分布与旗舰
语义契约。

## 原版证据

- 102 个含 `SELECT` 的 defpackage 文件；剔除 853 登记的
  12 个 DDL 宿主后，**67 个纯应用 DAO 宿主**，合计
  **278 条**应用表 SQL；余为 vendor DAO。
- 旗舰 `ws3`：`SyncedOpMetadata` × `ClientOp` 三段 CTE
  元数据投影——`opId = (timestamp<<32)|siteId` INTEGER
  打包，`opId>>32` 取时戳，`finalTitle` CASE 链实现
  服务端标题 vs 本地标题的 LWW 决胜；UNION ALL 双分支
  覆盖"无 SyncedOpMetadata 行"场景。

## Harmony 对照

- opId 载体：`op:<hex-ts>:<hex-site>` TEXT（仅身份键）+
  独立 `op_timestamp`/`editor_site_id` 列。
- LWW 决胜：`compareOperationIdentity` (timestamp,siteId)
  显式字典序 —— 与原版打包 int 比较**语义等价**，
  siteId 上界更严（65535 vs 32bit）。
- 策略差异：原版读出时 CTE 合并；Harmony 应用时物化
  `note_meta` + `*_winner` 寄存器 + 发散自检抛错
  （`materialized projection diverged`，原版无此检查）。
- 已登记偏差：v7 历史迁移 `op_id` 字符串序对变长 hex
  不安全，仅涉 DB≤v6 存量；表已废弃。

## 验证

- Replay `d02-dao-sql-contract.mjs`：**16/16**。
- ADR-0798。**DAO 查询契约面闭合**；数据库证据链三级完备。
