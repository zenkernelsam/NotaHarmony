# ADR-1357 文本域词/段界导航与 DELETE_PREV_CHAR 和弦

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1421
- 接续：ADR-1356（文本和弦契约）；证据：
  `docs/migration/evidence/phase-1421-text-kbd-nav.md`

## 背景

`e0b` 文本域分发器 ctrl 支除已移植的样式/剪贴板和弦外，还有一组
 caret 导航：`Ctrl+←/→` → `LEFT_WORD`/`RIGHT_WORD`（词界），
`Ctrl+↑/↓` → `PREV_PARAGRAPH`/`NEXT_PARAGRAPH`（段界），
`Ctrl+Shift+方向` → `SELECT_*_WORD/PARAGRAPH`（选区扩界），
`Ctrl+H` → `DELETE_PREV_CHAR`。Harmony `onEditorKeyEvent` 此前
未消费这些键（方向键落回 TextArea 原生行内导航）。

## 决策

1. **复用既有选区模型**：`caretSelectionStart`（锚定端）+
   `caretOffset`（移动端，`onTextSelectionChange` 语义）天然支持
   shift 扩界——`extendCaretSelection` 调 `setTextSelection(anchor, p)`
   并手动回写两字段保持连按续扩语义。
2. **词界近似**：原版走 ICU BreakIterator；以 `[\p{L}\p{N}_]` Unicode
   词字符近似（左=词首、右=词尾的 Compose 方向语义保持不变）。
   CJK 按字切分差异登记为近似移植。
3. **段界** = `\n` 分隔；`paraBoundaryUp` 在段首时退上一段起点，
   `paraBoundaryDown` 取下一段起点（末段后→文末）。
4. **Ctrl+H**（zs9.d=ofk.e(36)）→ `deletePrevChar`：选区非空删选区，
   否则删 caret 前一字符，复用 `adjustCharRunsForEdit` +
   `onDraftChange` 管线（与 `handleTabKey` 同变更模式）。

## 备选与拒绝

- **依赖 TextArea 原生 Ctrl+方向**：ArkUI 原生不保证词/段界语义与
  Compose 一致，且无法表达 SELECT_*_PARAGRAPH——须显式实现。
- **ICU BreakIterator 移植**：无鸿蒙等价物可用；近似算法登记差异。
- **不改原生 Shift+方向**：字符级 Shift+←→ 由 TextArea 原生处理，
  仅 Ctrl+Shift+方向 走扩界分支（与原版分发层级一致）。

## 后果

- caret 导航/扩界和弦对齐原版；`deletePrevChar` 覆盖原 Ctrl+H。
- 登记差异：词界近似（BreakIterator→Unicode 词字符）。
- Replay：`d02-original-text-kbd-nav.mjs`（12 钉）。
