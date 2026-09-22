# ADR-0566 — 选区覆盖层旋转柄（msc.c selectionHasRotationHandle）

- 状态：Accepted
- Phase 597；对齐 `msc.c`/`qpi.b(f2=null)`/`fvb.f`/`avc`（decompiled_1.0.3）。

## 背景

原版选区菜单状态 `msc.c = selectionHasRotationHandle`——覆盖层
存在专用旋转柄。`qpi.b` 的 `f2=null → scale=1.0f` 分支给出
纯旋转路径：旋转角增量叠加基角并绕新矩形中心应用。

Phase 596 落地角柄自由变换（缩放+旋转），但专用旋转柄仍缺——
角柄拖拽的角位移虽可产出旋转，但径向分量同时产出缩放，
无法"只旋转"。

## 决策

1. `SelectionOverlay` 顶边中点上方 28vp 加旋转柄圆点
   （`SELECTION_ROTATE_HANDLE_OFFSET`，同 deselectMode/租约隐藏）。
2. `onTouchDown` 角柄未命中时判旋转柄命中；命中进入同一
   `selectionResize` 会话并置 `resizeIsRotate`：
   `anchor = 选区中心`（pivot 语义）、`resizeStart` = 实际按点
   （环绕参考）。
3. `applySelectionResize`：`resizeIsRotate` 时 `scale=1`、
   `scaledCenter=anchor=中心` → `resizeSelected(1, θ, center,
   center, base)` = 纯旋转矩阵——`qpi.b f2=null` 等价。
4. 提交/取消复用 `selectionDrag`/`selectionResize` 通道不变。

## 偏差（fail-closed 记录）

1. 原版旋转柄的精确屏幕位置（边中/角外侧）未能从 decompiled
   字节码精确定位——`msc.c` 只证明存在性；Harmony 取常见的
   顶边中点上方布局，功能等价。
2. 原版覆盖层矩形随旋转倾斜渲染（`g()` 提供旋转角）；
   Harmony `selectionRect` 为轴对齐包围盒——旋转柄视觉仍居
   包围盒顶边上方，不随旋转倾斜。变换语义等价。
3. `msc.c` 的条件出现规则（何种选区显/隐旋转柄）未解码；
   Harmony 对所有非锁定、非 deselectMode、非租约选区常显。

## 验证

- `docs/migration/replays/d02-original-selection-resize.mjs`
  更新至 28 项断言（旋转柄位置/anchor=中心/scale 锁 1）。
- 证据：`docs/migration/evidence/original-selection-rotate-handle-2026-09-23.md`。
