# Harmony 证据：原版笔记卡片文件夹标签（folder chip）奇偶 — 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）恢复库列表卡片上的
文件夹标签 chip：合并投影携带 `folderName`/`folderColor`，卡片在
两者非空时渲染实心颜色胶囊 + 文件夹名；同行补上录音 mic 指示。

## 原版证据

### 投影模型（w09 / fk9）

- `defpackage/w09.java`：库笔记模型字段 `f`=folderId(utf)、
  `g`=folderName(String)、`h`=folderColor(`Integer` 可空)、
  `i/j/k/l/m` 布尔（含 shared/recordings 标志）。
- `fk9.java` 的 Loaded 状态以 `List<w09>` 承载——folderName/
  folderColor 随每条笔记投影下发（合并查询的字段，与 `x17`
  合并元数据同源）。

### 卡片渲染（cti / e5j / i2j / kkf / w3j）

- `defpackage/cti.java:94-186`（`cti.c` 卡片）：`num=w09Var.h`、
  `str=w09Var.g`；`str == null || num == null` → 不渲染，
  否则 `e5j.b(str, num, uz4Var, 0)`。同一尾随行：
  `w09Var.l` → `record_mic_outline`（a11y =
  `feature_library__recordings`）；`w09Var.k` →
  `library_shared_outline`。
- `defpackage/e5j.java:34`：`b` 在两者非空时转发
  `i2j.b(num.intValue(), ..., str)`。
- `defpackage/i2j.java:28`：chip =
  `iu1.b(0.5f, kkf.d(i))` 0.5dp 文件夹色描边 +
  `w3j.c(..., 1.0f, kkf.d(i), hde.M)` **实心**文件夹色填充
  （`w3j.c` → `d01` background 元素，alpha=1.0）+ `tpe.b(str,…)`
  名称文本（颜色 `0L` 未指定 → 样式默认，`are.Q` 不带色）。
- `kkf.java:1104`：`((long) i2) << 32` —— int ARGB → Compose
  Color 打包。

## Harmony 落点

### 模型与仓储（NoteTypes / NoteRepositoryImpl / FolderRepositoryImpl）

- `NoteMeta` 增加 `folderName: string | null` /
  `folderColor: number | null`（w09.g/h 对位）。
- `attachFolderProjection(store, notes)`：收集非空 folderId →
  单条 `SELECT id, name, color FROM folder WHERE id IN (…)` →
  就地回填；挂在全部 8 个列表出口（All/Folder/搜索/Favorites/
  Recent/Unfiled/分区搜索/回收站）+ `getNote`/`createNote`/
  `createNoteWithMeta` 单笔记路径。
- `note_meta.folder_id` 为 `ON DELETE SET NULL`——被删文件夹
  不会留下悬空 chip。
- `FolderRepositoryImpl.queryAllNotes`（文件夹删除的 committed
  列表）同样回填——幸存文件夹中的笔记保留标签。
- `folder.color` 在 Harmony 为 `NOT NULL`（Phase 533 登记决策：
  原版 Integer 可空，本地每文件夹解析为具体色），故"filed ⇒
  chip 可见"与原版的非空条件一致。

### 视图模型与页面（LibraryViewModel / LibraryPage）

- `noteWithFolder`/`noteWithFavorite` 携带投影字段；
  `publishCommittedNoteMove(noteId, folderId, folderName,
  folderColor)` 由调用页从 `this.folders` 解析目标文件夹的
  name/color——移动即时投影正确，committed 重读后由仓储回填校准；
  `publishCommittedFolderDelete` 的 unfiled 路径置空。
- `NoteCard` 日期行后新增尾随 Row：
  `folderName !== null && folderColor !== null` → 实心文件夹色
  胶囊（`folderChipColor` 归一化为 `#AARRGGBB`）+ 对比度文本
  （`folderChipTextColor` 亮度阈值 ≥150 → 暗字，否则白字）；
  `hasRecordings` → `🎙` 图标 + `recordings` a11y。

## 登记适配差异

1. 原版 chip 为 0.5dp 同色描边 + 实心填充；Harmony 直接实心填充
   （同色描边视觉冗余，省略已登记）。
2. 原版 chip 文本色 = 样式默认（`are.Q` 不带色）；Harmony 采用
   亮度对比文本以保证全调色板可读——登记为适配差异。
3. 图标 `record_mic_outline`/`library_shared_outline` → `🎙`
   文本字形；shared 标志 Harmony 无共享模型，未渲染（功能范围）。
4. 原版 chip 在文件夹内部视图同样渲染（`cti.c` 无视图条件）——
   Harmony 保持一致。

## 验证

- 专项 replay `d02-original-note-folder-chip.mjs`：33 项断言
  全过（w09/cti/e5j/i2j/kkf/w3j 锚点 + Harmony 投影/VM/UI 锚点 +
  可执行可见性/颜色归一化/对比度/移动投影模型）。
- 既有锚点合法更新：`d02-library-note-move-identity-bound.mjs`
  的 publish 调用点按新签名更新。
- 全量 replay 433/433（仓根执行）。
- `note@default` + `note@ohosTest` 构建成功；0 个 ArkTS ERROR。
- 未启动模拟器、虚拟机、真机或 Hypium。
