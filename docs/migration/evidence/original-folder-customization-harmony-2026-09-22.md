# Harmony 证据：原版文件夹颜色 / emoji 自定义与编辑时间戳（SCHEMA-D3）— 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）LibraryDatabase 的文件夹元数据模型，
补齐 Harmony `folder` 表缺失的 `color` / `emoji` / `updated_at`（Phase 530 登记的
SCHEMA-D3）。原版该能力并非仅同步字段——文件夹对话框可编辑、行视图有颜色渲染、
笔记行模型携带 `folderColor`。

## 原版证据

### 表声明（defpackage/e47.java）

- `e47.java:353` `SyncedFolderMetadata(id BLOB, parentId BLOB NOT NULL,
  updatedAt INTEGER NOT NULL, title TEXT NOT NULL, color INTEGER NOT NULL,
  siblingOrder REAL NOT NULL, emoji TEXT)`——颜色恒为具体 int，emoji 可空。
- `e47.java:354` `ClientFolderEdit(id, parentId, title, color INTEGER, siblingOrder,
  createdAt, updatedAt INTEGER NOT NULL, uploaded, idempotencyKey, emoji TEXT)`——
  除主键/updatedAt/uploaded/幂等键外全部可空：未写字段 = 保留当前值的增量编辑行。

### 实体字段序（defpackage/xo1.java）

`xo1(a=id, b=parentId, c=title, d=color(Integer), e=siblingOrder(Double),
f=xgb(createdAt), g=updatedAt(long), h=deleted, i=?, j=emoji(String))`。

### 编辑路径（beb.e → vdb / rdb / xdb，经 id7 门面）

- `id7.l(id7, folderId, title, Integer color, String emoji, …)` →
  `beb.e(folderId, now, null, title, color, null, emoji)`：重命名/自定义对话框
  一次性提交名称+颜色+emoji（`id7.java:165-169`）。
- `id7.b(..., int color, ...)` → `sdb` → `rdb`：创建必须给出具体颜色 int；
  `rdb.java:47` `new xo1(id, parentId, title, color, order, new xgb(j), j, emoji)`
  ——createdAt 与 updatedAt 同刻写入。
- `xdb.java:109/144`（移动）：`beb.e(id, ts, parentId, null, null, siblingOrder, null)`
  ——仅写 parent+siblingOrder，title/color/emoji 置 null 保留原值。
- `vdb.java`（beb.e 主体）：`num == null → lq4Var.f()`、`strD == null → lq4Var.d()`、
  `title2 == null → lq4Var.getTitle()`、`d == null → lq4Var.h()`——逐字段"未设即
  保留"；`this.T`（updatedAt）**无条件**写入两行 `new xo1(...)`/`xo1.d(...)`。
- `udb.java:28` `Q.e(null, 0L, null, null, null, null, null, this)`：全 null 调用
  即"仅盖 updatedAt"的空编辑——确认 updatedAt 恒写语义。

### 显示合并（defpackage/pdb.java，库列表行模型 lq4）

- `pdb.f()`：edit `xo1VarC.d` 非空用之，否则 synced `jaeVar.e`，再否则抛
  "Data not found"——**每个文件夹行必渲染一个具体颜色 int**。
- `pdb.d()`：edit `xo1VarC.j` 非空用之，否则 synced `jaeVar.g`；
  `null 或 length<=0 → null`——空串 emoji 等价无 emoji。
- `pdb.e()/getTitle()/h()`：同一"edit 覆盖 synced"逐字段解析。
- `ncj.c(this.c)`：从 ClientFolderEdit 列表取该文件夹最新编辑行。
- `w09.java:106` 笔记行模型携带 `folderColor`——颜色用户可见，非同步管线私用。

### emoji 选择器

- `ac4.java:133` 特性开关 `LIBRARY_FOLDER_EMOJI_PICKER`；`msb.java:5`
  `androidFolderEmojiPicker`——原版为分类 emoji 网格（Smileys/People/Animals/
  Food/Activities/Objects/Travel/Symbols/Flags）。

## Harmony 落点

### Schema（DatabaseHelper.ets，版本 67→68）

```sql
folder.color      INTEGER NOT NULL DEFAULT -7431250  -- FOLDER_DEFAULT_COLOR
folder.emoji      TEXT
folder.updated_at INTEGER NOT NULL DEFAULT 0
```

- `color` NOT NULL + DEFAULT：对齐原版"文件夹恒有具体色"（pdb.f() 无 null 路径）。
- 老库 `MIGRATIONS[68]` 三列 ALTER + `UPDATE folder SET updated_at = created_at`
  （创建时刻即最近一次编辑，对齐 rdb 同刻写入）。
- 原版调色板常量位于未反编译的 Compose 资源，`-7431250`（0xFF8E9BAE 石板灰蓝）
  为文档化本地默认色（ADR-0505 登记此适配）。

### 仓库（FolderRepositoryImpl.ets）

- `NoteFolder` +`color: number`、`emoji: string | null`、`updatedAt: number`；
  `queryFolders`/`folderBucket` 全列读写。
- `createFolder(name, parentId, color = FOLDER_DEFAULT_COLOR, emoji = null)`：
  `updatedAt = createdAt`（rdb 对齐）。
- 新 `editFolder(folderId, { name?, color?, emoji? })`：beb.e 对齐——未写字段不动、
  `updated_at` 恒盖 `Date.now()`、单事务；`emoji` 经 `normalizeFolderEmoji`
  （`null/''`→NULL，pdb.d() 空串即无）。
- `renameFolder` 委托 `editFolder({ name })`；`moveFolder` 桶内盖 `updated_at`
  （xdb 对齐：仅被移动文件夹盖章，兄弟行 sibling_order 归一化不算编辑、不盖章）。

### UI（LibraryPage.ets）

- `NameDialog` 扩展 `initialColor/initialEmoji` + `selectedColor/selectedEmoji`：
  名称输入下方新增 8 色色块行（首项 = `FOLDER_DEFAULT_COLOR`）与
  `∅`+10 个预设 emoji 行；`onConfirm(name, color, emoji)`。
- 新建对话框：默认色+无 emoji 打开；确认走 `createFolder(…, color, emoji)`。
- 重命名对话框：以文件夹当前 color/emoji 初始化；确认走
  `editFolder({ name, color, emoji })` 单次提交（id7.l 对齐）。
- `FolderNavigationRow`：名称前渲染 10dp 色点（`item.folder.color`）与 emoji
  （非 null 时）——侧栏与紧凑抽屉共用此 Builder，一处修改两处生效。

## 验证

- `docs/migration/replays/d02-original-folder-customization-parity.mjs`：56 项检查
  通过——原版锚点（e47/xo1/vdb/id7/xdb/pdb/w09/ac4/msb）14 项、Harmony
  schema/仓库/UI/fixture 锚点 32 项、可执行增量编辑模型 10 项。
- 全量 Desktop Replay：428/428（本仓根目录执行）。
- `hvigor clean` + `note@ohosTest` + `note@default`：全部 BUILD SUCCESSFUL，
  0 个 ArkTS ERROR；触改文件仅出现库内既有的 "may throw exceptions" 类警告。

## 残留差异（如实登记）

1. 原版 emoji 选择器是 flag 门控的分类网格（9 大类全量 emoji）；Harmony 为
   10 个常用预设 + 清除——记录为子集适配，后续可扩展为完整分类面板。
2. 原版调色板确切色值未从反编译产物恢复；`FOLDER_COLOR_PALETTE` 为文档化近似
   （首项锁定 `FOLDER_DEFAULT_COLOR`，与 DB DEFAULT 同源）。
3. 原版笔记行模型 `w09.folderColor` 用于 All Notes 列表内渲染文件夹色块；
   Harmony 笔记行当前不显示文件夹色——文件夹色已在文件夹行渲染，笔记行色块
   留作后续增强（与 SCHEMA-D3 持久化范围一致）。
4. 原版颜色恒非空（同步 schema NOT NULL）；Harmony `editFolder` 的
   `color?: number` 不接受 null——与原版一致，无"清除颜色"语义。
