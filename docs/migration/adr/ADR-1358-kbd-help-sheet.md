# ADR-1358 键盘快捷键帮助表（Ctrl+/ 应用内复刻）

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1422
- 接续：ADR-1356/1357（文本和弦）；证据：
  `docs/migration/evidence/phase-1422-kbd-help-sheet.md`

## 背景

原版 Ctrl+/（`yla`→`qw6` 路由）调系统 `requestShowKeyboardShortcuts`
弹出 KeyboardShortcutHelper，内容为 `txm.a` 构建的
KeyboardShortcutGroup 树（Navigation 6 条 + Text Editing 17 动作
18 行）。该路由是活动级分发——库内、编辑器内均生效。HarmonyOS 无
系统快捷键帮助面，此前 Ctrl+/ 按"无帮助面"消费 fail-closed——
但帮助表本身只是静态分组清单，属可复刻表面。

## 决策

1. **数据归一**：`ORIGIN_KBD_HELP_GROUPS` 落
   `data/OriginalKeyboardChords.ets`（与全部和弦常量同源），
   `Resource` 引用逐字原名 `app__kbd_shortcut_*`/
   `ui_text__kbd_shortcut_*`；组序=cma.a（vla.a 保序+vla.c+dismiss），
   条目序=syh.a（et9.z0 保序），REDO 双和弦展两行（每 qa8 一行的
   KeyboardShortcutInfo 语义）。
2. **表面复刻**：两处消费点（NotePage 编辑器、LibraryPage 库内——
   对应原版活动级路由）各挂 `bindSheet(LARGE)`，同一数据渲染
   组标题+逐行 label/chord。
3. **触发/关闭**：Ctrl+/ KeyUp 置态（与既有和弦同 KeyUp 触发模式）；
   ESC dismiss 链首插 `showShortcutsHelp` 早退（先于
   docScan/sheet/多选链），下滑关 sheet 由 bindSheet 内建承接。

## 备选与拒绝

- **维持 fail-closed**：拒绝——静态帮助表无平台依赖，复刻即等价。
- **CustomDialog 而非 bindSheet**：bindSheet 与既有面板一致
  （PageOverview/TemplateGallery 同款），且自带拖拽关闭。

## 后果

- Ctrl+/ 从 noop 消费升级为开帮助面；库内同级生效。
- 25 键 en+zh 双语资源新增。
- Replay：`d02-original-kbd-help-sheet.mjs`（16 钉）；
  `d02-original-keyboard-shortcuts.mjs` 重锚。
