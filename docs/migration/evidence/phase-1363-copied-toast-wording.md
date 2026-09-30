# Phase 1363 — 复制确认 Toast 措辞保真

## 原版证据

- `feature_note__copied_link` = `Copied Link`（链接复制成功 toast）
- 原版复制类 toast 统一 `Copied X` 语序（`copied_link`/`copied_pdf_text`）。

## 修正（base）

| 键 | 旧 | 新 | 原版/约定 |
|----|----|----|-----------|
| link_copied | Link copied | Copied Link | `feature_note__copied_link` |
| note_id_copied | Note ID copied | Copied note ID | 对齐原版 `Copied X` 语序 |

调用点：
- `link_copied` — `NoteCanvasView:2046`、`TextBlockOverlay:1299` 链接复制 toast。
- `note_id_copied` — `LibraryPage:1212` 笔记 ID 复制 toast。

zh（`已复制链接`/`笔记 ID 已复制`）已是自然语序，不改。

## 刻意不改

- `new_note`="New Note"（库速拨创建 chip）：对 `app__shortcut_new_note`/`default_title`="New Note"
  家族语义成立，非 `feature_library__create_note`（主创建钮）语境，保留。
- `crop_reset`/`crop_confirm` 描述性 a11y（`accessibilityText`），优于原版短标签。
- `copied_pdf_text`/`clear_search`：Harmony 未实现对应 PDF 复制/搜索清除特性，不加死串。

## 验证

`d02-copied-toast-wording.mjs`：10/10（含调用点仍在用该键的断言）。
