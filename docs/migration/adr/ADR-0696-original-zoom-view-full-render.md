# ADR-0696：原版 Zoom View 放大面按整页渲染栈投影（vgg）

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0695（Zoom View 面板移植）、`phase-748-original-zoom-view-full-render.md`

## 背景

Phase 747 移植的 `NoteZoomView` 内部持有独立 `StrokeCanvasPainter`，仅渲染
`completedStrokes` + 活动 zoom 笔画。复核 `vgg.java` 构造函数：Zoom View
注入 `oze/fvb/uke/hnf/gc9/cga` 六个依赖——即原版整页内容渲染栈，放大面
呈现的是与主画布同一条管线输出的全量页面内容（纸面 + z-order 全元素）。

## 决定

Harmony 放大面改为复用主画布内容管线，而非独立笔画渲染器：

1. `NoteZoomView` 删除自带 painter 与 `strokes`/`liveStroke`/`pageWidth`/
   `pageHeight` props，改为单一 `renderContent(renderCtx, rawCtx, mag)`
   回调——组件仍拥有放大变换（`scale(mag) ∘ translate(-srcX·mag,-srcY·mag)`）
   与 g0j 前进区覆盖层。
2. `NoteCanvasView.renderOrderedElements` 增加 `renderZoom` 形参
   （默认 `this.viewport.zoom`），mathRasterScale、renderShape、
   renderStroke、renderAudioLinkedStroke 全部改用该参数。
3. 新增 `renderZoomPanelContent`：`paperRenderer.renderBackground`（PDF 底图/
   paperTexture/renderRect 同主画布）→ `renderOrderedElements(ctx,
   zoomLiveStroke, mag)`。活动 zoom 笔画以 transientTopStroke 置顶，
   z-order、audio-ink 灰显、文本/形状/图片/数学渲染全部自动继承。
4. `renderFrame()` 顶部在 `ToolType.ZOOM` 激活时 `zoomPaintTick++`，
   使放大面对撤销/重做/导入/页面设置等一切内容变更实时镜像。

## 近似与边界（登记）

- 放大面不走 `StrokeLayerManager.composite` 位图缓存层，按序直绘——语义
  等价，主画布性能路径不变；
- 含 partial-eraser 笔画的页面在放大面不经 `compositeWithOrderedPartialEraser`
  离屏层，极端叠加下混合效果可能有轻微差异；
- 其余 Phase 747 已登记近似（180dp→180vp、落点判定停靠等）沿用不变。

## 验证

- 专项 Replay `d02-original-zoom-view.mjs` 扩展（renderContent 接线、
  renderZoom 形参、stroke-only props 移除等 pins）；
- 全量 Desktop Replay 见提交；
- `note@default` / `note@ohosTest` 双 HAP 构建成功。
