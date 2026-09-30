# Phase 1359 证据 — 字符串大小写/措辞修正（第二批）

延续 1358 —— 对原版 `strings.xml` 做系统化逐串比对，
修正第二批大小写/措辞差异（实改）。

## 修正（base，对照 strings.xml）

| key | 原值 | 修正为（原版） |
|-----|------|----------------|
| `new_note` | New note | **New Note**（`feature_note__default_title`/`shortcut_new_note`） |
| `add_page` | Add Page | **Add page**（`content_manager_add_page` 句首式） |
| `more_page_actions` | More Page Actions | **More actions**（`content_manager_more_actions`） |
| `copy_note_id` | Copy Note ID | **Copy note ID**（`feature_library__copy_note_id`） |
| `pages_deselect_all` | Deselect all | **Deselect All**（`ui_pageselection__deselect_all`/`library__deselect_all`） |
| `show_in_folder` | Show in Folder | **Show in folder**（`feature_library__show_in_folder`） |

## 判定为非缺陷（保留）

- `app_name`="Nota" —— 移植应用自身命名（非复用
  Notability 商标），正确。
- `empty_shared_notes_title` 缺失 —— 共享笔记页签在
  Harmony 无对应 section（协作功能 fail-closed），
  合理缺失。
- `jump_to_title`="Jump to page"/`jump_to_page_label`=
  "Page number" —— Harmony 更明确的对话框文案，保留。
- 大量 "missing" 原版串 = SDK/平台串（Navigate up/
  Voice search/androidx.startup）+ fail-closed 特性
  （login/feedback）—— 非 app UI 缺陷。

## zh_CN

对应键均为合理中文译法（无大小写问题）—— 无需改。

## 产出

- 6 处 base 串修正；fixture `d02-string-diffs.mjs`；
  ADR-1300；中文报告。
