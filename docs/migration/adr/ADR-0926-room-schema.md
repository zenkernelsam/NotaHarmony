# ADR-0926 — Room/SQLite schema 全枚举

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 18 张应用表分四个 DAO 绑定器：`wp1/iq1`（同步 7 表）、
  `y93`（学习 4 表）、`ip1`（文件夹客户端 2 表）、
  `na4`（笔记状态/纸张 5 表）。
- `ba8`/`ukc` 为 androidx WorkManager 库表（非应用语义）。
- 关键语义：`ClientOp.op` = `ree.b` 原始字节；client 表
  普遍带 `idempotencyKey`；`SyncedOpMetadata` 带
  ops/offsets/fileLength 三 checksum 指纹列；
  `NoteStateEntity` 存 zoom/scroll/zoomView/
  lastCodeBlockLanguage UI 态；`PaperBackground` 用
  `nullif(?,0)` 自增 id。

## Harmony 决策

Harmony RDB 侧语义等价——表名录即迁移对照表；op
字节原样 blob、qo5→long 打包键、idempotencyKey 幂等。

## Parity 状态

等价。

## 验证

- `d02-room-schema.mjs`：25/25 通过。
