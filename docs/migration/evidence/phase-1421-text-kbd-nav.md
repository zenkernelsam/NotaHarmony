# Phase 1421 证据 — 文本域词/段界导航 + DELETE_PREV_CHAR

## 原版证据链（decompiled_1.4.2）

`e0b.java`（`h3a`/`ya8` 文本域 KeyEvent 分发器）ctrl 支：

```java
if (pa8.a(jE2, zs9.m)) → LEFT_WORD        // zs9.m = ofk.e(21) = DPAD_LEFT
else if (pa8.a(jE2, zs9.n)) → RIGHT_WORD  // 22 = DPAD_RIGHT
else if (pa8.a(jE2, zs9.o)) → PREV_PARAGRAPH  // 19 = DPAD_UP
else if (pa8.a(jE2, zs9.p)) → NEXT_PARAGRAPH  // 20 = DPAD_DOWN
else if (pa8.a(jE2, zs9.d)) → DELETE_PREV_CHAR // zs9.d = ofk.e(36) = KEYCODE_H
else if (pa8.a(jE2, zs9.l)) → DESELECT    // 73 = BACKSLASH（P1420 已绑）
```

shift+ctrl 支（同文件 ~263 行区段）：
`zs9.m/n/o/p` → `SELECT_LEFT_WORD / SELECT_RIGHT_WORD /
SELECT_PREV_PARAGRAPH / SELECT_NEXT_PARAGRAPH`。shift=选区扩展语义与
`Shift+Home→SELECT_LINE_START`（zs9.t）同规则一致。

动作语义（Compose `TextPreparedSelection` 系）：
- LEFT_WORD → 上一词起点；RIGHT_WORD → 下一词终点（BreakIterator 词界）。
- PREV_PARAGRAPH → 段首上移；NEXT_PARAGRAPH → 下一段起点。
- DELETE_PREV_CHAR → 删 caret 前一字符（选区非空则删选区）。

## Harmony 实现

`TextBlockOverlay.ets` `onEditorKeyEvent` 既有四支分发上新增：

| 和弦 | 键码 | 操作 |
|---|---|---|
| Ctrl+Left/Right | 2014/2015 | `caretPosition(wordBoundary{Left,Right}(caretOffset))` |
| Ctrl+Up/Down | 2012/2013 | `caretPosition(paraBoundary{Up,Down}(caretOffset))` |
| Ctrl+Shift+←→↑↓ | 2014/2015/2012/2013 | `extendCaretSelection(同界)` |
| Ctrl+H | 2024 | `deletePrevChar()` |

新增私有方法：`isWordChar`（`[\p{L}\p{N}_]` Unicode 词字符近似
BreakIterator）、`wordBoundaryLeft/Right`（跳过非词字符+词字符），
`paraBoundaryUp/Down`（`\n` 段界；Up 在段首时退到上一段），
`extendCaretSelection`（`setTextSelection(anchor, pos)`，锚定端
`caretSelectionStart` + 移动端 `caretOffset` 语义保持供连按续扩），
`deletePrevChar`（选区非空删选区否则删前一字符，复用
`adjustCharRunsForEdit` + `onDraftChange` 管线——与 `handleTabKey`
同一变更模式）。

## 差异登记

- 词界算法以 `[\p{L}\p{N}_]` 近似 ICU BreakIterator（CJK 按字词规则
  与 Latin 词界行为有细微差——登记为近似移植）。
- `caretSelectionStart`/`caretOffset` 锚定/移动端语义经扩展操作手动
  保持；`onTextSelectionChange` 回调归一化后连按续扩依赖该保持。

## Replay

`d02-original-text-kbd-nav.mjs`：12/12 绿。
