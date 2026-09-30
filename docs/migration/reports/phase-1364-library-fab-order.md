# Phase 1364 — 库创建 FAB 速拨菜单保真

## 摘要

库创建 FAB 展开菜单重排并修正标签，匹配原版 `cd` case 0：顺序 **Import →
Templates → DocScan → Create Note**（末位主操作），并改用原版键 `create_note`=
"Create Note"、`library_import`="Import"。`record_audio` chip 保留于首位
（ADR-0655 记载的旗控 "Record a lecture" 功能等价）。此前注释误引 `mw3`
（实为笔记内空态行）。

## 改动

- `note/.../LibraryPage.ets`：重排速拨 + 新增两键引用。
- `note/.../element/string.json`（EN/zh_CN）：`create_note`/`library_import`。
- `docs/migration/replays/d02-library-fab-order.mjs`：10/10。

## 备注

`import_note_file` 保留原值 "Import from .note File"（BackupPage 共用）；
`new_note` 保留（有效资源）。
