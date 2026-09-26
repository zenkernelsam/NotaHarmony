# ADR-0710 — 原版 1.4.2 画廊互动 Outbox Schema 维持 fail-closed

日期：2026-09-29
状态：已登记（版本差·后端边界，维持 ADR-0708 fail-closed；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-766-original-gallery-outbox-schema.md`
Replay：`docs/migration/replays/d02-original-gallery-outbox-schema.mjs`
上游：ADR-0708（1.4.2 版本差处置范围）、ADR-0659（账号/社交边界）

## 背景

1.4.2 新增 `com.gingerlabs.notability.data.gallery.outbox.GalleryMutationDatabase`
（独立 Room 数据库），存放社交互动的本地待发队列：

- `PendingLike(noteId PK, liked INTEGER)` — 点赞态度覆盖写
- `PendingFollow(userId PK, following INTEGER)` — 关注态度覆盖写

DAO 使用 Room upsert 适配器（INSERT 失败回退 UPDATE），单键幂等——
重复互动折叠为最终态；排空由 `GalleryMutationUploaderWorker`
（WorkManager/CoroutineWorker）后台驱动上传画廊后端。

## 决策

维持 **fail-closed**：

1. 两张表虽为本地 schema，唯一消费者是画廊后端上传 Worker——无对应
   Harmony 后端与账号体系（ADR-0659），实现即伪造功能，不移植。
2. 不新建"先记账后同步"壳：Nozomi 版本 1.0.3 基线不含画廊簇，1.4.2
   行为属版本差（ADR-0708），非移植义务。
3. schema 证据完整归档为 T-042 输入；若未来获授权接入画廊后端，
   本 ADR 的 DDL/upsert/排空语句即为移植规格。

## 后果

- `d02-original-gallery-outbox-schema.mjs` 钉住双表 DDL、upsert 语句对
  与 Worker 存在性。
- `PendingLike`/`PendingFollow` 字符串键（`gallery_*` 簇）处置不变。
- 不改变任何 Harmony 代码路径；画廊入口保持 fail-closed 注册态。
