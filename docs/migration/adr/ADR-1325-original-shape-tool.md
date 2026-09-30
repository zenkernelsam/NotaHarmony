# ADR-1325 — 1.4.2 SHAPE 工具：拖拽成形专用管线（非 ink 管线）

- 状态：已接受
- 日期：2026-08（Phase 1389）
- 证据：`docs/migration/evidence/phase-1389-original-shape-tool.md`

## 决策

以「拖拽-预览-提交」专用管线实现 1.4.2 新增的 SHAPE 工具，**不走** ink 笔画管线：

1. **几何忠实**：`ShapeDragGeometry.buildDragShape` 逐字移植原版 `u5g.java`
   的拖拽→形状映射——包围盒 → RECTANGLE/ELLIPSE/DIAMOND/TRIANGLE 闭合形，
   起终点线段 → LINE/ARROW（ARROW 端点 `ShapeArrowHead.SINGLE`），
   拖拽 ≤6.0 不产形；约束修饰 = 面积形状取正方形、线/箭头 45° 吸附。
2. **手势独立**：`NoteCanvasView` 为 SHAPE 加 `shapeDragActive`/`shapeDragStart`/
   `previewShape` 状态——按下锚定、移动经 `buildDragShape` 实时成形预览
   （强制 orderedRender 渲染）、松手 `commitShapeDrag` 提交。SHAPE 不产生
   `StrokeSession`/ink batch，亦不参与 hold-recognize。
3. **同步身份同径**：提交的 `ShapeElement` 复用与笔画/识别形一致的
   `originalInkReservation` 预留 → `id=encodeOperationId(ts,site)` +
   `originalCreate=OriginalShapeCreateMetadata`，persist 层照常发 CREATE_SHAPE。
   按 `OriginalCreateShapePayloadEncoder` 校验补 `originalTool=0(Pen)`/
   `originalStyle=1(MONO)`。
4. **持久化忠实**：`tool_state` 增 `shape_kind TEXT DEFAULT 'RECTANGLE'`（枚举名
   存储，与原版 `ca3.java:404` 一致）+ `nib_*`/`stabilization`（DB v71→72 迁移）。
5. **UI 忠实**：`shape` 四层 glyph（fill/outline/overlay/shadow）+ "Shape" 标签 +
   6 类选择页（`ShapeKindPicker`，对应 `h5g` 图标+标签选择器）+
   Secondary 托盘 index5 默认（`cc3.H()`）。

## 显式差异（已记录于证据）

- 约束修饰 `constrain` 已接通但无 stylus-button 源 → 当前默认自由拖拽。
- 线型选择器（`line_style_*`）未移植——本阶段产形为 solid MONO。
- MyScript `HwrEngineService`（手写识别引擎）为专有 SDK 域 → fail-closed。
