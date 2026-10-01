# Phase 1422 证据 — 键盘快捷键帮助表（txm.a 复刻）

## 原版证据链（decompiled_1.4.2）

### 分发链
`vla.b(KeyEvent)` → `bma.a` → `lra.handleNavigationShortcut`（活动级，
`MainActivity.dispatchKeyEvent` 兜底——库内与编辑器内均生效）。
`qa8(76,12)=Ctrl+/` → `yla` → `open_help` 标签 → `lra.U(qw6.INSTANCE)`
帮助路由。原版经 **系统 `requestShowKeyboardShortcuts`** 弹出
KeyboardShortcutHelper；HarmonyOS 无系统等价 → 应用内复刻。

### 数据表 `txm.a`
合并 `cma.a` + `vla.c` + `f3b.a`（空死支）+ `syh.a`，按 `lag.c`
分组装 `KeyboardShortcutGroup`；每条 `qa8` → 一行
`KeyboardShortcutInfo(label, keyCode, mods)`。

**Navigation 组**（`app__kbd_shortcut_group_navigation`，cma 保序）：

| 和弦 | qa8 | 标签 | 动作 |
|---|---|---|---|
| Ctrl+N | (42,12) | new_note | xla |
| Ctrl+, | (55,12) | open_settings | zla |
| Ctrl+L | (40,12) | back_to_library | wla |
| Ctrl+/ | (76,12) | open_help | yla |
| Ctrl+Shift+N | (42,4) | new_window | vla.c |
| Esc | (111,14) | dismiss_deselect | cma 追加 |

**Text Editing 组**（`ui_text__kbd_shortcut_group_text_editing`，
`syh.a`=`ra8→qa8` et9.z0 保序，`ra8.F`=标签 res）：
Copy/Paste/Cut/Select All/Undo/Redo(双和弦 54,4+53,12→两行)/
Bold/Italic/Underline/Bullet/Numbered/Checkbox 列表/字号±/
Text Start/End(Alt+↑↓)/Deselect(Ctrl+\\)——17 动作 18 行。

## Harmony 实现

- `data/OriginalKeyboardChords.ets`：`ORIGIN_KBD_HELP_GROUPS` =
  `OriginalKeyboardHelpGroup{groupLabel:Resource, entries:{label:Resource,
  chords:string[]}[]}`，组/条目/和弦序与 txm 完全一致（REDO 双和弦
  展两行）。
- `NotePage.ets`：`@State showShortcutsHelp` + `Ctrl+/` KeyUp 置位
  （原 fail-closed noop 改为开面）+ `bindSheet` →
  `buildShortcutsHelpSheet`（组标题 + 逐和弦行 label/chord）+ ESC
  dismiss 链首插 `showShortcutsHelp` 早退。
- `LibraryPage.ets`：同一数据表 + `ShortcutsHelpSheet` Builder +
  Ctrl+/ 接线（活动级路由等价——原版库内 Ctrl+/ 同样弹出）+
  ESC 链早退。
- 25 键 en+zh 双语字符串（`app__kbd_shortcut_*`/`ui_text__kbd_shortcut_*`
  逐字原名；zh 按既有风格补写，原版无 zh 资源）。

## 差异登记

- 原版为系统模态对话框（KeyboardShortcutHelper）；Harmony 复刻为
  bindSheet（LARGE）——视觉形态差异属平台映射，数据内容逐项等价。
- Ctrl+N/Ctrl+Shift+N 条目仍列出（原版注册即显示，与实际可用性
  无关——忠实复刻注册表）。

## Replay

`d02-original-kbd-help-sheet.mjs`：16/16 绿；`d02-original-keyboard-
shortcuts.mjs` 重锚 Ctrl+/ 消费钉至帮助面接线（68/68 绿）。
