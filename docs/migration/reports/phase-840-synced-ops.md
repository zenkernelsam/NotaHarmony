# Phase 840 — `data/note/ops` 同步操作层

## 范围

`data/note/ops/`（database + synced 两子包）+ Harmony
OperationSyncCoordinator 对照。

## 原版发现

- `ops/database/`：`NoteBundleMetadataDatabase`（笔记束
  元数据 Room DB）；
- `ops/synced/`：**六类类型化同步失败异常**——
  AccessDenied/CorruptedSyncedOp/NoteHasNoOps/NoteOpsGone/
  NoteOpsNotFound/StaleSyncedNote；其中
  `NoteOpsGoneException extends NoteOpsNotFoundException`
  （410 是 404 的子类型，层级化分类）。

## Harmony 侧

`OperationSyncCoordinator` 有 7 处 `throw new Error(...)`
（request/session/batch/identity/ack 校验），全部非类型化
字符串 Error——**无六类分类学**。登记为缺口；因同步后端
fail-closed，属文档级而非行为级缺口。

## 验证

- 新 Replay `d02-synced-ops.mjs`：**13/13**（结构、六类齐全、
  继承链、Gone⊂NotFound 层级、Harmony 非类型化断言）。
- ADR-0784。
