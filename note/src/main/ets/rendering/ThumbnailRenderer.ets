import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BitmapTransferTracker } from '../core/adaptation/BitmapTransferTracker';
import {
  Canvas2DOffscreenRenderContext, Canvas2DStrokeRenderer,
} from '../core/adaptation/Canvas2DStrokeRenderer';
import { Canvas2DTextRenderer } from '../core/adaptation/Canvas2DTextRenderer';
import { LoadedPencilTexture, loadOriginalPencilTexture } from '../core/adaptation/PencilTextureLoader';
import { PagePixelSize, pagePixelSize } from '../core/model/PageCoordinateSpace';
import { PageInfo } from '../core/model/NoteTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { StrokePersistence } from '../data/StrokePersistence';
import { ThemeTokens } from '../ui/theme/EditorTheme';
import { PaperRenderer } from './PaperRenderer';
import { StrokeCanvasPainter } from './StrokeCanvasPainter';
import { ShapeCanvasRenderer } from './ShapeCanvasRenderer';
import { ThumbnailPageTransform, fitPageInThumbnail } from './ThumbnailRenderPolicy';

const THUMB_W: number = 300;
const THUMB_H: number = 400;
const MARGIN: number = 8;

export class ThumbnailRenderer {
  private transferTracker: BitmapTransferTracker = new BitmapTransferTracker();
  private strokeRenderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer(this.transferTracker);
  private strokePainter: StrokeCanvasPainter = new StrokeCanvasPainter(this.strokeRenderer, this.transferTracker);
  private textRenderer: Canvas2DTextRenderer = new Canvas2DTextRenderer();
  private shapeRenderer: ShapeCanvasRenderer = new ShapeCanvasRenderer();
  private paperRenderer: PaperRenderer = new PaperRenderer();
  private pencilPixelMap: image.PixelMap | null = null;
  private textureReady: boolean = false;
  private disposed: boolean = false;
  private initializePromise: Promise<void> | null = null;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.textureReady || this.disposed) {
      return;
    }
    if (this.initializePromise !== null) {
      return this.initializePromise;
    }
    this.initializePromise = this.initializeTexture(context);
    try {
      await this.initializePromise;
    } finally {
      this.initializePromise = null;
    }
  }

  private async initializeTexture(context: common.UIAbilityContext): Promise<void> {
    try {
      const texture: LoadedPencilTexture = await loadOriginalPencilTexture(context);
      if (this.disposed) {
        texture.bitmap.close();
        await texture.pixelMap.release();
        return;
      }
      this.pencilPixelMap = texture.pixelMap;
      this.strokeRenderer.setSplatTexture(texture.bitmap);
    } catch (e) {
      if (!this.disposed) {
        console.error(`Thumbnail pencil texture load failed: ${JSON.stringify(e)}`);
        this.strokeRenderer.setSplatTexture(Canvas2DStrokeRenderer.generatePencilTexture(this.transferTracker));
      }
    }
    this.textureReady = true;
  }

  // The caller owns the returned PixelMap and must release it.
  async renderThumbnail(noteId: string, persistence: StrokePersistence,
    page: PageInfo, theme: ThemeTokens): Promise<PixelMap> {
    if (this.disposed) {
      throw new Error('ThumbnailRenderer is disposed');
    }
    const loaded = await persistence.loadElements(noteId, page.pageId);
    const pageSize: PagePixelSize = pagePixelSize(page.widthMm, page.heightMm);
    const pageTransform: ThumbnailPageTransform = fitPageInThumbnail(
      pageSize.width, pageSize.height, THUMB_W, THUMB_H, MARGIN);
    const canvas: OffscreenCanvas = new OffscreenCanvas(THUMB_W, THUMB_H);
    const ctx: OffscreenCanvasRenderingContext2D =
      canvas.getContext('2d', new RenderingContextSettings(true));
    ctx.clearRect(0, 0, THUMB_W, THUMB_H);
    ctx.save();
    ctx.translate(pageTransform.offset.x, pageTransform.offset.y);
    ctx.scale(pageTransform.scale, pageTransform.scale);
    this.paperRenderer.renderOffscreenBackground(ctx, pageSize.width, pageSize.height,
      page, pageTransform.scale, theme);
    const renderContext: Canvas2DOffscreenRenderContext = new Canvas2DOffscreenRenderContext(ctx);
    for (const element of loaded.elements) {
      if (element.kind === PageElementKind.STROKE) {
        this.strokePainter.renderStroke(element.data, renderContext, pageSize.width, pageSize.height);
      } else if (element.kind === PageElementKind.TEXT) {
        this.textRenderer.renderText(element.data, renderContext);
      } else {
        this.shapeRenderer.renderShape(element.data, renderContext);
      }
    }
    ctx.restore();

    const imageData: ImageData = ctx.getImageData(0, 0, THUMB_W, THUMB_H);
    const copyBuffer: ArrayBuffer = new ArrayBuffer(THUMB_W * THUMB_H * 4);
    const copy: Uint8Array = new Uint8Array(copyBuffer);
    const rawData: Uint8ClampedArray = imageData.data;
    for (let i: number = 0; i < rawData.length; i++) {
      copy[i] = rawData[i];
    }
    return image.createPixelMap(copyBuffer, {
      size: { width: THUMB_W, height: THUMB_H },
      srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: false,
    });
  }

  async dispose(): Promise<void> {
    if (this.disposed) {
      return;
    }
    this.disposed = true;
    this.strokeRenderer.dispose();
    if (this.pencilPixelMap !== null) {
      await this.pencilPixelMap.release();
      this.pencilPixelMap = null;
    }
  }
}
