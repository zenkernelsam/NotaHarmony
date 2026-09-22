# Harmony 证据：原版页书签（bookmark）奇偶 — 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）把"页书签"作为每页 LWW
寄存器落地：CreatePage/ModifyPage 字段 3 解码、寄存器胜者表、
归档/检查点/导入导出全链路保真，以及内容管理器书签动作的
Harmony 落点。

## 原版证据

### 线格式（oz9 / ge8 / ln2 / haj / u5j）

- `defpackage/oz9.java`：`UNBOOKMARKED((byte) 0), BOOKMARKED((byte) 1)`
  ——两值枚举，`.I` 承载字节。
- `defpackage/ge8.java:44,61-70`（ModifyPage 表）：`k()` 读取字段 3
  字节，以 `byte - oz9.M.get(0).I` 索引 `oz9.M`；越界回退 `get(0)`
  ——**未知字节映射为 UNBOOKMARKED**。
- `defpackage/ln2.java:56-61`（CreatePage 表）：同一解码模式。
- `defpackage/vz9.java:677`：`haj.a(cxcVarB, null, i2, oz9.UNBOOKMARKED,
  16)` ——CreatePage 构建器写字段 3，默认 UNBOOKMARKED。
- `defpackage/u5j.java:1141,1164`：`s(x09Var, List, Integer, m2dVar,
  oz9Var, int)` / `t(x09Var, List, lxcVar, m2dVar, oz9Var)` → `r0j.a(...)`
  ——ModifyPage 构建器把 `oz9` 应用到列表中的页。

### 寄存器与物化（yc6 / wz9 / vz9）

- `defpackage/wz9.java:42`：`this.l = yc6Var2.K == oz9.BOOKMARKED`
  ——页模型的 `bookmarked` 由书签寄存器胜者物化；
  `wz9.java:132` 显示寄存器是页的独立字段（`bookmarkedRegister=`）。
- `defpackage/vz9.java:129`：`return this.f.b == oz9.BOOKMARKED`
  ——UI/模型层读取。

### 用户动作（de2 / ae2 / md / nd2）

- `defpackage/de2.java:174-181`：`m(List)` = 书签开关，空选择记
  "Bookmark toggle with empty page selection" 后返回；
  派发 `ae2(..., 0)`（同文件 case 1..5 依次为 clear/copy/cut/delete/
  duplicate——书签是六个多选动作之首）。
- `defpackage/ae2.java` `invokeSuspend` case 0：遍历笔记全部页，
  若**任一被选中页** `!l()`（未书签）→ `oz9Var = BOOKMARKED`，
  否则 `UNBOOKMARKED`；随后一条
  `u5j.s(x09Var, list3, null, null, oz9Var, 6)` ModifyPage
  作用于整个选择集。即原版语义为"有未书签 → 全部书签；否则全部取消"。
- `defpackage/md.java:81-84`：缩略图叠加
  `ui_designsystem__bookmark_tall_fill`（已书签）/
  `bookmark_tall_outline`（未书签）图标。
- `defpackage/nd2.java`：`ALL / BOOKMARKS / NOTES` ——内容管理器
  三枚过滤 chip。

## Harmony 落点

### Schema v70（DatabaseHelper.ets / DatabaseManager.ets）

- `page_info.bookmarked`、`original_deleted_page.bookmarked`、
  `page_delete_checkpoint.bookmarked`：`INTEGER NOT NULL DEFAULT 0`。
- `original_page_bookmark_winner`：`(note_id, page_ts, page_site,
  page_index)` 主键定位页序列身份；胜者 `winner_ts/winner_site` +
  `bookmarked INTEGER NOT NULL CHECK (bookmarked IN (0,1))`，
  `ON DELETE CASCADE`——与 position/visibility/background/
  page-in-asset 胜者表同构。
- v69→v70 迁移：ALTER 三表加列 + 建胜者表 + 从
  `original_page_identity` 为既有页播种胜者行（identity 即胜者，
  bookmarked=0）。

### 解码 / 编码 / 应用

- `OriginalCreatePageOperation.ets`：payload `bookmarked`（字段 3，
  仅字节 1 → true，其余 → false，与 ge8/ln2 越界回退等价）；
  **移除 `BOOKMARK_UNSUPPORTED` 延迟**；创建每页时以 CreatePage
  操作身份播种胜者行并把 `bookmarked` 写进 `page_info`。
- `OriginalModifyPageOperation.ets`：`hasBookmarked`/`bookmarked`
  解码；`applyBookmark` = 读胜者 → 操作身份 LWW 比较 → 写胜者 +
  `updateMaterializedBookmark` 同步活动 `page_info` 与归档
  `original_deleted_page`（含归档页书签——原版寄存器与可见性
  正交，归档页同样接受书签写）。
- `OriginalModifyPagePayloadEncoder.encodeOriginalModifyPageBookmark`：
  vtable 字段 3 写字节；页向量 4 字节对齐；缺省字段 vtable 项为 0。
- `OriginalNoteBundlePageIdentity.ets`：`BootstrapPageState` 增加
  `bookmarked`/`bookmarkWinner`；CreatePage 播种、ModifyPage 按
  操作身份 LWW 更新；fresh 路径批量插入胜者行；
  `applyBootstrapBookmarks` 在 fresh 与 existing-mapping 两条路径
  无条件物化；`existingMappingMatches` 校验胜者行数与逐页身份/值；
  `hasExistingMapping` 识别胜者表。

### 运行时 / 生命周期 / 包格式

- `PageInfo.bookmarked` + `clonePageInfo` 保真；
  `PageRepositoryImpl` 读写路径（rowToPage / addPage /
  addImportedPage / 检查点快照与恢复）全链携带。
- `PageRepository.setPageBookmarked`（接口 + 实现）：原版身份页 →
  `persistOriginalPageBookmark`（分配操作身份 →
  `encodeOriginalModifyPageBookmark` → apply → appendOperation →
  持久历史，与 reorder/visibility 同双写）；本地页 → 直接列更新。
- `OriginalDeleteEntitiesOperation` 归档/恢复两向携带；
  `OriginalPagePersistence.readPage` 读列；
  `OriginalBlankNoteBootstrapPersistence.requireCreatedPages`
  播种 bookmarked=false。
- 备份/缩略图 `BackupPageRevision` 签名携带 bookmarked——书签翻转
  是文档变更，应推移备份签名。
- `NotePackageSpec.PageData.bookmarked?` + `NoteExporter` 写出 +
  `NoteImporter` 校验（可选 boolean，缺省 false——旧包格式兼容）。

### UI（PageManagerBar.ets / NotePage.ets）

- 页计数旁 `🔖` 指示（md.java 缩略图叠加图标的当前页落点）；
  常规行 `🔖` 开关按钮（书签时 accent 着色）；紧凑页菜单同位项；
  全部回调沿用 `busy || photoImportLeaseActive` 失败即关守卫。
- `NotePage.toggleCurrentPageBookmark` 经 `runPageOperation` →
  `pageRepo.setPageBookmarked` → 本地 `pages` 数组同步。

## 刻意排除（设计决策）

`bookmarked` 是**可变寄存器**，不是不可变页结构。因此不进入：

- `PageStructureOpCodec` 的页结构相等性/序列化
- `PageRepositoryImpl.samePage`
- `PersistentHistory.samePageInfo` / `changedPages`

理由：删除推送与重做之间若发生书签翻转，结构比较必须仍然通过；
checkpoint/archive 列仍携带书签以保证恢复保真。

## 登记适配差异

1. 原版开关是内容管理器缩略图网格上的**多选**动作
   （de2.m → 一条 ModifyPage 覆盖选择集）；Harmony 无缩略图网格，
   落点为当前页单选开关（PageManagerBar）——寄存器/写路径语义一致，
   选择集退化为 1。
2. `nd2` 的 BOOKMARKS 过滤 chip 依赖页网格表面——暂不可移植，登记。
3. 图标 `bookmark_tall_fill/outline` → 文本字形 `🔖`（代码库无
   SymbolGlyph 先例，沿用文本字形约定）。

## 验证

- 专项 replay `d02-original-page-bookmark-parity.mjs`：50 项断言
  全过（原版 oz9/ge8/ln2/haj/u5j/ae2/de2/md/nd2 锚点 + Harmony
  解码/寄存器/迁移/仓储/UI 锚点 + 可执行开关与 LWW/归档恢复/
  导入导出模型）。
- 既有锚点合法更新：`d02-page-bar-shared-lease-bound.mjs`
  失败即关回调计数 7→9；`d02-original-null-title-register.mjs`
  的 `assertEqual(69)` → 70。
- 全量 replay 431/431（仓根执行）。
- `note@default` + `note@ohosTest` 构建成功；0 个 ArkTS ERROR。
- 未启动模拟器、虚拟机、真机或 Hypium。
