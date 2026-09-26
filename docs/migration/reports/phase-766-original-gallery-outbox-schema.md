# Phase 766 — 原版 1.4.2 画廊互动 Outbox Schema 登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-766-original-gallery-outbox-schema.md`
ADR：`ADR-0710-original-gallery-outbox-schema.md`
Replay：`d02-original-gallery-outbox-schema.mjs`（10/10）

## 本阶段做了什么

继 Phase 765 之后，对 1.4.2 第三个新增 Room 数据库
`GalleryMutationDatabase`（`data/gallery/outbox/`）执行同法取证：
从 `ca3` RoomOpenHelper、`yg1`/`pd2` upsert 适配器对与
`vtc`/`qtc` DAO impl 完整恢复双表 DDL 与全部 DAO 语句。

## 恢复的 schema 与语义

- `PendingLike(noteId PK, liked INTEGER)` / `PendingFollow(userId PK,
  following INTEGER)`——布尔以 INTEGER 持久化。
- 写路径为 Room upsert（INSERT 冲突回退 `UPDATE ... WHERE pk=?`），
  单键幂等，重复互动折叠为最终态度。
- 读路径 `SELECT *`/`WHERE noteId IN (...)`；删路径 `DELETE FROM`
  全清（排空或登出清场）。
- `GalleryMutationUploaderWorker`（CoroutineWorker）后台排空 →
  画廊后端 API：典型 outbox 模式，本地记账 + Worker 重试上传。

## 分类

ADR-0710 判定**维持 fail-closed**（ADR-0708 画廊后端簇 + ADR-0659
账号边界的细化）：两表唯一消费者是后端上传 Worker，无 Harmony
后端即无意义队列。schema 归档为 T-042 版本差异输入，若未来获授权
接入画廊后端，本阶段证据即移植规格。

## 验收

- Replay fixture 10/10 绿；全量 Desktop Replay 与双 HAP 构建随本阶段执行。
- 三项跟踪文档已更新。
