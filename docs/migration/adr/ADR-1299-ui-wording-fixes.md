# ADR-1299：UI 文案修正（实改）

## 状态

已接受（Phase 1358）。

## 决策

修正 `string.json` 7 处文案为原版逐字节/原意 —
— 含 `untitled_note` 真实 bug（无标题笔记曾显
"New Note"→改"Untitled"/"未命名"）。

## 理由

Phase 1351 比对发现 widget `*_desc`+`untitled_note`
与原版不符。修正：`form_recent_notes_desc`/`form_
folder_notes_desc`/`form_folder_notes_display`/`untitled_
note`（base）+ zh_CN 4 处对应译法。`untitled_note`
被 7 调用点（库/卡片/编辑器/删除/导入/缩略图）作
无标题兜底 —— 修正后正确显示 "Untitled"。

## 后果

UI 文案真实修正（非文档）—— 无标题笔记文案 bug
修复 + widget 描述/标签逐字节对齐原版。
