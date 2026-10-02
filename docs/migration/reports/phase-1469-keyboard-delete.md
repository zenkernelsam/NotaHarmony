# Phase 1469 报告：Delete / Forward Delete 键盘删除选区

## 原版行为（1.4.2 证据）

键盘兜底链 `f2.java:247-253`（`!rsi` 非文本编辑门内、`!pa8.W` 块内）：

- **键位**：`pa8.O = ofk.e(67)` = KEYCODE_DEL；`pa8.P = ofk.e(112)` =
  KEYCODE_FORWARD_DEL——两键同支处理，语义无差别。
- **无修饰键门**：分支谓词只测键码，Ctrl/Shift 不参与——
  Ctrl+Del、Shift+Del 同样删除。
- **动作门**：仅 `lxm.a(o,1)` = KeyUp 触发；Down（含长按重复）
  落 `b2=0` 不消费透传。
- **选区门**：`d63.f.F.getValue()` 当前选区非空才消费，否则透传
  （退格语义留给文本控件/系统）。
- **执行**：`go(byte14, bd8, msf)` 协程 = `wib.a.i0()` 取页句柄 →
  `oag.x2(q9l.a(i4(msf.h()), em4.F×3))` 选中 id 解元素 →
  `fq9.c0(w0g, elements, ofj, fm4.F)` 批量删除 → `ome.a()` 清选。
- **同核验证**：选区菜单 `wqf.P`(DELETE) → `sqf` case10 → `urf.E`
  内部同一 `wib.a.i0 + fq9.c0 + 清选`——键盘与菜单共享删除核。
- `msf.h()` 为原始选中 id 集，分发层不滤锁定元素。

## Harmony 缺口

`onCanvasKeyEvent` 未接管 DEL/FORWARD_DEL——按键无删除通路。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_DEL=2055`、
  `ORIGIN_KEYCODE_FORWARD_DEL=2071`（Harmony 键码）。
- `onCanvasKeyEvent` `!textEditing` 块内（DPAD nudge 支之后）：
  DEL/FORWARD_DEL 且 `isUp && selection.isActive` →
  `onSelectionMenuAction(SelectionMenuAction.DELETE)`；
  Down 或无选区 → `return false` 透传（`b2=0` 等价）。
- 复用菜单 DELETE 管线：id 收集→删除→撤销步→持久化→
  `clearSelectionWithRegisterReset()`（`ome.a()` 等价）——
  经 bytecode 级证据确认与原版同核，不另起路径。

## 验证

- 新 fixture `d02-original-selection-delete-key.mjs`：17 项
  （键码 pin、无修饰门、UP+选区门、透传语义、链序、管线复用、
  可执行门控模型 4 例）。
- 键盘族 fixture（shortcuts/kbd-chords/keymap/keyboard/key-tail/
  nudge 共 7 件）无回归。
- `note@default` 构建通过；全量基线与 `note@ohosTest` 收尾验证。

## 遗留差异

- 原版 `fq9.c0` 携带 `ofj` 分析埋点——Harmony 无遥测通路，
  fail-open 忽略（不改文档语义）。
- 锁定元素过滤在原版发生于 `fq9.d0` 内部或选区构建层；
  Harmony DELETE 不额外过滤，与 `msf.h()` 原始 id 集语义一致。
