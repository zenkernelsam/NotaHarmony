# 原版 1.4.2 自定义模板数据库 Schema 登记（Phase 764 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/templates/database/`
>   + `sources/defpackage/e83.java`（Room 生成 INSERT 语句）
> 性质：1.4.2 版本差证据登记（ADR-0708"版本差·待审"细化）；无 Harmony 代码变更。

## 一、数据库与实体

`CustomTemplatesDatabase`（Room，`database/CustomTemplatesDatabase(_Impl).java`）
声明两个实体表：

- `CustomTemplate`
- `PendingTemplateDeletion`

配套 DAO/仓储实现位于 `defpackage`（`g83`/`kuc`/`wa3`/`s93` 等），
同步侧为 `data/templates/sync/CustomTemplateSyncWorker` +
`data/settings/sync/TemplatePageSyncWorker`。

## 二、`CustomTemplate` 列清单（Room 生成 INSERT 原文）

```sql
INSERT OR REPLACE INTO `CustomTemplate`
(`id`,`name`,`interactive`,`repeats`,`createdAt`,`favoritedAt`,
 `assetId`,`syncedName`,`uploadState`,`origin`,`pageCount`,`pageWidth`,`pageHeight`)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
```

```sql
INSERT OR REPLACE INTO `PendingTemplateDeletion` (`assetId`) VALUES (?)
```

列语义推断（结合 `ui_templates__*`/`ui_share__gallery_*` 键族）：

| 列 | 语义 |
|----|------|
| `id` / `name` / `createdAt` | 模板主键/命名/创建时间 |
| `interactive` | interactive template 开关（`ui_templates__interactive_template_*`） |
| `repeats` | repeat template 开关（每页重复应用，`repeat_template_*`） |
| `favoritedAt` | 收藏排序键（templates favorites 行） |
| `assetId` / `syncedName` / `uploadState` / `origin` | 云同步状态机（asset 上传态、同步命名、来源） |
| `pageCount` / `pageWidth` / `pageHeight` | 模板页几何 |

`PendingTemplateDeletion` 仅 `assetId` 单列——墓碑式待删队列，
供 `GalleryMutationUploader`/模板同步回收远端资产（软删+上传墓碑模式
与 Harmony 现有 `RecentlyDeleted`/asset-detach 管线同型）。

## 三、处置

- 本地库结构纯 SQLite/Room——Harmony 侧 RelationalStore 可等价；
- 真正的移植依赖：模板资产落地格式（页面→模板包的序列化）、
  `interactive`/`repeats` 的页面应用语义、Gallery 同步协议；
- 登记为 ADR-0708"版本差·待审"；`PendingTemplateDeletion` 墓碑模式
  可复用到本仓 asset-detach 设计评审，本阶段仅登记 schema。
