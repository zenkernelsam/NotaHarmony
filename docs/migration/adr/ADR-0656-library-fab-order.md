# ADR-0656 — 库创建 FAB 速拨菜单对齐 `cd` case 0

## 状态

已接受（Phase 1364）。

## 背景

库创建 FAB 展开的速拨菜单，原版实现位于 `defpackage/cd.java` case 0：
按序 **Import → Templates（旗控）→ Document Scan（门控）→ Create Note（末位主操作）**。
Harmony 此前序为 New Note → Record → Import-from-.note → Templates → DocScan，
且注释误引 `mw3`（实为笔记内空态行），标签亦偏离原版键。

## 决定

1. 速拨项重排为 cd case-0 序：`library_import` → `templates` → `docscan` → `create_note`。
2. 新增 `create_note`="Create Note"（原版 `feature_library__create_note`）与
   `library_import`="Import"（原版 `feature_library__import`）；`import_note_file`
   保留原值（与 BackupPage 共用）。
3. `record_audio` chip 保留于首位——ADR-0655 记载的旗控 "Record a lecture"
   首页卡功能等价；cd 本无此项，但删除会丢失该入口。`createAndRecord` 仍被其调用。

## 后果

- 原版 FAB 项的顺序与标签与 `cd` case 0 完全一致；
- Record 作为额外等价项居首，不干扰原版四项的相对序；
- 修正了 `mw3`→`cd` 的引用错误。

## 验证

`d02-library-fab-order.mjs`：10/10。
