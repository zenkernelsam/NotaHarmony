# 原版 1.4.2 文本专属模式（Text only）登记（Phase 773 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/res/values/strings.xml`、
>   `defpackage/{d6b,qf3,y07,yf2,ws3,xf3,zmb,chb,vii,anb}.java`
> 性质：1.4.2 版本差证据登记（**本地候选**）；无 Harmony 代码变更。

## 一、功能语义

1.4.2 新增**每笔记视图模式** "Text only"——隐藏非文本元素、
以纯文本排版优化阅读。

- 持久化：`NoteStateEntity.isTextOnly INTEGER NULL`（可空三态：
  NULL=未设置/默认关）。
- 读：`SELECT isTextOnly FROM NoteStateEntity where id = ?`（`ws3`）。
- 写：`UPDATE NoteStateEntity SET isTextOnly = ? WHERE id = ?`（`xf3`）。
- 迁移：`ALTER TABLE NoteStateEntity ADD COLUMN isTextOnly INTEGER
  DEFAULT NULL`（`zmb`，Phase 767 列增量）。

## 二、UX 链（字符串原文）

| 键 | 文案 | 语义 |
|---|---|---|
| `options_menu_text_only` | "Text only" | 笔记选项菜单切换项（`yf2`） |
| `text_only_banner_on_title/body` | "Text only mode on" / "…optimized as text only for easier reading. Go to Note options and turn off…" | 开启横幅 |
| `text_only_banner_off_title/body` | "Text only mode off" / "The view setting has changed to accurately display non-text elements" | 关闭横幅 |
| `text_only_banner_dismiss` | "Dismiss" | 横幅关闭钮（`qf3`） |
| `text_only_notice_message` | "This note contains non-text elements but is optimized as text only…" | 非文本元素提示 |
| `text_only_auto_exit` | "Showing the full note" | **自动退出**提示——向笔记加入非文本内容时自动关闭模式 |

渲染面：`d6b` 横幅组件（on/off/auto_exit 三态）、`qf3` dismiss 钮、
`y07` notice 条、`yf2` 选项菜单项；共 21 个文件触及该字段。

## 三、Harmony 现状

- `note/src/main/ets/core/model/NoteTypes.ets` 的 `NoteViewState`
  为 `NoteStateEntity` 的瘦身对应（noteId/zoom/scrollOffset/
  coordinateModelVersion），**无 isTextOnly 字段**。
- 无任何 text-only 视图模式实现。

## 四、分类

**版本差·本地候选**（纯本地特性，无后端依赖）：

- 可移植性高：状态列为单字段；渲染侧需隐藏非文本元素的排版路径；
- 1.0.3 无此功能——是否采纳属 1.4.2 回移决策，须经独立 Phase
  与用户确认，不在本阶段实现。
- 若采纳：语义为"隐藏 ink/image/shape 等非文本元素 + 三态横幅 +
  加入非文本内容时自动退出"。
