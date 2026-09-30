# Phase 1320 报告 — Form 卡片（≈ widget）

## 完成内容

- `NoteFormAbility`（`FormExtensionAbility`+`formBinding
  Data`/`formProvider`+`widget_bindings` formId→folder/
  noteId 绑定）+5 卡面逐项对照原版：`NewNoteCard`≈
  CreateNote(launch_action=create_note)、`NewRecording
  Card`≈CreateRecording(+auto_start_recording)、`Recent
  NotesCard`≈RecentNotes 4×2("No recent notes")、`Folder
  NotesCard`≈FolderNotes("No notes in this folder")、
  `NoteThumbnailCard`≈NoteThumbnail("Choose a note")+
  2 FormEditAbility≈配置 Activity —— widget 语义保真。

## 产出

- evidence `phase-1320-widget-cards.md`
- fixture `d02-widget-cards.mjs`（10/10）
- ADR-1264
