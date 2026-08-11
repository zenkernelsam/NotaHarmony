import { BitmapTransferKind, BitmapTransferTracker } from '../core/adaptation/BitmapTransferTracker';
import {
  Canvas2DDrawingContext, Canvas2DOffscreenRenderContext,
} from '../core/adaptation/Canvas2DStrokeRenderer';
import { RenderContext, StrokeRenderer } from '../core/adaptation/StrokeRenderer';
import { computeIsolatedLayerBounds, translateTransformToCrop } from '../core/adaptation/LayerCacheGeometry';
import { Rect2D } from '../core/model/GeometryTypes';
import { InkStyle, StrokeElementData } from '../core/model/StrokeTypes';
import {
  OriginalAudioLinkedPlayback, sliceStrokeForAudioProgress,
} from '../core/adaptation/OriginalAudioLinkedInkPlayback';

// Shared stroke composition contract for the editor cache and page thumbnails.
export class StrokeCanvasPainter {
  private renderer: StrokeRenderer;
  private transferTracker: BitmapTransferTracker;

  constructor(renderer: StrokeRenderer, transferTracker: BitmapTransferTracker) {
    this.renderer = renderer;
    this.transferTracker = transferTracker;
  }

  renderStroke(stroke: StrokeElementData, rc: RenderContext, pageWidth: number, pageHeight: number): void {
    const canvasContext: Canvas2DDrawingContext = rc as Canvas2DDrawingContext;
    if (stroke.renderSpec.isPartialEraser === true) {
      canvasContext.save();
      canvasContext.transform(stroke.transform);
      this.renderer.renderPartialEraser(stroke, rc);
      canvasContext.restore();
      return;
    }
    if (stroke.maskPath.length > 0) {
      const crop: Rect2D = computeIsolatedLayerBounds(stroke.bounds, pageWidth, pageHeight);
      const width: number = crop.right - crop.left;
      const height: number = crop.bottom - crop.top;
      if (width <= 0 || height <= 0) {
        return;
      }
      const isolatedLayer: OffscreenCanvas = new OffscreenCanvas(width, height);
      const isolatedContext: OffscreenCanvasRenderingContext2D =
        isolatedLayer.getContext('2d', new RenderingContextSettings(true));
      const isolatedRenderContext: Canvas2DOffscreenRenderContext =
        new Canvas2DOffscreenRenderContext(isolatedContext);
      isolatedRenderContext.save();
      isolatedRenderContext.transform(translateTransformToCrop(stroke.transform, crop));
      this.renderInk(stroke, isolatedRenderContext);
      this.renderer.renderEraserMask(stroke, isolatedRenderContext);
      isolatedRenderContext.restore();
      const bitmap: ImageBitmap = isolatedLayer.transferToImageBitmap();
      this.transferTracker.recordTransfer(BitmapTransferKind.ISOLATED_MASK);
      try {
        canvasContext.drawImage(bitmap, crop.left, crop.top, width, height);
      } finally {
        bitmap.close();
      }
      return;
    }
    canvasContext.save();
    canvasContext.transform(stroke.transform);
    this.renderInk(stroke, rc);
    canvasContext.restore();
  }

  renderAudioLinkedStroke(stroke: StrokeElementData, playback: OriginalAudioLinkedPlayback,
    rc: RenderContext, pageWidth: number, pageHeight: number): void {
    if (playback.alpha === null) {
      this.renderStroke(stroke, rc, pageWidth, pageHeight);
      return;
    }
    const canvasContext: Canvas2DDrawingContext = rc as Canvas2DDrawingContext;
    canvasContext.save();
    canvasContext.setGlobalAlpha(playback.alpha);
    this.renderStroke(stroke, rc, pageWidth, pageHeight);
    canvasContext.restore();
    if (playback.progress !== null && playback.progress > 0) {
      this.renderStroke(sliceStrokeForAudioProgress(stroke, playback.progress),
        rc, pageWidth, pageHeight);
    }
  }

  private renderInk(stroke: StrokeElementData, rc: RenderContext): void {
    this.renderer.renderInkFill(stroke, rc);
    if (stroke.renderSpec.isPencil) {
      this.renderer.renderPencilSplats(stroke.splatPoints, stroke.renderSpec, rc);
    } else {
      const customRendered: boolean = this.renderer.renderCustomPath(stroke, rc);
      if (!customRendered) {
        if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH) {
          this.renderer.renderVariableWidthOutline(stroke, rc);
        } else {
          this.renderer.renderCenterPath(stroke, rc);
        }
      }
      if (stroke.renderSpec.tapePattern !== undefined) {
        this.renderer.renderTapePattern(stroke, rc);
      }
    }
  }
}
