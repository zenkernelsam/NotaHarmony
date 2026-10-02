# ADR-1403: 方向键微移选区（f2 → guf.g ntf/otf 通道移植）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1468
- **关联**: evidence/phase-1468-keyboard-nudge.md
  （`f2`/`bd8.j0,l0`/`guf.t,u`/`ms1:784` 解码）

## 背景

原版编辑器键盘兜底链（`f2`）对纯 DPAD 方向键实现**选区微移**：
DOWN → `ntf(±2.0 文档单位, isRepeat)` 步进，UP → `otf.a`
NudgeEnd 收尾；无选区时降级为视口滚动 10% 视口尺寸；触摸到达
亦终结微移。Harmony 此前方向键完全未接管。

## 决策

- `OriginalKeyboardChords` 新增 Harmony DPAD 键码 2012..2015 +
  `ORIGIN_SELECTION_NUDGE_STEP=2.0` + `ORIGIN_KEY_SCROLL_FRACTION=0.1`。
- `selectionNudgeActive` 会话标记：首步捕 `dragBefore*` 快照，
  `applySelectionTransform` 以快照为基线重建（transform 累积
  无重复应用）；UP/触摸 → `endSelectionNudgeCommit` 单条
  TRANSFORM_ELEMENTS 撤销步。
- 修饰键排除 `ctrl/shift/alt`（f2 链 `db8.q/r/s` 等价）；
  `!textEditing` 块内分发（`Q.m instanceof rsi` 门等价）。
- `r9a.k()==0` 空事务跳过 → `isIdentityTransform` 门等价。

## 等价性与边界

- 撤销粒度：原版每步 `x()` 事务化（transient op），Harmony 以
  会话级单撤销步提交——可观察行为（撤销一次回到微移前）一致。
- 差异：`u7b.g` 键盘光标模式降级支未复刻（默认 true 等价）；
  越页微移 fail-closed；isRepeat 语义由长按重复 Down 自然覆盖。

## 验证

- `d02-original-selection-nudge.mjs`：18 项——键码/步长 pin、
  分发结构 pin、双支实现 pin、提交门 pin、可执行累积模型
  （3 步累积单提交、抵消零位移不提交、空收尾 no-op）。
- 全部键盘 fixture 无回归；`note@default` 构建通过。
