# Phase 1320 证据 — Harmony Form 卡片（≈ 原版 widget）

来源：`noteformability/NoteFormAbility.ets` + `pages/`
卡面。

## `NoteFormAbility` = `FormExtensionAbility`

`forms_config.json` 声明卡片；`formBindingData`/`form
Provider` 下发；`widget_bindings` JSON 存 formId→
folderId/noteId（Harmony 无活动实例枚举 API → filesDir
JSON）—— 卡片绑定持久化。

## 卡面 ↔ 原版 widget（逐条对照+原版文案）

```
NewNoteCard     ≈ CreateNoteWidgetProvider(2×2)
                postCardAction→launch_action=create_note
                →LaunchActionIngress→createAndLaunch
NewRecordingCard ≈ CreateRecordingWidgetProvider(2×2)
                launch_action=create_recording_note+
                auto_start_recording_applied(一次性)
RecentNotesCard ≈ RecentNotesWidgetProvider(4×2)
                VIEW+show_recent；行=48dp thumb+标题；
                空态 "No recent notes"；nbnote:<id>
FolderNotesCard ≈ FolderNotesWidgetProvider
                folderId 绑定；"No notes in this folder"
NoteThumbnailCard ≈ NoteThumbnailWidgetProvider(2×2)
                widget_bindings["note_"+id]；"Choose a
                note"；VIEW+note_id
```

## 编辑 = 配置 Activity 等价

`FolderFormEditAbility`/`NoteThumbnailFormEditAbility`
（type=formEdit）≈ `FolderNotesConfigActivity`/`Note
ThumbnailConfigActivity` —— 卡片配置写回 widget_bindings。

## 语义

Form 卡片 = **原版 widget 逐项保真移植** —— 尺寸/
点击 intent→launch_action/绑定/空态文案/配置页 —
— widget 语义高度保真。

## Harmony 决策

AppWidget→`FormExtensionAbility`+`formBindingData`+
`widget_bindings` 绑定；配置页→`FormEditAbility` —
— widget 语义保真（含原版文案/空态）。

## 产出

- fixture `d02-widget-cards.mjs`（10 断言）。
- ADR-1264；中文报告。
