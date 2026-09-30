# Phase 1364 — 库创建 FAB 速拨菜单保真（`cd` case 0）

## 原版证据（`defpackage/cd.java` case 0）

库创建 FAB 展开的速拨菜单项按序渲染（`cwi.b`）：
1. `feature_library__import` = `Import`（importnewnote 图标，常驻）
2. `feature_library__templates` = `Templates`（`lc4.a(ac4.K0)` 旗标门控）
3. `feature_library__docscan` = `Document Scan`（`lc4.a(ac4.a0)` 门控）
4. `feature_library__create_note` = `Create Note`（`wp8.I` 强调主操作，**末位**）

`mw3` case 0（`feature_note__empty_note__*`：Record/Import/Scan/Capture）是
**笔记内空态**操作行，并非本库 FAB——此前注释误引。

## 差距

Harmony 原序：`new_note`(New Note) → `record_audio`(Record) → `import_note_file`
(Import from .note File) → `templates` → `docscan`。问题：
- 「Create Note」原为**末位主操作**，Harmony 却置顶且标签为 "New Note"。
- 「Import」原为 `feature_library__import`="Import"，Harmony 用 `import_note_file`
  ="Import from .note File"（该键还与 BackupPage 共用）。

## 修正

- `LibraryPage.FabButton` 速拨重排为 cd case-0 序：**Import → Templates → DocScan → Create Note**。
- `record_audio` chip 保留于首位：ADR-0655 记载其为旗控 "Record a lecture" 首页卡的功能
  等价（cd 本无此项；删除会丢失该入口）。`createAndRecord` 仍被该 chip 调用。
- 新增 `create_note`="Create Note"（zh `新建笔记`）、`library_import`="Import"（zh `导入`）。
- `import_note_file` 保留原值（BackupPage 另用）；`new_note` 保留（有效资源）。

## 验证

`d02-library-fab-order.mjs`：10/10（断言顺序 Import<Templates<DocScan<CreateNote、
Record 居首、键值正确）。`d02-original-new-note-quick-actions.mjs` 同步更新为新序
（原断言钉住旧 buggy 序 new_note→record_audio→import_note_file）。

## 附带：版本基线冲突消解

`d02-content-diff.mjs`（Phase 812）原断言 Harmony 键 = **1.4.2** 文案
（"Show in Folder"/"Copy Note ID"/"Take a photo"/"Math (LaTeX)"），与 Phase 1360
按 1.0.3 基线改的措辞冲突。ADR-0708 明确：移植基线=1.0.3，1.4.2 仅为
T-042 版本差证据树、非移植目标。故 Phase 1360 的 1.0.3 措辞正确，更新该
fixture 为断言 1.0.3 基线文案（上方版本差钉住段仍有效）。该 fixture 21/21。
