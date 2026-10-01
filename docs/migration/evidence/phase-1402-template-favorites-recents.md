# Phase 1402 证据 — 捆绑模板收藏/最近使用/用量

## 原版 1.4.2 证据（decompiled_1.4.2）

### 数据面（gaf/qsh Room）

- `gaf`（`sources/defpackage/gaf.java`）：模板元数据 store，三路 flow：
  - `gaf.c` = `FavoritePaperTemplate` 表监听；
  - `gaf.d` = `RecentPaperTemplate` + `RecentGalleryTemplate` 合并流；
  - `gaf.e` = `PaperTemplateUsage` map。
- 建表语句（`ca3.java` ~line 544）：
  ```sql
  CREATE TABLE FavoritePaperTemplate(pdfAssetPath TEXT PK, favoritedAt INTEGER);
  CREATE TABLE RecentPaperTemplate(pdfAssetPath TEXT PK, usedAt INTEGER);
  CREATE TABLE RecentGalleryTemplate(noteId PK, title, publisherScreenname,
    previewImageUrl, likes, downloads, hasNtb, isRemix, remixCount, usedAt);
  CREATE TABLE PaperTemplateUsage(templateUuid TEXT PK, useCount INTEGER);
  ```
- 查询/裁剪（`nsh.java` / `fch.java`）：
  - `SELECT pdfAssetPath FROM FavoritePaperTemplate ORDER BY favoritedAt DESC`
  - `SELECT * FROM RecentPaperTemplate ORDER BY usedAt DESC`
  - `DELETE FROM RecentPaperTemplate WHERE pdfAssetPath NOT IN
    (SELECT pdfAssetPath FROM RecentPaperTemplate ORDER BY usedAt DESC LIMIT 36)`
  - `SELECT * FROM PaperTemplateUsage`
- `chc`（PaperTemplateVariant）字段序：`a`=templateUuid、`b`=paperSize、
  `c`=orientation、`d`=colorHex、`e`=pdfAssetPath（`a()` getter）、
  `f`=thumbPath、`g`=needsLightInk → 收藏/最近键 = `chc.e`。

### 写路径

- 收藏：`pth.o(chc,z)` → `yb6(gaf, chc.e, z)` → FavoritePaperTemplate
  upsert/delete。
- 应用记录：`pth.t(chc)` → `qc0(gaf, chc.e, chc.a)` → RecentPaperTemplate
  上移（usedAt=now）+ PaperTemplateUsage useCount+1。调用方为模板应用
  成功路径（`f1d`→`sqc.b` 完成后）。
- 设为默认：`pth.g(chc)` → `o8b.e(ju8)` case26 → `o8b.w`=flatbuffer
  `pfc{wfc,tr0}`、`o8b.x`=uuid —— 本 Phase 不落地（登记）。

### 视图面

- `qgc` cell 状态：`{pgc, chc resolvedVariant, c=isCurrent, d=isFavorite}`；
  `isCurrent` = `b1dVar instanceof a1d` → 本会话最近 Preset 变体相等。
- `q9l.b`：cell 右上星标按钮，`qgc.d` → `ui_designsystem__favorite_fill`
  （实色星）vs `favorite_outline`（透明 fill + `#000` 1.25 stroke
  round-join evenOdd）；两 drawable 共用同一 24×24 星形 pathData。
- `ha6`：category 分节（`ahc`）之外构建 `qia{recents, favorites, -}`
  挂 `sth.PRESET` tab（tab 标签：`preset`/`gallery`/`my_templates`）。
- `ria`：空态枚举 `FAVORITES="Star a design to keep it here."` /
  `RECENTS="Designs you apply show up here."` / `CUSTOM`（My Templates 空态）。
- `s7n.d`：recents/favorites 按存入 `pdfAssetPath` 经 `mapI0`
  （`chc.e → kdc{pgc,chc}`）精确反查 exact variant。

## Harmony 落点

- `note/src/main/ets/data/BundledTemplateMetaStore.ets`：preferences
  `bundledPaperTemplateMeta`；三个键 + `recordUsed`/`setFavorite`/
  `getRecentPaths`/`getFavoritePaths`/`getUsageCounts`；回滚写与
  `EditorSettingsStore` 同款；36 条裁剪常量
  `BUNDLED_TEMPLATE_RECENTS_LIMIT`。
- `note/src/main/ets/core/model/PaperTemplateCatalog.ets`：
  `findBundledPaperVariantByPath` + `BundledPaperVariantMatch`。
- `note/src/main/ets/ui/editor/PaperTemplateGallery.ets`：顶部
  Recents/Favorites 区块（恒在 + `ria` 空态）+ cell 星标 overlay +
  `appliedVariantPath` 会话徽记 + 乐观切换/失败回滚。
- `note/src/main/ets/ui/editor/NotePage.ets`：`buildTemplateGallery` 透传
  徽记；`applyBundledPaperTemplate` 成功后 `recordUsed(path, uuid)`。
- 字符串：en/zh 各 6 键（recents/favorites/no_*/unfavorite/favorite）。

## 验证

- `d02-original-paper-template-favorites.mjs` 48 checks 绿。
- `note@default` / `note@ohosTest` 构建 + 全量 Replay 基线（见报告）。
