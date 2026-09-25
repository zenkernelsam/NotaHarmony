# Phase 719：`ui_text__` 族尾部收口

`ui_text__*`（74 键）审计收尾：核心面（格式/列表/对齐/链接/字体
样式字号行距/27 语言代码块）此前已随文本工具条阶段移植，余 6 项
——3 项可移植落地，3 项边界登记。

## 原版证据

- `fie.java:19`：文本工具项描述符 `yz.j("Add Text")`（唯一 label
  源，`uke:341` 注册）。
- `bn5.java:127`：链接对话框标题按 `en5.c`（选区已带链接）择一
  "Edit hyperlink"/"Insert hyperlink"。
- `i8j.java:42`：代码块语言菜单 `koi.a` 带 "Programming language"
  标题。
- `hke.java`/`kmi.java`：`kbd_shortcut_*`×12 注册为系统
  `KeyboardShortcutGroup`（Android `onProvideKeyboardShortcuts`
  快捷键帮助表）——HarmonyOS 无对位面。
- `ir4`/`br2`/`whh`：格式按钮动态样式名兜底 "Format"、字号 chevron
  a11y——前者需具名样式字段（Harmony 预设为 {bold,fontSize} 原子）、
  后者无 chevron 节点，均登记边界。

## 实现

- `toolTypeLabel` 默认分支 + 工具栏加项菜单：`text`→`add_text`
  （"Add Text"/"添加文本"）。
- `openLinkSheet`：`linkSheetIsEdit = linkUrlAt(s,e).length>0`，
  `buildLinkSheet` 顶部标题行 insert/edit 择一。
- 代码语言 `bindMenu` 加 `{ title: programming_language }`。
- 新串 ×5 双 locale（add_text/insert_hyperlink/edit_hyperlink/
  programming_language/fontsize——fontsize 备档未接线）。

## 验证

- `d02-original-ui-text-tail-labels.mjs`（22 断言：fie/bn5/i8j/hke/
  kmi/ir4 证据点 + 三处移植接入 + 双 locale）。
- `ui_text__*` 族全量审计完毕（ADR-0667）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
