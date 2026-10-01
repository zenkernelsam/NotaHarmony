# Phase 1420 证据 — 文本编辑键盘和弦补齐 + DESELECT 更正

## 原版证据链（decompiled_1.4.2）

### 帮助表（用户可见契约）`syh.java`

`syh.a` = `ra8` 动作 → `qa8` 和弦集合，由 `txm` 分组注册进
Ctrl+/ 快捷键帮助表。`qa8(int keyCode, int mask)` 三参构造：

```java
this(i, (i2 & 2) == 0, (i2 & 4) == 0, (i2 & 8) == 0)  // bit 置位 = 修饰缺席
```

因此 mask 是"缺席位"：4=alt 缺席（ctrl+shift）、8=shift 缺席
（ctrl+alt）、10=ctrl+shift 缺席（alt）、12=alt+shift 缺席（ctrl）。

| ra8 动作 | qa8 | 解码和弦 |
|---|---|---|
| TOGGLE_BULLET_LIST | qa8(30,4) | Ctrl+Shift+B |
| TOGGLE_NUMBERED_LIST | qa8(40,4) | Ctrl+Shift+L |
| TOGGLE_CHECKLIST | qa8(31,4) | Ctrl+Shift+C |
| INCREASE_FONT_SIZE | qa8(19,8) | Ctrl+Alt+Up |
| DECREASE_FONT_SIZE | qa8(20,8) | Ctrl+Alt+Down |
| HOME（至文首） | qa8(19,10) | Alt+Up |
| END（至文末） | qa8(20,10) | Alt+Down |
| DESELECT | qa8(73,12) | **Ctrl+\\**（73=KEYCODE_BACKSLASH） |

### 运行时分发器 `e0b.java`（h3a/ya8 文本域 KeyEvent 拦截）

- 字体步进真实门：`isCtrlPressed() || !isAltPressed() || isShiftPressed()`
  的 else 支 = `alt && !ctrl && !shift`，Up→INCREASE、Down→DECREASE
  （`zs9.o=ofk.e(19)`、`zs9.p=ofk.e(20)`）。即运行时是 **Alt+Up/Down**，
  帮助表另列 Ctrl+Alt+Up/Down —— 两和弦在 Harmony 侧皆绑定为超集。
- DESELECT：`pa8.a(jE2, zs9.l)` → `ra8.DESELECT`，`zs9.l=ofk.e(73)`。
  Android KeyEvent 73 = **KEYCODE_BACKSLASH**。Harmony 早期
  Phase 695 误植为 Ctrl+D(2020)，本 Phase 更正。
- 列表切换：`e0b` 中另见 `!ctrl && shift` + B/L/C 支（疑似 Shift-only
  或脱字；若字面执行会与 Shift 键大写输入冲突）。以 `syh` 用户可见
  契约 Ctrl+Shift+B/L/C 为准，在 ADR 中登记该分歧。
- 其余块（复制/粘贴/剪切/全选/B/I/U/Home/End/方向/Tab/Esc）与
  Harmony 既有覆盖一致，无新增动作。

## Harmony 实现

`note/src/main/ets/ui/components/TextBlockOverlay.ets` →
`onEditorKeyEvent`，新增 alt/shift 修饰读取并按特异性排序分发：

| 和弦 | Harmony 键码 | 复用操作 |
|---|---|---|
| Ctrl+Alt+Up / Alt+Up | 2012 | `stepFontSize(1)` |
| Ctrl+Alt+Down / Alt+Down | 2013 | `stepFontSize(-1)` |
| Ctrl+Shift+B | 2018 | `toggleDecoratorStyle(1)` |
| Ctrl+Shift+L | 2028 | `toggleDecoratorStyle(2)` |
| Ctrl+Shift+C | 2019 | `toggleDecoratorStyle(3)` |
| Ctrl+\\ | 2061 | `collapseSelection()`（替代误植的 2020） |

约束：纯 Ctrl+B/I/U 现限定 `!shift && !alt`，避免 Ctrl+Shift+B 误触
加粗；全部沿用 `KeyType.Down` + `photoImportLeaseActive` 门控；
未消费的组合键返回 false 走系统默认（与原 1.0.3 移植语义一致）。

## 差异登记

- `syh` HOME/END=Alt+Up/Down 与 e0b 字体步进在同一和弦冲突——
  以运行时分发为准（Alt+Up/Down=字号步进）；文首/文末经既有
  Ctrl+Home/End(2081/2082) 覆盖。
- Ctrl+Z/Y：草稿级 undo 基建不存在（画布 UndoRedoManager 在提交层），
  fail-closed 维持登记。

## Replay

`docs/migration/replays/d02-original-text-kbd-chords.mjs`：
15/15 绿；`d02-original-text-keymap.mjs` Ctrl+D 钉已重锚 2061。
