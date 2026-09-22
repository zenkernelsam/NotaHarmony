# Phase 609 — 文本块按下点光标定位（ttc → qke + sqa）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-tap-caret-place-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0578-original-tap-caret-place.md`
- Replay：`d02-original-tap-caret-place.mjs`（12 项断言）

## 背景

原版 `dl1` case2：已选中的文本块（xhe）再被点按时产出
`ttc(blockId, jE)`（携带按下点世界坐标）；`uw2` case4 消费——
`qke` 激活该块编辑器（`uke.p` 挂起会话恢复），随后 `sqa` 把
按下点经 `zn9.f`（世界→局部）+ `rej.i`（布局偏移命中）定位
为光标偏移，**无条件覆盖**挂起光标；`tqa` 做链接探测。

Harmony 旧实现已覆盖"已选文本块再点→激活编辑"的结构，但只
恢复挂起光标、不按按下点定位——二次点按光标不落在点按字符
处，与原版"光标跟手"不符。

## 实现

- `Canvas2DTextRenderer.caretIndexAtPoint`：rej.i /
  `getOffsetForPosition` 等价——`inverseTransformPoint` 世界→
  局部，`layoutLines` 逐行取最近行带（y 钳制），命中行内
  `characterIndexAt` 半字宽拆分；越过行尾 → `line.end`，
  空文本 → 0。与 `linkAtPoint` 共用同一套布局/命中机制。
- `beginTextEditingAt`：qke 挂起恢复（既有）后计算 `tapCaret`
  并非空覆盖 `textEditingRestoreCaret`/`editingCaretOffset`
  ——sqa 无条件定位语义；同时覆盖 itc→ttc（insideOverlay
  ElementTap）与 TEXT 面点按两条激活路径。
- `TextBlockOverlay.onAppear` 的 `caretPosition` 消费不变；
  链接命中（tqa 等价）保持先于编辑激活。

## 验证

- Replay `d02-original-tap-caret-place.mjs`：12/12。
- 全量 Desktop Replay：SUITE pass=499 fail=0。
- `note@default` / `note@ohosTest` HAP 静态构建成功。

## 备注

- 本 Phase 期间 `NoteCanvasView.ets` 出现一次工具写入未落盘
  （edit 报成功但磁盘无改动），改经 node 直写落盘并复核
  grep/git status 确认。
