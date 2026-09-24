# Phase 695 — 原版文本编辑键盘快捷键（hke/k09/wl6）Evidence

## 范围

把原版文本编辑器的硬件键盘快捷键（`wl6` 动作集）中可在 Harmony
现有基建内忠实落地的子集移植到 `TextBlockOverlay` 的 TextArea。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/hke.java` —— 快捷键清单

`hke.a` 为 `cad` 列表（组名 `ui_text__kbd_shortcut_group_text_editing`
= "Text Editing"）：

```java
Map mapD0 = uy7.d0(
  new k1a(wl6.COPY,            vl6(31,12)),
  new k1a(wl6.PASTE,           vl6(50,12)),
  new k1a(wl6.CUT,             vl6(52,12)),
  new k1a(wl6.SELECT_ALL,      vl6(29,12)),
  new k1a(wl6.UNDO,            vl6(54,12)),
  new k1a(wl6.REDO,            vl6(54,4) 或 vl6(53,12)),   // Ctrl+Shift+Z / Ctrl+Y
  new k1a(wl6.TOGGLE_BOLD,     vl6(30,12)),
  new k1a(wl6.TOGGLE_ITALIC,   vl6(37,12)),
  new k1a(wl6.TOGGLE_UNDERLINE,vl6(49,12)),
  new k1a(wl6.HOME,            vl6(19,10)),
  new k1a(wl6.END,             vl6(20,10)),
  new k1a(wl6.DESELECT,        vl6(73,12)));
```

对应字符串：`kbd_shortcut_copy/paste/cut/select_all/undo/redo/
bold/italic/underline/text_start("Go to Start of Text")/
text_end("Go to End of Text")/deselect`。

### 2. `sources/defpackage/k09.java` —— 按键分发

`keyEvent.isCtrlPressed()` 分支映射 wl6 动作（COPY/PASTE/CUT/
SELECT_ALL/TOGGLE_BOLD/ITALIC/UNDERLINE/REDO/UNDO + 词/段导航与
Shift 选区扩展：LEFT_WORD/RIGHT_WORD/PREV_PARAGRAPH/
NEXT_PARAGRAPH/SELECT_LEFT_WORD 等）。

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| TOGGLE_BOLD (Ctrl+B) | `keyCode===2018` → `toggleCharStyle('bold')` |
| TOGGLE_ITALIC (Ctrl+I) | `2025` → `toggleCharStyle('italic')` |
| TOGGLE_UNDERLINE (Ctrl+U) | `2037` → `toggleCharStyle('underline')` |
| SELECT_ALL (Ctrl+A) | `2017` → `controller.setTextSelection(0,len)` |
| HOME ("Go to Start of Text") | Ctrl+`2081`(MOVE_HOME) → `caretPosition(0)` |
| END ("Go to End of Text") | Ctrl+`2082`(MOVE_END) → `caretPosition(len)` |
| DESELECT | Ctrl+`2020`(D) + Esc(`2070`) → `collapseSelection()` 折叠至 caret |
| COPY/CUT/PASTE | TextArea 原生剪贴板（不拦截；run 保留差异登记） |
| UNDO/REDO | 登记缺口——草稿级 undo 无基建（画布 UndoRedoManager 在提交层） |
| 词/段导航、Shift 扩展 | 登记缺口（选区模型同步面大） |

修饰键检测：`event.getModifierKeyState(['ctrl'/'Ctrl'])`
（API 12+ 可选方法，双大小写兜底）；仅 `KeyType.Down`；
`photoImportLeaseActive` 下短路。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-text-keymap.mjs`：
  21 项静态钉全绿。
