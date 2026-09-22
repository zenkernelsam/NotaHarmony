# ADR-0567 — 套索/矩形完成的最小尺寸门（uw2 case1，20dp/zoom）

- 状态：Accepted
- Phase 598；对齐 `uw2` case1/`oo3.a`/`fvb.a`（decompiled_1.0.3）。

## 背景

原版选区手势完成时先量绘制区域：`任一边 ≤ 20.0f/zoom →
fvbVar.a()` 取消——套索与矩形同约束，微拖动/误触点按不产生
微小选区。Harmony 的 `selectionDrawing` 收尾直接
`finalizeSelection`——无尺寸门，任何细小拖动都留下极小选区。

## 决策

1. `SelectionTool.drawnBounds()`：矩形模式返回 `state.rect`；
   套索模式返回 `lassoPoints` 外接矩形（空 → null）——
   `oo3Var.a()` 等价。
2. `onTouchUp` 的 `selectionDrawing` 分支在 `finalizeSelection`
   之前判定：`drawnBounds` 任一边 `≤ 20.0/viewport.zoom`
   → `deselect()` + `selectionVisible=false` 取消。
3. `deselect()` 补清 `lassoPoints`/`rect`——取消后无绘制残留
   （原版 `fvbVar.a()` 同样丢弃整个手势状态）。

## 偏差（fail-closed 记录）

1. 原版 `f3 = 20.0f/fK` 的 20 为屏幕 dp；Harmony `viewport.zoom`
   是屏幕像素/画布单位比，`20.0/zoom` 取同一折算语义——
   屏幕密度换算差异为平台适配。
2. 原版对小于阈值的点按**不**再进入 TapToSelect（取消即终）；
   Harmony 同样直接取消（该次手势已消费）。
3. 原版 `oo3Var.c/d`（手势内部字段）置空语义并入 `deselect()`
   的统一清空，无额外通道。

## 验证

- `docs/migration/replays/d02-original-selection-minimum-size.mjs`
  13 项断言（门序/阈值/双维/取消语义 + 边界可执行模型）。
- 证据：`docs/migration/evidence/original-selection-minimum-size-2026-09-23.md`。
