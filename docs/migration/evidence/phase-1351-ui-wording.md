# Phase 1351 证据 — UI 文案保真（string.json vs strings.xml）

来源：`note/src/main/resources/base/element/string.json`
（~915 串）vs `decompiled_1.0.3/resources/res/values/
strings.xml`。

## 逐字符串比对（widget/库/编辑器关键串）

| 原版 `strings.xml` | Harmony `string.json` | 结果 |
|--------------------|----------------------|------|
| `widget_folder_empty`=Tap to open Notability | "Tap to open Notability" | **逐字节** |
| `widget_folder_no_notes`=No notes in this folder | "No notes in this folder" | **逐字节** |
| `widget_recent_notes_empty`=No recent notes | "No recent notes" | **逐字节** |
| `widget_picker_no_notes`=No notes yet | "No notes yet" | **逐字节** |
| `widget_note_thumbnail_picker_title`=Choose a note | "Choose a note" | **逐字节** |
| `widget_folder_picker_title`=Choose a folder | "Choose a folder" | **逐字节** |
| `widget_note_picker_search_hint`=Search notes | "Search notes" | **逐字节** |
| `widget_new_note_label`=Create a new note | "Create a new note" | **逐字节** |
| `widget_recording_label`=Start recording | "Start recording" | **逐字节** |
| `widget_recent_notes_label`=Recent Notes | "Recent Notes" | **逐字节** |
| `widget_new_note_description`=Quickly create a new note. | "Quickly create a new note." | **逐字节** |
| `widget_recording_description`=Quickly create a new note with a recording. | 同 | **逐字节** |
| `widget_recent_notes_description`=Quick access to your recent notes. | "Show your recent notes." | 近似 |

## 结论

**所有展示/动作/空态/选择器串与原版逐字节一致**；
仅 `*_desc`（无障碍/卡描述）串轻微近似（"Show your
recent notes." vs "Quick access to your recent notes."）。

文件夹空态富文案（`This folder is empty…`/复数形态
`%d folders with %d notes`）亦保留原版措辞。

## Harmony 决策

UI 文案 = 原版 strings.xml 逐字节保真（用户可见串）；
卡描述（无障碍）近似 —— 文档化差异。

## 产出

- fixture `d02-ui-wording.mjs`（10 断言）。
- ADR-1292；中文报告。
