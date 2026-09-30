# Phase 1311 证据 — Harmony 渲染层覆盖（对照原版编辑器）

来源：`note/src/main/ets/rendering/`（22 文件）。

## 渲染栈（对照原版 Compose 编辑器）

```
CanvasViewport          缩放/平移+坐标映射  ≈ mv6/ry8 LayoutCoords
DirtyRectTracker        脏区增量渲染(zoom 换算 padding)
StrokeCanvasPainter/
StrokeLayerManager/
StrokeSession           笔画渲染/分层/会话 ≈ ka8 stroke+UndoRedo
EraserEngine +
OriginalInkPartialEraser/
OriginalShapePartialEraser/
OriginalPartialEraserTransientPreview
                        橡皮擦(部分/整体) ≈ ERASE_PARTIAL/
                        WHOLE+ORIGINAL_PARTIAL_ERASE
ImageCanvasRenderer/
MathCanvasRenderer/
ShapeCanvasRenderer/
PaperRenderer/
PdfRasterPlan           元素渲染器：图/数学/形状/纸纹/PDF
SelectionTool/TextBlockTool  选择/文本工具
StrokeClipboard/OriginalPageClipboard 笔画/页面剪贴板
ThumbnailRenderer/Policy  缩略图
UndoRedoManager         撤销重做
OriginalMathEngine      **native glmath**（ROOT_NAME=
                        'glmath' + measureNative/render→
                        nativeDraw —— GLMath 原生库已移植！）
```

## 语义

Harmony 渲染层 = **全功能编辑器渲染**（脏区+分层+
元素渲染器+部分橡皮+工具+缩略图+undo）+ **原生
GLMath**（LaTeX→GL 测量/绘制 —— 非 fail-closed，真
原生绑定）。

## Harmony 决策

渲染/编辑器全功能实现 + GLMath 原生库已移植 —
— 渲染语义高度保真。

## 产出

- fixture `d02-rendering-coverage.mjs`（10 断言）。
- ADR-1255；中文报告。
