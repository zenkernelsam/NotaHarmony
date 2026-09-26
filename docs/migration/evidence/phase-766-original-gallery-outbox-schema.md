# 原版 1.4.2 画廊互动 Outbox 数据库 Schema 登记（Phase 766 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/gallery/outbox/`
>   + `sources/defpackage/{qtc,vtc,vnh,yg1,pd2,otc,ttc}.java`
> 性质：1.4.2 版本差证据登记（ADR-0708"画廊/社交后端"簇细化）；无 Harmony 代码变更。

## 一、数据库与实体

`GalleryMutationDatabase`（`gallery/outbox/GalleryMutationDatabase(_Impl).java`，
独立 Room 数据库）暴露两个 DAO（`u()`→`qtc`、`v()`→`vtc`）。失效追踪器
声明恰好 **2 张表**：

- `PendingLike`
- `PendingFollow`

实体类（混淆名）：`ttc`=PendingLike、`otc`=PendingFollow
（`toString` 原形 `PendingLike(noteId=...)` / `PendingFollow(userId=...)`，
全限定名 `...gallery.outbox.PendingLike/.PendingFollow` 见 Room 校验串）。

## 二、DDL 原文

```sql
CREATE TABLE IF NOT EXISTS `PendingLike` (`noteId` TEXT NOT NULL, `liked` INTEGER NOT NULL, PRIMARY KEY(`noteId`))
CREATE TABLE IF NOT EXISTS `PendingFollow` (`userId` TEXT NOT NULL, `following` INTEGER NOT NULL, PRIMARY KEY(`userId`))
```

布尔以 INTEGER 持久化（`ttc.b ? 1L : 0L` / `otc.b ? 1L : 0L` 绑定）。

## 三、DAO 语句（`vtc`/`qtc` impl）

写路径为 Room **upsert 适配器** `op4(yg1-insert + pd2-update)`：

```sql
INSERT INTO `PendingLike` (`noteId`,`liked`) VALUES (?,?)          -- yg1 case 4
UPDATE `PendingLike` SET `noteId` = ?,`liked` = ? WHERE `noteId` = ?   -- pd2 case 3
INSERT INTO `PendingFollow` (`userId`,`following`) VALUES (?,?)    -- yg1 case 3
UPDATE `PendingFollow` SET `userId` = ?,`following` = ? WHERE `userId` = ?  -- pd2 case 2
```

读/删路径：

```sql
SELECT * FROM PendingLike
SELECT * FROM PendingLike WHERE noteId IN (...)
SELECT * FROM PendingFollow
DELETE FROM PendingLike
DELETE FROM PendingFollow
```

`SELECT * WHERE noteId IN (...)` 为笔记域批量查询（图书馆卡片徽标态用）；
`DELETE FROM` 全清用于上传成功排空或退出登录清场。

## 四、上传管道

`GalleryMutationUploaderWorker extends CoroutineWorker`
（WorkManager，构造注入 `l66` uploader）——后台排空 outbox →
画廊后端 API。这是典型 outbox 模式：本地先记账、Worker 重试上传。

## 五、语义总结

| 表 | 语义 |
|---|---|
| `PendingLike` | 笔记点赞的本地待发队列（noteId 覆盖写 = 幂等） |
| `PendingFollow` | 创作者关注的本地待发队列（userId 覆盖写 = 幂等） |

两表单键幂等 upsert——后写覆盖前写，最终只上传最新态度（like/unlike、
follow/unfollow 折叠为最终态）。

## 六、Harmony 现状与分类

- Harmony 侧无画廊/社交表面（ADR-0659 账号边界 + ADR-0708 画廊后端
  fail-closed 登记已覆盖）。
- 本表虽为本地 schema，**其唯一用途是后端上传**——无画廊后端时属
  无消费者队列，整体维持 fail-closed；不列为本地候选。
- schema 证据归入 T-042 版本差异输入；若未来画廊后端获授权，本表
  可直接映射为 Harmony 关系型数据库两表。
