# ADR-1404: Delete / Forward Delete 键盘删除选区（f2 → go(bd8,msf) 协程）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1469
- **关联**: evidence/phase-1469-keyboard-delete.md
  （`f2:247-253`/`go` case14/`sqf` case10/`urf.E`/`fq9.c0` 解码）

## 背景

原版编辑器键盘兜底链对 DEL(67)/FORWARD_DEL(112) 实现**选区删除**：
UP + 选区非空 → `go(bd8,msf)` 协程执行 `fq9.c0` 批量删除并清选；
DOWN 或无选区不消费透传。该支无修饰键门。静态证据显示其删除核
`wib.a.i0() + fq9.c0(w0g, elements, ofj, fm4.F) + ome.a()` 与选区
菜单 `wqf.P`（`urf.E`）完全相同。Harmony 此前无 Delete 键盘通路。

## 决策

- `OriginalKeyboardChords` 新增 `ORIGIN_KEYCODE_DEL=2055`、
  `ORIGIN_KEYCODE_FORWARD_DEL=2071`（Harmony 键码映射
  `ofk.e(67)/ofk.e(112)`）。
- `onCanvasKeyEvent` 的 `!textEditing` 块内新增删除支：
  `isUp && selection.isActive` → `onSelectionMenuAction(DELETE)`；
  其余情形 `return false` 透传（原版 `b2=0`）。
- 不设修饰键门——原版分支谓词不含 `db8.r`/`db8.s`。
- 复用菜单 DELETE 管线而非另起路径：经 bytecode 级证据确认两路
  同核（同一 `fq9.c0` + 清选），复用保证撤销/持久化/清选语义一致。

## 等价性与边界

- 撤销粒度：原版 `fq9.c0`→`d0` 一次批处理事务；Harmony
  `DELETE_ELEMENTS`/`DELETE_STROKE` 单撤销步——等价。
- 清选：原版 `ome.a()`；Harmony `clearSelectionWithRegisterReset()`
  ——等价。
- 遥测：原版经 `ofj` 参数埋点，Harmony 无遥测通路，fail-open 忽略
  （不影响文档语义）。
- 文本编辑态：`!textEditing` 门等价 `!(Q.m instanceof rsi)`——
  编辑中 DEL 由文本控件处理。

## 验证

- `d02-original-selection-delete-key.mjs` 17 项检查全绿。
- 键盘 fixture 族（shortcuts/kbd-chords/keymap/keyboard/key-tail/
  nudge）无回归；`note@default`、`note@ohosTest` HAP 构建通过。
