# Phase 597 — 选区覆盖层旋转柄（msc.c selectionHasRotationHandle）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-selection-rotate-handle-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0566-original-selection-rotate-handle.md`
- Replay：`docs/migration/replays/d02-original-selection-resize.mjs`（更新至 28 项断言）

## 背景

原版 `msc.c = selectionHasRotationHandle`——覆盖层有专用旋转柄；
`qpi.b` 的 `f2=null → scale=1.0f` 即纯旋转通道（旋转角增量绕新
矩形中心应用）。Phase 596 角柄自由变换的角位移可产出旋转，但
径向分量同时产出缩放，不能"只旋转"。

## 实现

- `SELECTION_ROTATE_HANDLE_OFFSET=28vp`；`SelectionOverlay` 顶边
  中点上方绘制旋转柄（同角柄隐藏门控）。
- `onTouchDown`：角柄未命中 → 判旋转柄命中；命中进入同一
  `selectionResize` 会话，`resizeIsRotate=true`、`anchor=选区中心`、
  `resizeStart`=实际按点（环绕参考）。
- `applySelectionResize`：旋转模式 `scale=1`、`scaledCenter=anchor` →
  `resizeSelected(1, θ, center, center, base)` = 纯旋转矩阵
  （`qpi.b f2=null` 等价）；提交/取消复用既有通道。

## 偏差

见 ADR-0566 §偏差：柄位布局与包围盒不随旋转倾斜为适配记录；
出现条件未解码故常显。

## 验证

- `node docs/migration/replays/d02-original-selection-resize.mjs` → 28/28。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
