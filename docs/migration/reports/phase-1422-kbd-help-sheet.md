# Phase 1422：键盘快捷键帮助表（Ctrl+/ txm 复刻）报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 16 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1422-kbd-help-sheet.md`
- 决策：`docs/migration/adr/ADR-1358-kbd-help-sheet.md`
- Replay：`docs/migration/replays/d02-original-kbd-help-sheet.mjs`

## 目标

把原版 Ctrl+/ 帮助路由（`yla`→`qw6`→系统 KeyboardShortcutHelper）
从 fail-closed 消费升级为应用内复刻：`txm.a` 的
KeyboardShortcutGroup 树是纯静态分组清单，HarmonyOS 无系统对等
表面，以 bindSheet 等价落地。

## 原版证据链

- `txm.a`：`cma.a + vla.c + f3b.a(空) + syh.a` →
  `KeyboardShortcutGroup{label, KeyboardShortcutInfo[]}`；
  `lag{labelRes, groupRes, qa8[]}`，每 qa8 一行。
- Navigation 组（`cma`）：Ctrl+N New Note / Ctrl+, Open Settings /
  Ctrl+L Back to Library / Ctrl+/ Open Help / Ctrl+Shift+N New
  Window / Esc Dismiss or deselect。
- Text Editing 组（`syh`，`ra8.F` 标签）：17 动作 18 行（REDO
  Ctrl+Shift+Z + Ctrl+Y 双行）。
- 活动级分发（`bma.a`/`lra`/`MainActivity.dispatchKeyEvent`）——
  库内与编辑器内均可触发。

## Harmony 实现

- `OriginalKeyboardChords.ets`：`ORIGIN_KBD_HELP_GROUPS` 数据表
  （`Resource` 标签 + 和弦文本），组/条目序与 txm 逐项一致。
- `NotePage.ets`：`showShortcutsHelp` 态 + Ctrl+/ KeyUp 开面 +
  `bindSheet` + `buildShortcutsHelpSheet` + ESC 链早退。
- `LibraryPage.ets`：同表面 `ShortcutsHelpSheet` + Ctrl+/ 接线 +
  ESC 链早退（活动级路由等价）。
- 字符串：`app__kbd_shortcut_*`/`ui_text__kbd_shortcut_*` 25 键
  en+zh（zh 按既有风格补写）。

## 差异登记

- 系统模态 → bindSheet 形态差异（平台映射，内容逐项等价）。
- 帮助表忠实列出全部注册和弦（含 Ctrl+N/New Window 等
  不可用项——原版注册表静态展示，与可用性无关）。

## 验证

- `d02-original-kbd-help-sheet.mjs`：16/16 绿；
  `d02-original-keyboard-shortcuts.mjs` 重锚后 68/68 绿。
- `REPLAY_BASELINE PASS=1274 FAIL=0`。
- `hvigorw assembleHap -p module=note@default`：BUILD SUCCESSFUL。
- clean + `note@ohosTest`：BUILD SUCCESSFUL（OhosTestCompileArkTS
  实际执行）。

## 提交内容

- `note/src/main/ets/data/OriginalKeyboardChords.ets`
- `note/src/main/ets/ui/editor/NotePage.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `note/src/main/resources/base/element/string.json` /
  `zh_CN/element/string.json`（25 键）
- `docs/migration/replays/d02-original-kbd-help-sheet.mjs`（新）+
  `d02-original-keyboard-shortcuts.mjs`（重锚）
- 证据/ADR/报告 + 三份追踪文档
