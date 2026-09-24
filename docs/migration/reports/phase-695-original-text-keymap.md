# Phase 695 — 原版文本编辑键盘快捷键（hke/k09/wl6）移植

## 范围

原版 `hke` 快捷键清单 + `k09` 按键分发中可忠实落地的子集：
Ctrl+B/I/U、Ctrl+A、Ctrl+Home/End、Ctrl+D/Esc 反选——
`wl6` 动作到 `TextArea.onKeyEvent` 的映射。

## 原版行为（证据见 phase-695 evidence）

- `hke.a`：12 项快捷键清单（COPY/PASTE/CUT/SELECT_ALL/UNDO/REDO/
  BOLD/ITALIC/UNDERLINE/HOME/END/DESELECT），组名 "Text Editing"。
- `k09`：`isCtrlPressed` 分发 + 词/段导航与 Shift 选区扩展
  （更大的 `wl6` 动作全集）。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `TextArea.onKeyEvent` → `onEditorKeyEvent`：仅 `KeyType.Down`、
    `photoImportLeaseActive` 短路、`getModifierKeyState(['ctrl'/'Ctrl'])`
    双写法兜底。
  - Ctrl+B/I/U → `toggleCharStyle`（P684 管线，选区/pending 语义一致）。
  - Ctrl+A → `controller.setTextSelection(0,len)`。
  - Ctrl+Home/End → `caretPosition(0/len)`（"Go to Start/End of Text"）。
  - Ctrl+D + Esc → `collapseSelection()`（caretPosition 折叠至 caret
    端 = wl6.DESELECT）。
  - 处理消费返回 `true`，未处理返回 `false` 放行原生行为。

## 验证

- Replay：`d02-original-text-keymap.mjs` 21 项全绿；
  lease-bound enabled 计数不变（无新按钮）。
- 构建：`note@default`/`note@ohosTest` clean assembleHap 成功
  （见提交记录）。
- 真机/模拟器：未验证（约束内）。

## 限制（登记差异）

- Ctrl+X/C/V：不拦截，走 TextArea 原生纯文本剪贴板——内部剪贴板的
  run 保留属后续缺口（原版内部剪贴板保留样式）。
- Ctrl+Z/Y：无草稿级 undo 基建；画布 `UndoRedoManager` 在提交层
  （Done 之后），编辑会话内 undo 为登记缺口。
- 词/段导航（Alt/Ctrl+方向）与 Shift 选区扩展：k09 的更大动作集，
  选区-模型同步成本高，登记为后续项。
- `getModifierKeyState` 大小写以双写法兜底；真机键盘行为待验收
  （已加 R-32 检查行）。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-text-keymap.mjs`
