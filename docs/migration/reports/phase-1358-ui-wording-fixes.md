# Phase 1358 报告 — UI 文案修正（实改）

## 完成内容

- **实际代码修正** 7 处 `string.json` 文案：
  - base：`untitled_note` `"New Note"`→`"Untitled"`
    （**真实 bug**——无标题笔记在库/卡片/编辑器/删除/
    导入/缩略图 7 处曾显"New Note"）；
    `form_recent_notes_desc`/`form_folder_notes_desc`/
    `form_folder_notes_display` → 原版逐字节。
  - zh_CN：`untitled_note`→"未命名" + 3 处对应译法。
- 确认 `empty_folder_with_children_body` `%d`+`\n` 为
  ArkUI HTML→纯文本的文档化适配（注释载明计数恒 0，
  无复数 bug）—— 保留。

## 产出

- 7 处字符串修正（base+zh_CN）
- fixture `d02-ui-wording-fix.mjs`（10/10）
- ADR-1299
