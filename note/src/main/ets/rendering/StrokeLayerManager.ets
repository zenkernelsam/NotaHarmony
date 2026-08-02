// T-013 分层渲染管理器（任务卡 T-013，REVERSE_ANALYSIS §19/§37 低延迟分层架构）
// 已完成层（OffscreenCanvas 缓存）+ 当前笔画层 + 脏矩形增量重绘
// 渲染层实现：允许 import Canvas 类型；不 import UI 组件
import { Rect2D } from '../core/model/GeometryTypes';
import { StrokeElementData, InkStyle } from '../core/model/StrokeTypes';
import { StrokeRenderer, RenderContext } from '../core/adaptation/StrokeRenderer';
import { Canvas2DOffscreenRenderContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { DirtyRectTracker } from './DirtyRectTracker';

export class StrokeLayerManager {
  private completedLayer: OffscreenCanvas | null = null;   // 已完成笔画缓存
  private completedCtx: OffscreenCanvasRenderingContext2D | null = null;
  private completedRenderCtx: Canvas2DOffscreenRenderContext | null = null;
  private renderer: StrokeRenderer;
  private dirtyTracker: DirtyRectTracker;
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;

  constructor(renderer: StrokeRenderer) {
    this.renderer = renderer;
    this.dirtyTracker = new DirtyRectTracker(3);
  }

  // 初始化/重建 OffscreenCanvas（页面 onReady 或 resize 时调用）
  initialize(width: number, height: number): void {
    this.canvasWidth = width;
    this.canvasHeight = height;
    this.completedLayer = new OffscreenCanvas(width, height);
    this.completedCtx = this.completedLayer.getContext('2d', new RenderingContextSettings(true));
    this.completedRenderCtx = new Canvas2DOffscreenRenderContext(this.completedCtx);
    this.dirtyTracker.markFullDirty(width, height);
  }

  // 将完成笔画渲染到已完成层
  commitStroke(stroke: StrokeElementData, _renderCtx: RenderContext): void {
    if (this.completedRenderCtx === null) {
      return;
    }
    this.renderStrokeOnto(stroke, this.completedRenderCtx);
    this.dirtyTracker.markDirty(stroke.bounds);
  }

  // 每帧合成：已完成层 + 当前笔画 → 主画布（脏区 clipRect 限制重绘范围）
  composite(mainCtx: CanvasRenderingContext2D, currentStroke: StrokeElementData | null,
    currentRenderCtx: RenderContext): void {
    const dirty: Rect2D | null = this.dirtyTracker.consume();
    if (dirty === null && currentStroke === null) {
      return;  // 无脏区且无当前笔画：跳过（省性能）
    }
    mainCtx.save();
    if (dirty !== null) {
      mainCtx.beginPath();
      mainCtx.rect(dirty.left, dirty.top, dirty.right - dirty.left, dirty.bottom - dirty.top);
      mainCtx.clip();
      mainCtx.clearRect(dirty.left, dirty.top, dirty.right - dirty.left, dirty.bottom - dirty.top);
    }
    if (this.completedLayer !== null) {
      // OffscreenCanvas → ImageBitmap → 主画布（transfer 后立即回写恢复层内容）
      const bmp: ImageBitmap = this.completedLayer.transferToImageBitmap();
      mainCtx.drawImage(bmp, 0, 0, this.canvasWidth, this.canvasHeight);
      if (this.completedCtx !== null) {
        this.completedCtx.drawImage(bmp, 0, 0, this.canvasWidth, this.canvasHeight);
      }
    }
    if (currentStroke !== null && currentRenderCtx !== null) {
      this.renderStrokeOnto(currentStroke, currentRenderCtx);
    }
    mainCtx.restore();
  }

  // 清空全部（新建笔记/撤销全部）
  clearAll(): void {
    if (this.completedCtx === null) {
      return;
    }
    this.completedCtx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.dirtyTracker.markFullDirty(this.canvasWidth, this.canvasHeight);
  }

  // 撤销/擦除后重建：清空已完成层 → 逐笔重新渲染
  rebuildFromStrokes(strokes: StrokeElementData[], _renderCtx: RenderContext): void {
    if (this.completedCtx === null || this.completedRenderCtx === null) {
      return;
    }
    this.completedCtx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    for (const s of strokes) {
      this.renderStrokeOnto(s, this.completedRenderCtx);
    }
    this.dirtyTracker.markFullDirty(this.canvasWidth, this.canvasHeight);
  }

  isInitialized(): boolean {
    return this.completedLayer !== null;
  }

  // 按 renderSpec 分发渲染路径（中心线 / 可变宽度轮廓 / PencilSplat），随后应用擦除遮罩
  private renderStrokeOnto(stroke: StrokeElementData, rc: RenderContext): void {
    if (stroke.renderSpec.isPencil) {
      this.renderer.renderPencilSplats(stroke.splatPoints, stroke.renderSpec, rc);
    } else if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH) {
      this.renderer.renderVariableWidthOutline(stroke, rc);
    } else {
      this.renderer.renderCenterPath(stroke, rc);
    }
    this.renderer.renderEraserMask(stroke, rc);
  }
}
