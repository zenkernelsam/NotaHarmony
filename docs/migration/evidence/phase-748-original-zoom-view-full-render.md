# Phase 748 证据：原版 Zoom View 放大面 = 整页渲染栈投影（vgg）

> 证据基准：`decompiled_1.0.3/sources/`（JADX 反编译 1.0.3）。
> 本件只记 Zoom View **内容渲染范围**的硬证据；面板结构/控制条/旗标证据
> 见 `phase-747-original-zoom-view.md`。

## 1. 原版放大面渲染的是整页内容，不是仅笔画层

`defpackage/vgg.java`（Zoom View 的呈现器/状态宿主）构造函数注入六个依赖：

```java
public final class vgg {
    public final oze a;
    public final fvb b;
    public final uke c;
    public final hnf d;
    public final gc9 e;
    public final cga f;
    public int g;
    public final o5g h;
    public final uh3 i;
    public final ufb j;
    public final uh3 k;
    public vgg(oze ozeVar, fvb fvbVar, uke ukeVar, hnf hnfVar, gc9 gc9Var, cga cgaVar) { ... }
}
```

`oze/fvb/uke/hnf/gc9/cga` 即原版页面内容渲染栈（渲染会话、元素绘制器、
位图/资源装载与层管理）——Zoom View 复用与主画布同一条渲染管线，输出
只是换了放大变换后的目标表面。因此原版放大面呈现的是**页面全量内容**
（纸面底纹/PDF 底图 + 按 z-order 的墨迹/文本/形状/图片/数学块 + 正在书写
的活动笔画），而非独立的"笔画预览层"。

## 2. 变换模型（ggg.d/e 复核）

- `ggg.d magnification = 5.0f`：文档 px → 屏幕 px 的线性放大倍率；
- `ggg.c sourceRectDocPx`：放大窗在文档坐标系中的源矩形；
- 渲染等价于 `scale(mag) ∘ translate(-srcX, -srcY)` 后执行整页绘制。

## 3. Harmony 原状缺口（Phase 747 遗留近似）

Phase 747 的 `NoteZoomView` 内部持有独立 `StrokeCanvasPainter`，仅迭代
`strokes` + `liveStroke` 两个 prop 直绘——纸面底纹/PDF 底图、文本块、形状、
图片、数学块均不进入放大面，与 vgg 注入整页渲染栈的原版语义不符。

## 4. Harmony 修复落点（Phase 748）

- `NoteZoomView` 移除自带 painter/strokes/liveStroke/pageWidth/pageHeight
  props，改为单一 `renderContent(renderCtx, rawCtx, mag)` 回调；
- `NoteCanvasView.renderZoomPanelContent`：先 `paperRenderer.renderBackground`
  （含 PDF 底图/paperTexture/renderRect，zoom=mag），再走与主画布同一入口
  `renderOrderedElements(renderCtx, zoomLiveStroke, mag)`——z-order、audio-ink
  灰显、形状/图片/数学渲染器全部复用，活动 zoom 笔画以 transientTopStroke
  置顶；
- `renderOrderedElements` 新增第三参 `renderZoom`（默认 `this.viewport.zoom`），
  内部 mathRasterScale / renderShape / renderStroke / renderAudioLinkedStroke
  全部改吃该参数；
- `renderFrame()` 顶部：ZOOM 工具激活期间每次主画布重绘 `zoomPaintTick++`，
  使放大面成为整页内容镜像（撤销/重做/导入/页面设置即时反映）。

### 已知近似（登记，非缺陷）

- 放大面内不做主画布 `layerManager.composite` 位图缓存层——直接按序直绘，
  语义等价、性能更差但面板面积小；
- 含 partial-eraser 笔画的页面在放大面走有序直绘（不经过
  `compositeWithOrderedPartialEraser` 离屏层），极端叠加下混合效果可能有
  轻微差异；主画布语义不变。
