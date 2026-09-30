# Phase 1358 证据 — UI 文案修正（实际代码改动）

对 Phase 1351 发现的近似/错误串做**实际修正**（非纯
文档）。来源：`resources/base|zh_CN/element/string.json`
vs 原版 `strings.xml`。

## base 修正（英文，对照 strings.xml 逐字节）

| key | 原值 | 修正为（原版） |
|-----|------|----------------|
| `form_recent_notes_desc` | Show your recent notes. | **Quick access to your recent notes.**（`widget_recent_notes_description`） |
| `form_folder_notes_desc` | Show notes from a folder. | **Quick access to notes from one of your folders.**（`widget_folder_description`） |
| `form_folder_notes_display` | Folder Notes | **Folder**（`widget_folder_label`） |
| `untitled_note` | New Note | **Untitled**（`shortcut_untitled_note`）—— **真实 bug**：无标题笔记曾显示"New Note" |

## zh_CN 修正（无原版 zh 基线，按英文原意译）

| key | 原值 | 修正为 |
|-----|------|--------|
| `untitled_note` | 新笔记 | **未命名** |
| `form_recent_notes_desc` | 展示你的最近笔记。 | 快速访问你的最近笔记。 |
| `form_folder_notes_display` | 文件夹笔记 | 文件夹 |
| `form_folder_notes_desc` | 展示某个文件夹中的笔记。 | 快速访问某个文件夹中的笔记。 |

## 影响面

`untitled_note` 被 7 处调用（库/卡片/编辑器/最近删除/
导入表/缩略图编辑页 —— `note.title.length>0 ? title :
untitled_note`）—— 修正后无标题笔记正确显示
"Untitled"/"未命名"。

## 说明

`empty_folder_with_children_body` 的 `%d`+`\n`（vs 原版
`%s`+`<br>`/`<b>`）为 ArkUI HTML→纯文本的文档化适配
（注释载明 note 计数在该投影恒为 0，无复数 bug）——
保留不改。

## 产出

- 7 处字符串修正；fixture `d02-ui-wording-fix.mjs`；
  ADR-1299；中文报告。
