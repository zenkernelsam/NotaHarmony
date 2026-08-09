// T-013 分层渲染管理器（任务卡 T-013，REVERSE_ANALYSIS §19/§37 低延迟分层架构）
// 已完成层（OffscreenCanvas 缓存）+ 当前笔画层 + 脏矩形增量重绘
// 渲染层实现：允许 import Canvas 类型；不 import UI 组件
import { Rect2D } from '../core/model/GeometryTypes';
import { StrokeElementData, InkStyle } from '../core/model/StrokeTypes';
import { StrokeRenderer, RenderContext } from '../core/adaptation/StrokeRenderer';
import { Canvas2DRenderContext, Canvas2DOffscreenRenderContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { DirtyRectTracker } from './DirtyRectTracker';

export class StrokeLayerManager {
  private completedLayer: OffscreenCanvas | null = null;   // 已完成笔画缓存
  private completedCtx: OffscreenCanvasRenderingContext2D | null = null;
  private completedRenderCtx: Canvas2DOffscreenRenderContext | null = null;
  private completedBitmap: ImageBitmap | null = null;
  private completedBitmapDirty: boolean = true;
  private renderer: StrokeRenderer;
  private dirtyTracker: DirtyRectTracker;
  private pageWidth: number = 0;
  private pageHeight: number = 0;
  private previousCurrentBounds: Rect2D | null = null;

  constructor(renderer: StrokeRenderer) {
    this.renderer = renderer;
    this.dirtyTracker = new DirtyRectTracker(3);
  }

  // 初始化/重建 OffscreenCanvas（页面 onReady 或 resize 时调用）
  initialize(width: number, height: number): void {
    this.releaseCompletedBitmap();
    this.pageWidth = width;
    this.pageHeight = height;
    this.completedLayer = new OffscreenCanvas(width, height);
    this.completedCtx = this.completedLayer.getContext('2d', new RenderingContextSettings(true));
    this.completedRenderCtx = new Canvas2DOffscreenRenderContext(this.completedCtx);
    this.completedBitmapDirty = true;
    this.previousCurrentBounds = null;
    this.markFullPageDirty();
  }

  // 将完成笔画渲染到已完成层
  commitStroke(stroke: StrokeElementData, _renderCtx: RenderContext, zoom: number = 1): void {
    if (this.completedRenderCtx === null) {
      return;
    }
    this.renderStrokeOnto(stroke, this.completedRenderCtx);
    this.completedBitmapDirty = true;
    this.dirtyTracker.markDirty(stroke.bounds, zoom);
  }

  // 每帧合成：已完成层 + 当前笔画 → 主画布（脏区 clipRect 限制重绘范围）
  composite(mainCtx: CanvasRenderingContext2D, currentStroke: StrokeElementData | null,
    currentRenderCtx: RenderContext, renderBackground: () => void = () => {},
    renderForeground: () => void = () => {},
    zoom: number = 1): void {
    if (this.previousCurrentBounds !== null) {
      this.dirtyTracker.markDirty(this.previousCurrentBounds, zoom);
    }
    if (currentStroke !== null) {
      this.dirtyTracker.markDirty(currentStroke.bounds, zoom);
    }
    const dirtyRegions: Rect2D[] = this.dirtyTracker.consume();
    this.previousCurrentBounds = currentStroke !== null ? this.cloneRect(currentStroke.bounds) : null;
    if (dirtyRegions.length === 0) {
      return;
    }
    mainCtx.save();
    mainCtx.beginPath();
    for (const dirty of dirtyRegions) {
      mainCtx.rect(dirty.left, dirty.top, dirty.right - dirty.left, dirty.bottom - dirty.top);
    }
    mainCtx.clip();
    for (const dirty of dirtyRegions) {
      mainCtx.clearRect(dirty.left, dirty.top, dirty.right - dirty.left, dirty.bottom - dirty.top);
    }
    renderBackground();
    const completed: ImageBitmap | null = this.getCompletedBitmap();
    if (completed !== null) {
      mainCtx.drawImage(completed, 0, 0, this.pageWidth, this.pageHeight);
    }
    if (currentStroke !== null && currentRenderCtx !== null) {
      this.renderStrokeOnto(currentStroke, currentRenderCtx);
    }
    renderForeground();
    mainCtx.restore();
  }

  // 全屏合成（无脏区优化）：纸张背景每帧重绘场景使用，避免脏区清屏破坏背景
  // 调用方需先绘制背景，本方法仅叠加已完成层与当前笔画
  compositeFull(mainCtx: CanvasRenderingContext2D, currentStroke: StrokeElementData | null,
    currentRenderCtx: RenderContext): void {
    // This path redraws the full frame, so earlier dirty bounds have been satisfied.
    this.dirtyTracker.consume();
    this.previousCurrentBounds = currentStroke !== null ? this.cloneRect(currentStroke.bounds) : null;
    const completed: ImageBitmap | null = this.getCompletedBitmap();
    if (completed !== null) {
      mainCtx.drawImage(completed, 0, 0, this.pageWidth, this.pageHeight);
    }
    if (currentStroke !== null && currentRenderCtx !== null) {
      this.renderStrokeOnto(currentStroke, currentRenderCtx);
    }
  }

  // 清空全部（新建笔记/撤销全部）
  clearAll(): void {
    if (this.completedCtx === null) {
      return;
    }
    this.completedCtx.clearRect(0, 0, this.pageWidth, this.pageHeight);
    this.completedBitmapDirty = true;
    this.markFullPageDirty();
  }

  // 撤销/擦除后重建：清空已完成层 → 逐笔重新渲染
  rebuildFromStrokes(strokes: StrokeElementData[], _renderCtx: RenderContext): void {
    if (this.completedCtx === null || this.completedRenderCtx === null) {
      return;
    }
    this.completedCtx.clearRect(0, 0, this.pageWidth, this.pageHeight);
    for (const s of strokes) {
      this.renderStrokeOnto(s, this.completedRenderCtx);
    }
    this.completedBitmapDirty = true;
    this.markFullPageDirty();
  }

  isInitialized(): boolean {
    return this.completedLayer !== null;
  }

  dispose(): void {
    this.releaseCompletedBitmap();
    this.completedLayer = null;
    this.completedCtx = null;
    this.completedRenderCtx = null;
    this.pageWidth = 0;
    this.pageHeight = 0;
    this.previousCurrentBounds = null;
    this.dirtyTracker.consume();
  }

  // 按 renderSpec 分发渲染路径（中心线 / 可变宽度轮廓 / PencilSplat），随后应用擦除遮罩
  // 渲染前应用 stroke.transform（选区变换支持）
  private renderStrokeOnto(stroke: StrokeElementData, rc: RenderContext): void {
    const c: Canvas2DRenderContext = rc as Canvas2DRenderContext;
    if (stroke.maskPath.length > 0) {
      const isolatedLayer = new OffscreenCanvas(this.pageWidth, this.pageHeight);
      const isolatedCtx: OffscreenCanvasRenderingContext2D =
        isolatedLayer.getContext('2d', new RenderingContextSettings(true));
      const isolatedRenderCtx = new Canvas2DOffscreenRenderContext(isolatedCtx);
      isolatedRenderCtx.save();
      isolatedRenderCtx.setTransform(stroke.transform);
      this.renderInk(stroke, isolatedRenderCtx);
      this.renderer.renderEraserMask(stroke, isolatedRenderCtx);
      isolatedRenderCtx.restore();
      const bitmap: ImageBitmap = isolatedLayer.transferToImageBitmap();
      c.drawImage(bitmap, 0, 0, this.pageWidth, this.pageHeight);
      bitmap.close();
      return;
    }
    c.save();
    c.setTransform(stroke.transform);
    this.renderInk(stroke, rc);
    c.restore();
  }

  private renderInk(stroke: StrokeElementData, rc: RenderContext): void {
    if (stroke.renderSpec.isPencil) {
      this.renderer.renderPencilSplats(stroke.splatPoints, stroke.renderSpec, rc);
    } else if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH) {
      this.renderer.renderVariableWidthOutline(stroke, rc);
    } else {
      this.renderer.renderCenterPath(stroke, rc);
    }
  }

  private markFullPageDirty(): void {
    this.dirtyTracker.markFullDirty({ left: 0, top: 0, right: this.pageWidth, bottom: this.pageHeight });
  }

  private cloneRect(rect: Rect2D): Rect2D {
    return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
  }

  private getCompletedBitmap(): ImageBitmap | null {
    if (!this.completedBitmapDirty) {
      return this.completedBitmap;
    }
    if (this.completedLayer === null || this.completedCtx === null) {
      return null;
    }
    this.releaseCompletedBitmap();
    // HarmonyOS ArkUI drawImage accepts ImageBitmap/PixelMap, not OffscreenCanvas.
    // Transfer only when the completed layer changed, then restore the layer for future commits.
    this.completedBitmap = this.completedLayer.transferToImageBitmap();
    this.completedCtx.drawImage(this.completedBitmap, 0, 0, this.pageWidth, this.pageHeight);
    this.completedBitmapDirty = false;
    return this.completedBitmap;
  }

  private releaseCompletedBitmap(): void {
    if (this.completedBitmap !== null) {
      this.completedBitmap.close();
      this.completedBitmap = null;
    }
  }
}
