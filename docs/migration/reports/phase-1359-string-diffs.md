# Phase 1359 报告 — 字符串大小写/措辞修正

## 完成内容

- 实改 6 处 base 串（对照 `strings.xml`）：
  `new_note`→"New Note"、`add_page`→"Add page"、
  `more_page_actions`→"More actions"、`copy_note_id`→
  "Copy note ID"、`pages_deselect_all`→"Deselect All"、
  `show_in_folder`→"Show in folder"。
- 判定保留：`app_name`="Nota"（移植命名）、
  `empty_shared_notes` 缺失（协作 fail-closed）、
  跳转对话框更明确文案。

## 产出

- 6 处修正；fixture `d02-string-diffs.mjs`（10/10）；
  ADR-1300
