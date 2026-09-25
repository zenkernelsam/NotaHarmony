# ADR-0552: 全局 Hide/Reveal Tapes（会话级揭示集合对齐）

## Status

Accepted, 2026-09-28.

## Context

原版胶带遮盖层可通过 `o94` case14 的 Hide/Reveal Tapes 行整组开关：
`oh9`（OnToggleTapesRevealed）经 `ti9:360-380` 判定当前页可见胶带是否
已全部揭示，派发 `np0` case5 对 `NoteSessionState.revealedTape`
（`yd9.j`）做 `ys2.J` 并集/`ys2.H` 差集 —— 全揭示→整组隐藏，否则→整组
揭示。该集合**会话级、不持久化**，经 `gvb.k` 流入渲染参数；`i16` 仅在
元素 id 属于已揭示集合时抑制胶带图案层（`ifeVar=null`），笔迹本体照常
绘制。菜单标签由 `uf0` case4 的"任意已揭示"语义驱动（`jg9.n`）。

Harmony 此前既无 revealedTape 状态也无对应 UI——导入笔记中的胶带始终
显示图案层，无法按原版语义查看被遮盖内容。

## Decision

- `NoteCanvasView` 持有 `revealedTapeIds: Set<string>`（会话级，随画布
  存活、不持久化），与 `StrokeCanvasPainter.revealedTapeIds` 共享同一
  引用使门控即时生效。
- `StrokeCanvasPainter.renderStroke` 在 `renderSpec.tapePattern` 存在且
  id **不在**已揭示集合时才调用 `renderTapePattern` —— 揭示态 = 抑制
  图案层、保留笔迹本体（对应 `ifeVar=null` + `mwd.o` 烘焙路径）。
- `toggleTapesReveal()` 按原版 np0 case5：空集 no-op；全揭示→整组
  delete；否则→整组 add；随后重绘。
- `emitTapeRevealState()` 向 `NotePage` 发出 `(tapeCount, anyRevealed)`
  （`uf0` case4 ANY 语义）；页面加载/切页后刷新标签状态。
- `NotePage.buildEditorOptionsMenu()` 在 `pageTapeCount > 0` 时提供
  Hide/Reveal 行，标签 `anyRevealed ? hide_tapes : reveal_tapes`，动作
  `tapeToggleSignal++` 驱动画布 watcher。

## Consequences

- 揭示态呈现 = 去图案化（无 wet-reveal 动画层）：原版 `l0f.A`/`p0f`
  揭示层最终派发函数未反编译成功，fail-closed 记录于证据文档。
- 点按揭示（`xtc.b`→`ej9`）未移植：原版入口在胶带工具命中路径内，
  Harmony 尚无胶带工具入口；待胶带工具 epic 时一并补齐。
  **已闭环**：epic 于 Phase 583-588 落地——胶带工具入口（Phase 584 /
  ADR-0553）、点按揭示链路 `dl1→xtc.b→ej9→xo5`（Phase 586 /
  ADR-0555）、设置面 Hide/Reveal 行（Phase 588）。
- 入口位于编辑器 ⋮ 菜单而非胶带工具设置行：Harmony 工具箱尚无 REVIEW
  工具行；动作语义（作用于全部可见胶带）一致，表面位置偏差已记录。
  注：Phase 588 起 REVIEW 工具行内亦提供同款开关。
- 回放 `d02-original-tape-hide-reveal.mjs` 钉死门控、并/差集语义、
  标签翻转与字符串。
