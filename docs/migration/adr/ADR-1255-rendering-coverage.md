# ADR-1255：渲染层覆盖

## 状态

已接受（Phase 1311）。

## 决策

Harmony 渲染层全功能实现（脏区+分层+元素渲染+部分
橡皮+工具+缩略图+undo）+ GLMath 原生库已移植 —
— 渲染语义保真。

## 理由

`rendering/`(22)：CanvasViewport/DirtyRect/StrokeLayer/
EraserEngine+部分橡皮/Image·Math·Shape·Paper·PdfRaster
渲染器/Selection·TextBlock 工具/剪贴板/缩略图/undo +
`OriginalMathEngine`(`glmath` 原生 measure/render 真绑定)
—— 编辑器渲染全功能+原生数学。

## 后果

Harmony 编辑器渲染全功能+GLMath 原生 —— 渲染语义
高度保真（原生库真移植非降级）。
