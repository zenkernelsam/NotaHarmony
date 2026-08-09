// T-035 笔记缩略图渲染器（OffscreenCanvas → PixelMap，内存缓存）
import { image } from '@kit.ImageKit';
import { StrokePersistence } from '../data/StrokePersistence';

const THUMB_W: number = 300;
const THUMB_H: number = 400;
const MARGIN: number = 8;

export class ThumbnailRenderer {
  // 渲染指定笔记首页缩略图。调用方独占返回的 PixelMap，并负责 release()。
  // MVP：仅渲染笔画（文本框渲染依赖 CanvasRenderingContext2D，Offscreen 不兼容，标注）
  async renderThumbnail(noteId: string,
    persistence: StrokePersistence, knownRevision?: string,
    paperBackground: string = '#FFFFFF'): Promise<PixelMap | null> {
    if (knownRevision === undefined) {
      await persistence.getFirstPageRevision(noteId);
    }
      const loaded = await persistence.loadFirstPageElements(noteId);
      if (loaded.strokes.length === 0 && loaded.textBlocks.length === 0) {
        console.info(`ThumbnailRenderer: empty note ${noteId}`);
        return null;
      }
      console.info(`ThumbnailRenderer: note ${noteId} strokes=${loaded.strokes.length}`);
      // 合并笔画 bounds（画布坐标）→ 等比缩放适配
      let minX: number = Number.MAX_VALUE;
      let minY: number = Number.MAX_VALUE;
      let maxX: number = -Number.MAX_VALUE;
      let maxY: number = -Number.MAX_VALUE;
      for (const s of loaded.strokes) {
        minX = Math.min(minX, s.bounds.left);
        minY = Math.min(minY, s.bounds.top);
        maxX = Math.max(maxX, s.bounds.right);
        maxY = Math.max(maxY, s.bounds.bottom);
      }
      for (const t of loaded.textBlocks) {
        minX = Math.min(minX, t.bounds.left);
        minY = Math.min(minY, t.bounds.top);
        maxX = Math.max(maxX, t.bounds.right);
        maxY = Math.max(maxY, t.bounds.bottom);
      }
      if (minX > maxX || minY > maxY) {
        return null;
      }
      const contentW: number = maxX - minX;
      const contentH: number = maxY - minY;
      if (contentW <= 0 || contentH <= 0) {
        return null;
      }
      const scale: number = Math.min((THUMB_W - MARGIN * 2) / contentW,
        (THUMB_H - MARGIN * 2) / contentH);
      const offX: number = (THUMB_W - contentW * scale) / 2 - minX * scale;
      const offY: number = (THUMB_H - contentH * scale) / 2 - minY * scale;

      const canvas = new OffscreenCanvas(THUMB_W, THUMB_H);
      const ctx: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      ctx.fillStyle = paperBackground;
      ctx.fillRect(0, 0, THUMB_W, THUMB_H);
      ctx.translate(offX, offY);
      ctx.scale(scale, scale);

      // MVP 简化：手画中心线（不走 renderer 包装——缩略图缩放场景下包装类 as 转换
      // 与 Offscreen 上下文的兼容性不可靠，手画保证可见性）
      // T-040 审核修复：逐笔画应用 stroke.transform（选区变换后的笔画在缩略图中正确显示）
      for (const s of loaded.strokes) {
        if (s.pathPoints.length > 0) {
          ctx.save();
          const m: number[] = s.transform;
          // 组合：全局 translate(off)*scale(scale) × 笔画 transform m
          ctx.setTransform(m[0] * scale, m[3] * scale, m[1] * scale, m[4] * scale,
            offX + m[2] * scale, offY + m[5] * scale);
          ctx.strokeStyle = this.colorToRgba(s.renderSpec.color, s.renderSpec.isHighlighter);
          ctx.lineWidth = Math.max(s.renderSpec.brushWidth, 2 / scale);
          ctx.lineCap = 'round';
          ctx.beginPath();
          ctx.moveTo(s.pathPoints[0].position.x, s.pathPoints[0].position.y);
          for (let i = 1; i < s.pathPoints.length; i++) {
            ctx.lineTo(s.pathPoints[i].position.x, s.pathPoints[i].position.y);
          }
          ctx.stroke();
          ctx.restore();
        }
      }

      // OffscreenCanvas → PixelMap（RGBA_8888，源/目标格式显式一致）
      const imageData = ctx.getImageData(0, 0, THUMB_W, THUMB_H);
      // 逐字节拷贝到独立 ArrayBuffer（避免 Uint8ClampedArray.buffer 偏移问题）
      const copyBuf = new ArrayBuffer(THUMB_W * THUMB_H * 4);
      const copy = new Uint8Array(copyBuf);
      const rawData = imageData.data;
      for (let i = 0; i < rawData.length; i++) {
        copy[i] = rawData[i];
      }
      const pixelMap: PixelMap = await image.createPixelMap(copyBuf, {
        size: { width: THUMB_W, height: THUMB_H },
        srcPixelFormat: image.PixelMapFormat.RGBA_8888,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: true,
      });
      console.info(`ThumbnailRenderer: ok ${noteId} ${THUMB_W}x${THUMB_H}`);
      return pixelMap;
  }

  private colorToRgba(argb: number, isHighlighter: boolean): string {
    const alphaByte: number = (argb >>> 24) & 0xFF;
    let alpha: number = alphaByte / 255;
    if (isHighlighter) {
      alpha = Math.min(alpha, 0.35);
    }
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha})`;
  }
}
