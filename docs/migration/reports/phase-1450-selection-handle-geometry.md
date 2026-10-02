# Phase 1450 报告：选区手柄几何与式样对齐（gsf.b/e）

## 原版行为（1.4.2 反编译证据）

- **角柄**（`gsf.b`）：四角各绘双层同心圆——白半径 12dp + `#FF4278FF`
  半径 10dp（视觉 Ø24/20dp）。
- **旋转柄**（`gsf.e`+`gsf.i`）：锚点=右（RTL 左）**边中点**，
  `#FF444DE0` 2dp 茎线水平延出 56dp，端点双层圆白 16dp/`#FF444DE0`
  14dp（Ø32/28dp），中心 y 下偏 1dp。

## Harmony 缺口（修复前）

- 旋转柄悬于顶边中点上方 28vp——1.4.2 精证为**右侧茎式**（早前按
  iOS 惯例近似，实错）。
- 角柄单层小圆 Ø12vp（control+accent 描边）——原版双层 Ø24/20。
- 旋转柄单色——原版 `#FF444DE0`（与角柄蓝色不同源）。

## 本次改动

- `SelectionOverlayLayout`：新常量 `HANDLE_DOT_OUTER/INNER`、
  `ROTATE_HANDLE_STEM/DOT_OUTER/DOT_INNER`；移除 `ROTATE_HANDLE_OFFSET`。
- `SelectionOverlay`：角柄双层圆；旋转柄 = 右边中点茎（Rect）+ 端点
  双层圆。
- `NoteCanvasView.selectionRotateHandleAt`：命中域迁至茎端点。

## 验证

- 新增 fixture：`d02-original-selection-handle-geometry.mjs`（11 断言）；
  更新 `d02-original-selection-resize.mjs`。
- 证据：`evidence/phase-1450-selection-handle-geometry.md`；ADR-1385。
- 登记差异：RTL 锚左边未实现（固定右边）。

## 结果

全量基线与双 HAP 构建见提交信息。
