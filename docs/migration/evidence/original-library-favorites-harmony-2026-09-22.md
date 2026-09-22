# Harmony 证据：原版库收藏（Favorites）与分区奇偶 — 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）恢复库分区模型
`dk9`（ALL_NOTES / RECENT / FAVORITES / UNFILED）与笔记收藏位：
`modifyNote.isFavorited` 语义的部分更新、RECENT 的 `lastOpened`
降序前 10、上下文菜单 Favorite/Unfavorite、卡片收藏徽标与
Favorites 空态。

## 原版证据

### 分区枚举与渲染（dk9 / ua5 / pk9）

- `defpackage/dk9.java`：四值枚举
  `ALL_NOTES(R.string.feature_library__all_notes)` /
  `RECENT(feature_library__recent_notes)` /
  `FAVORITES(feature_library__favorite_notes)` /
  `UNFILED(feature_library__unfiled)`。
- `defpackage/ua5.java:227`：`for (dk9 dk9Var : dk9.M)` ——分区行
  把四个值渲染为可选 chip，`fk9Var.d == dk9Var` 标记选中。
- `defpackage/pk9.java:67`：`bsd.a(dk9.ALL_NOTES)` ——默认选中
  ALL_NOTES；选择文件夹即回到默认分区。

### 分区查询（mk9 / fh7 / apb）

- `defpackage/mk9.java`：RECENT 走
  `au1.N1(au1.K1(list, new fh7(13)), 10)` ——新近度降序、**前 10 条**，
  且不经过 `pk9.s` 的分区排序；其余分区走共享排序。
  同处 `dk9Var == dk9Var2 ? gb6.b0 : gb6.c0` ——RECENT 卡片日期取
  `lastOpened`（b0），其余分区取 `updatedAt`（c0）。
- `defpackage/fh7.java` case 13：交换参数比较
  `apb.F((j89) obj2)` vs `apb.F((j89) obj)` ——即按新近度**降序**。
- `defpackage/apb.java` `F`：`xgbVarC != null ? xgbVarC.I : j89Var.m()`
  ——`lastOpened` 覆盖存在则用，否则回退笔记自身时间戳。

### 数据模型（x17 / yp1 / dj5）

- `defpackage/x17.java:143` 合并查询：
  `COALESCE(cp.editFavorite, snm.favorite, 0) as favorite`、
  `COALESCE(cp.editLastOpened, snm.lastOpened) as lastOpened`
  ——favorite/lastOpened 是一等合并元数据；`setFavorite` /
  `setLastOpened` 为**部分 EDIT 行**（不带 createdAt/updatedAt），
  合并投影保持原 `snm.updatedAt`，即收藏/打开**不推进** updatedAt。
- `defpackage/yp1.java`：`modifyNote` 序列化
  `put("isFavorited", bool.booleanValue())` 与
  `put("lastOpened", xgbVar.I)` ——可选字段写入。
- `defpackage/dj5.java:48`：`HomeRecentNoteModel` 携带
  `isFavorited` 供卡片展示。

### UI 证据（d5j / gj9 / pf9 / strings）

- `defpackage/d5j.java:126`：上下文菜单项按当前标志选择
  `R.string.feature_library__unfavorite` /
  `R.string.feature_library__favorite`；原版菜单位序为
  Favorite → Move（Sort to folder）→ Delete（尾部）。
- `defpackage/gj9.java`：图标
  `ui_designsystem__unfavorite_outline` / `favorite_outline`
  按 `ek9Var.e` 切换。
- `defpackage/pf9.java:49`：笔记卡片渲染
  `ui_designsystem__favorite_fill` 徽标。
- `strings.xml`：`feature_library__favorite_notes`、
  `empty_favorite_notes_title`（"No favorite notes"）、
  `empty_favorite_notes_body`（"Favorite a note in its context
  menu for easy access from any folder in this tab."）、
  `home_favorite_notes_title`。

## Harmony 落点

### 仓储（RepositoryInterfaces.ets / NoteRepositoryImpl.ets）

- `LibrarySection` 枚举按 `dk9` 序：ALL_NOTES=0 / RECENT=1 /
  FAVORITES=2 / UNFILED=3。
- `getFavoriteNotes()`：`favorite=1 AND deleted_at IS NULL`，
  `updated_at DESC`（gb6.c0 投影）。
- `getRecentNotes()`：`deleted_at IS NULL`，
  `ORDER BY last_opened DESC, updated_at DESC LIMIT 10`（mk9 N1）。
- `getUnfiledNotes()`：`folder_id IS NULL AND deleted_at IS NULL`。
- `setNoteFavorite` / `touchNoteLastOpened`：**部分更新**——
  ValuesBucket 只写 `favorite` / `last_opened` 单列，
  `updated_at` 不动（x17 部分 EDIT 语义）；
  均走 `libraryMetadataMutationMutex.runExclusive`。
- `searchNotesInSection(query, section)`：分区谓词 +
  `EXISTS (SELECT 1 FROM search_item …)`，搜索限定在当前分区。

### 视图模型（LibraryViewModel.ets）

- `currentSection` 状态默认 ALL_NOTES（pk9 默认值）。
- `setSection` 清空 `currentFolderId`（分区与文件夹视图互斥）；
  `setFolder` 反向把分区重置回 ALL_NOTES。
- `queryNotes` 按分区派发：ALL_NOTES→`getAllNotes`、
  RECENT→`getRecentNotes`、FAVORITES→`getFavoriteNotes`、
  UNFILED→`getUnfiledNotes`；搜索态走 `searchNotesInSection`。
- `toggleFavorite`：`setNoteFavorite(noteId, !note.favorite)` →
  在 FAVORITES 分区中就地剔除已取消项（投影一致性），
  其余分区原地更新标志。
- `applySort` 在 RECENT 分区直接返回（mk9：RECENT 不经 pk9.s
  排序，序固定为 lastOpened 降序）。
- 删除/移动等既有变更后沿用 `queryNotes` 重读当前分区。

### UI（LibraryPage.ets）

- 侧栏与紧凑抽屉各渲染四枚 `SectionNavRow`（dk9 四值、图标 +
  本地化标签 + 选中态），点击 → `selectSection` →
  `vm.setSection` + 生命周期 generation 守卫。
- 上下文菜单按原版顺序：Favorite/Unfavorite（标签随
  `note.favorite` 翻转）→ Move → … → Delete（尾部）。
- 卡片右上角 `♥` 徽标（pf9 `favorite_fill` 落点，Stack
  `TopEnd` 叠加）。
- RECENT 分区卡片日期取 `note.lastOpened`（gb6.b0）。
- FAVORITES 分区空态：`empty_favorite_notes_title/body` 文案。
- `currentFolderName()` 在非 ALL_NOTES 分区返回分区名。

### 编辑器（NotePage.ets）

- 打开笔记时 `touchNoteLastOpened(this.noteId, Date.now())`
  ——原版的 `setLastOpened` 部分更新落点；置于既有打开
  生命周期内，不阻塞编辑器初始化。

## 登记适配差异

1. 原版 `ua5` 分区行为横向 chip 行；Harmony 库采用侧栏/抽屉
   导航模型，落点为纵向分区行——选择/高亮语义一致。
2. 原版 RECENT 固定 10 条为硬上限（`au1.N1(...,10)`）——
   Harmony 保留 `LIMIT 10`。
3. 图标 `favorite_fill`/`favorite_outline` → 文本字形 `♥` /
   `♡`（代码库文本字形约定，与 Phase 536 🔖 同例）。
4. `lastOpened` 写入时机：原版在打开路径多处打点（含缩略图
   预览）；Harmony 当前在编辑器打开处打点——预览/搜索跳转
   是否补点待后续观察，已登记。

## 验证

- 专项 replay `d02-original-library-favorites.mjs`：47 项断言
  全过（原版 dk9/ua5/pk9/mk9/fh7/apb/x17/yp1/d5j/gj9/pf9/dj5
  锚点 + Harmony 仓储/VM/UI/编辑器锚点 + 可执行分区投影与
  部分更新模型）。
- 既有锚点合法更新：`d02-library-delete-loading-bound.mjs`
  的重读派发改经 `queryNotes(query, folderId, section)`；
  `d02-original-compact-library-drawer.mjs` 的 all_notes 文本
  锚点改为 SectionNavRow 调用点；`d02-original-note-soft-delete-parity.mjs`
  的 `deleted_at IS NULL` 计数 2→5（新增三条分区查询同样排除
  已删笔记）。
- 全量 replay 432/432（仓根执行）。
- `note@default` + `note@ohosTest` 构建成功；0 个 ArkTS ERROR。
- ArkTS 测试：`LibraryViewModel.test.ets` 新增分区/收藏/上限/
  重置用例；FakeNoteRepository 实现新接口。
- 未启动模拟器、虚拟机、真机或 Hypium。
