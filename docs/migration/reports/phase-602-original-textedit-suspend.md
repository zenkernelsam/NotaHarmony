# Phase 602 — 选区手势挂起文本编辑器（pke / NoneActive）

- 日期：2026-09-23
- 结果：已实现对齐（修正 Phase 594 的销毁-only 简化）
- 证据：`docs/migration/evidence/original-textedit-suspend-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0571-original-textedit-suspend.md`
- Replay：`d02-original-textedit-suspend.mjs`（12 项）+ `d02-original-textedit-outside-tap.mjs`（8 项）

## 背景

原版编辑器停用二分：

- `oke.a`（`zl2` TEXT 工具面块外点按）→ 提交并销毁 `ake` 会话。
- `pke.a`（`ct0`/`uw2` 选区手势分发、外部文本变更）→ 内容照常
  提交（`uke.d` 尾部 `mub` 写回），`ake` 会话保留在 `uke.p`——
  再激活同块恢复光标。

Phase 594 将块外点按统一为销毁，丢失 `pke` 会话保留。

## 实现

- `onTouchDown` 编辑中块外点按分流：DEFAULT(TEXT 面) →
  `onTextCommit`（oke）；其余工具 → `suspendTextEditing`（pke）。
- `suspendTextEditing`：commit 成功后写 `suspendedCaretByBlock`。
- `beginTextEditingAt` 命中块 → `textEditingRestoreCaret` 取挂起值；
  `TextBlockOverlay` 新增 `TextAreaController` + `caretPosition` 恢复
  + `onTextSelectionChange` 回写光标。
- Done/Cancel/页面切换清除挂起条目。

## 偏差

见 ADR-0571 §偏差：仅恢复光标（滚动/IME 态无可恢复面）；
`uke:211` 外部变更挂起点不移植。

## 验证

- 专项 12/12 + 更新件 8/8；`note@default` 构建 0 错误。
