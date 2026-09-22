# ADR-0571 — 选区手势挂起文本编辑器（pke / NoneActive）

- 状态：Accepted
- Phase 602；对齐 `uke.d`/`ct0`/`uw2`/`zl2`（decompiled_1.0.3）。
- 修正 Phase 594 的简化（块外点按一律销毁）。

## 背景

原版编辑器停用有两条路径：

- `oke.a`（TEXT 工具面 `zl2` 块外点按）→ 提交并销毁 `ake` 会话。
- `pke.a`（选区手势面 `ct0`/`uw2` 的 ClearSelection/TapToSelect、
  外部文本变更）→ 提交内容（`uke.d` 尾部 `mub` 写回）但 `ake`
  会话保留在 `uke.p`——再激活同块时恢复光标等会话状态。

Phase 594 把 Harmony 的块外点按统一为 `onTextCommit`（销毁），
丢失了 `pke` 的会话保留语义。

## 决策

1. `onTouchDown` 编辑中块外点按按工具分流：
   - `ToolType.DEFAULT`（原版 TEXT 工具面）→ `onTextCommit`（`oke`）。
   - 其余工具（dl1 选区分发面所覆盖的全部工具）→ `suspendTextEditing`。
2. `suspendTextEditing` = `onTextCommit` 提交（mub 写回等价）+
   `.then` 成功后 `suspendedCaretByBlock.set(blockId, caret)`——
   在 commit 的显式销毁分支清完旧条目后写入本次挂起值，避免竞态。
3. `beginTextEditingAt` 命中块 → `textEditingRestoreCaret` 取挂起值 →
   `TextBlockOverlay`（新增 `TextAreaController`）`onAppear` 恢复
   `caretPosition(min(caret, len))`；`onTextSelectionChange` 回写实时光标。
4. 显式销毁（Done/Cancel/oke 路径）`suspendedCaretByBlock.delete(id)`；
   页面切换 `clear()`（uke.p 按文档作用域）。

## 偏差（fail-closed 记录）

1. 原版 `ake` 会话保留的不止光标（滚动、IME 组合态、字段状态机）；
   Harmony 只恢复光标偏移——TextArea 无其余可恢复面。
2. 原版挂起由 `uke` 状态机管理（`p` map + CAS）；Harmony 以
   `Map<blockId, caret>` 平替，语义等价于"每块最近挂起光标"。
3. `uke:211` 外部文本变更触发挂起——Harmony 无对应多字段编辑面，
   该触发点不移植。

## 验证

- `docs/migration/replays/d02-original-textedit-suspend.mjs`（12 项断言）。
- `d02-original-textedit-outside-tap.mjs` 更新分流断言（8 项）。
- 证据：`docs/migration/evidence/original-textedit-suspend-2026-09-23.md`。
