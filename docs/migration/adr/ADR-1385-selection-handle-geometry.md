# ADR-1385: 选区手柄几何与式样（gsf.b 双层角柄、gsf.e 右侧茎式旋转柄）

## 状态

已接受（2026-08，Phase 1450）

## 背景

`gsf.b`/`gsf.e` 精确尺寸此前未解：

- 角柄 = 四角各绘**双层同心圆**——`p52.e` 白半径 12dp +
  `gsf.a=#FF4278FF` 半径 10dp。
- 旋转柄锚点 `gsf.i` = **右（RTL 左）边中点**；`qe4.U` 绘
  `#FF444DE0` 2dp 茎线水平延出 56dp；端点双层圆（白半径 16dp /
  `#FF444DE0` 半径 14dp，中心 y+1dp）。

Harmony 此前：角柄=单层圆（control 底 + accent 描边 Ø12vp），旋转柄=
顶边中点上方 28vp 单层圆——位置与式样均不符 1.4.2（顶边悬置是早前按
iOS 惯例的近似）。

## 决策

1. 常量（`SelectionOverlayLayout`）：`HANDLE_DOT_OUTER/INNER`=24/20vp
   （半径 12/10dp）、`ROTATE_HANDLE_STEM`=56vp、
   `ROTATE_DOT_OUTER/INNER`=32/28vp；移除 `ROTATE_HANDLE_OFFSET`。
2. `SelectionOverlay`：角柄 = Stack 双层圆（白 Ø24 + 蓝 Ø20）；
   旋转柄 = 右边中点 Rect 茎（56vp×2vp `#FF444DE0`）+ 端点 Stack
   双层圆（白 Ø32 + `#FF444DE0` Ø28，y+1vp）。
3. `selectionRotateHandleAt` 命中域迁至茎端点圆心，半径 22vp 不变。
4. 手柄门控不变（deselectMode/photoImport/selectionHandlesHidden）。

## 登记差异

- RTL：原版锚左边中点且茎反向；Harmony 固定右边（布局方向感知留待后续）。

## 验证

- Fixture：`d02-original-selection-handle-geometry.mjs`（11 断言）；
  更新 `d02-original-selection-resize.mjs` 旋转柄断言。
- 证据：`evidence/phase-1450-selection-handle-geometry.md`。
