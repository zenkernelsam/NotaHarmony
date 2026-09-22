# Phase 598 — 套索/矩形完成的最小尺寸门（uw2 case1，20dp/zoom）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-selection-minimum-size-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0567-original-selection-minimum-size.md`
- Replay：`docs/migration/replays/d02-original-selection-minimum-size.mjs`（13 项断言）

## 背景

原版选区手势完成（`uw2` case1）：`oo3Var.a()` 产出绘制区域，
`任一边 ≤ 20.0f/zoom → fvbVar.a()` 取消——套索/矩形同约束，
先于模式分支判定；微拖动视作点按不产生选区。

Harmony `selectionDrawing` 收尾直接 `finalizeSelection`——
无尺寸门，微小拖动留下极小选区。

## 实现

- `SelectionTool.drawnBounds()`：矩形→`state.rect`、套索→路径
  bbox（空→null），`oo3Var.a()` 等价。
- `onTouchUp` `selectionDrawing` 分支：`finalizeSelection` 之前
  判 `任一边 ≤ 20.0/viewport.zoom` → `deselect()` + 隐藏覆盖层。
- `deselect()` 补清 `lassoPoints`/`rect` 绘制残留。

## 偏差

见 ADR-0567 §偏差：dp/像素密度折算为平台适配；小于阈值的
点按同原版直接取消不进入 TapToSelect。

## 验证

- `node docs/migration/replays/d02-original-selection-minimum-size.mjs` → 13/13。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
