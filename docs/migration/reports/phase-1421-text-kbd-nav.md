# Phase 1421：文本域词/段界导航与 DELETE_PREV_CHAR 报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 12 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1421-text-kbd-nav.md`
- 决策：`docs/migration/adr/ADR-1357-text-kbd-nav.md`
- Replay：`docs/migration/replays/d02-original-text-kbd-nav.mjs`

## 目标

补齐 `e0b` 分发器 ctrl 支的 caret 导航和弦：Ctrl+←/→/↑/↓ 词/段界
移动、Ctrl+Shift+方向 选区扩界、Ctrl+H 删除前一字符——Harmony
此前不消费这些键（落回 TextArea 原生行内导航）。

## 原版证据链

| 原版 | 键码 | 动作 |
|------|------|------|
| `e0b` ctrl 支 `zs9.m/n` | DPAD_LEFT/RIGHT(21/22) | LEFT_WORD/RIGHT_WORD |
| `e0b` ctrl 支 `zs9.o/p` | DPAD_UP/DOWN(19/20) | PREV/NEXT_PARAGRAPH |
| `e0b` shift+ctrl 支 | 同上四键 | SELECT_*_WORD/PARAGRAPH |
| `e0b` `zs9.d` | KEYCODE_H(36) | DELETE_PREV_CHAR |

## Harmony 实现（`TextBlockOverlay.ets`）

`onEditorKeyEvent` 四支分发内新增：`ctrl&&shift&&!alt` 支四方向 →
`extendCaretSelection(词/段界)`；`ctrl&&!alt&&!shift` 支四方向 →
`caretPosition(词/段界)` + `2024(H)` → `deletePrevChar()`。
新增方法：`isWordChar`/`wordBoundaryLeft`/`wordBoundaryRight`/
`paraBoundaryUp`/`paraBoundaryDown`/`extendCaretSelection`/
`deletePrevChar`（删改复用 `adjustCharRunsForEdit`+`onDraftChange`）。

## 差异登记

- 词界 = `[\p{L}\p{N}_]` 近似 ICU BreakIterator（CJK 切分差异登记）。

## 验证

- `d02-original-text-kbd-nav.mjs`：12/12 绿；
  `d02-original-text-kbd-chords.mjs` 等邻域 fixture 绿。
- `REPLAY_BASELINE PASS=1273 FAIL=0`。
- `hvigorw assembleHap -p module=note@default`：BUILD SUCCESSFUL。
- clean + `note@ohosTest`：BUILD SUCCESSFUL（OhosTestCompileArkTS
  实际执行）。

## 提交内容

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-text-kbd-nav.mjs`（新）
- 证据/ADR/报告 + 三份追踪文档
