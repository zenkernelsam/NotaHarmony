# Phase 596 — 选区覆盖层角柄自由变换（htc.e / qpi.b / fvb.f）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-selection-resize-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0565-original-selection-resize.md`
- Replay：`docs/migration/replays/d02-original-selection-resize.mjs`（24 项断言）

## 背景

原版选区覆盖层可自由变换：`htc.e(commit, translate, scale, rotation,
pivot)` 由角柄手势驱动，`qpi.b` 以 pivot 等比缩放构矩阵、旋转角
单独累加并绕新矩形中心应用；`z=false` 预览 / `z=true` 提交。

Harmony 的 `SelectionOverlay` 此前只有虚线框 + 菜单按钮——
`scaleSelected`/`rotateSelected` 是死代码，选区完全不能缩放/旋转。

## 实现

- `SelectionOverlayLayout`：`SELECTION_HANDLE_SIZE=12vp` /
  `SELECTION_HANDLE_HIT_RADIUS=22vp`。
- `SelectionOverlay`：四角柄圆点（deselectMode/租约隐藏）。
- `NoteCanvasView`：`selectionResizeCornerAt` 屏幕命中（先于内部
  拖拽分支）；命中进入 `selectionResize` 会话——anchor=对角
  画布坐标、base=起始矩阵快照、baseCenter=起始选区中心；
  `positionLocked`/租约不产出。
- `applySelectionResize`：`scale=距离比`、`θ=绕 anchor 角位移`、
  `scaledCenter=anchor+scale·(baseCenter−anchor)` →
  `SelectionTool.resizeSelected` 重建 `R(scaledCenter)·S(anchor)·base`
  （对齐 `qpi.b` 非增量重建语义），每帧 `applySelectionTransform`
  预览、drop 复用 `selectionDrag` 通道单次 `TRANSFORM_ELEMENTS` 撤销；
  `cancelActiveInteraction` 恢复 `dragBefore*` 快照。

## 偏差

见 ADR-0565 §偏差：覆盖层为轴对齐包围盒（角柄随包围盒而非旋转
矩形角）；专用旋转柄未单独移植（角柄角位移已产出旋转）；等比
缩放与原版一致。

## 验证

- `node docs/migration/replays/d02-original-selection-resize.mjs` → 24/24。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
