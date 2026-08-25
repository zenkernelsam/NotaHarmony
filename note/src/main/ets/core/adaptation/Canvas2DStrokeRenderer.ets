// T-012 Canvas 2D 渲染器（任务卡 T-012，StrokeRenderer 接口的 Canvas 2D 实现）
// 适配层实现：允许 import Canvas 相关类型；不 import TouchEvent / UI 组件
// ArkTS 不支持结构化类型赋值：主画布与 OffscreenCanvas 上下文分属两个包装类
import { StrokeRenderer, RenderContext } from './StrokeRenderer';
import { StrokeElementData, PencilSplatPoint, RenderSpec, InkStyle,
  ERASER_PATH_BREAK_COORDINATE, InkPathCommand, InkPathCommandType,
  TapePattern } from '../model/StrokeTypes';
import { Point2D, Rect2D } from '../model/GeometryTypes';
import { WidthOutlineBuilder } from '../algorithm/WidthOutlineBuilder';
import { BitmapTransferKind, BitmapTransferTracker } from './BitmapTransferTracker';

interface TapePatternTileSize {
  width: number;
  height: number;
}

interface TapePatternTile {
  bitmap: ImageBitmap;
  logicalWidth: number;
  logicalHeight: number;
}

// Original qfe.a(): round(clamp(viewportZoom, 1, 8) * 2). The integer bucket is
// part of PatternCellKey and represents half-step raster scales from 1x through 8x.
export function originalTapePatternScaleBucket(viewportZoom: number): number {
  const zoom: number = Math.fround(viewportZoom);
  if (!Number.isFinite(zoom) || zoom <= 0) {
    return 2;
  }
  const clamped: number = Math.fround(Math.max(1, Math.min(8, zoom)));
  return Math.round(Math.fround(clamped * 2));
}

export function originalTapePatternPixelSize(logicalSize: number, scaleBucket: number): number {
  const logical: number = Math.fround(logicalSize);
  if (!Number.isFinite(logical) || logical <= 0) {
    return 1;
  }
  const bucket: number = Number.isInteger(scaleBucket) ?
    Math.max(2, Math.min(16, scaleBucket)) : 2;
  const rasterScale: number = Math.fround(bucket / 2);
  return Math.max(1, Math.round(Math.fround(logical * rasterScale)));
}

export interface Canvas2DDrawingContext extends RenderContext {
  beginPath(): void;
  moveTo(x: number, y: number): void;
  lineTo(x: number, y: number): void;
  quadraticCurveTo(cpx: number, cpy: number, x: number, y: number): void;
  bezierCurveTo(cp1x: number, cp1y: number, cp2x: number, cp2y: number, x: number, y: number): void;
  rect(x: number, y: number, width: number, height: number): void;
  clip(fillRule?: CanvasFillRule): void;
  closePath(): void;
  stroke(): void;
  fill(): void;
  fillRect(x: number, y: number, width: number, height: number): void;
  fillText(text: string, x: number, y: number): void;
  measureText(text: string): number;
  arc(x: number, y: number, radius: number, startAngle: number, endAngle: number): void;
  setLineDash(segments: number[]): void;
  setLineDashOffset(offset: number): void;
  setLineWidth(width: number): void;
  setLineCap(cap: CanvasLineCap): void;
  setLineJoin(join: CanvasLineJoin): void;
  setStrokeStyle(color: string): void;
  setFillStyle(color: string): void;
  setFillPattern(image: ImageBitmap, logicalWidth: number, logicalHeight: number): boolean;
  setFont(font: string): void;
  setGlobalAlpha(alpha: number): void;
  setGlobalCompositeOperation(op: string): void;
  setFilter(filter: string): void;
  translate(x: number, y: number): void;
  rotate(angle: number): void;
  scale(sx: number, sy: number): void;
  setTransform(m: number[]): void;
  transform(m: number[]): void;
  drawImage(image: ImageBitmap, dx: number, dy: number, dw: number, dh: number): void;
}

// 渲染上下文实现 A：包装主画布 CanvasRenderingContext2D
export class Canvas2DRenderContext implements Canvas2DDrawingContext {
  private ctx: CanvasRenderingContext2D;

  constructor(ctx: CanvasRenderingContext2D) {
    this.ctx = ctx;
  }

  save(): void {
    this.ctx.save();
  }

  restore(): void {
    this.ctx.restore();
  }

  clipRect(rect: Rect2D): void {
    this.ctx.beginPath();
    this.ctx.rect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    this.ctx.clip();
  }

  clear(rect: Rect2D): void {
    this.ctx.clearRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
  }

  // === Canvas 2D 扩展（RenderContext 接口不足的部分）===
  beginPath(): void {
    this.ctx.beginPath();
  }

  moveTo(x: number, y: number): void {
    this.ctx.moveTo(x, y);
  }

  lineTo(x: number, y: number): void {
    this.ctx.lineTo(x, y);
  }

  quadraticCurveTo(cpx: number, cpy: number, x: number, y: number): void {
    this.ctx.quadraticCurveTo(cpx, cpy, x, y);
  }

  rect(x: number, y: number, width: number, height: number): void {
    this.ctx.rect(x, y, width, height);
  }

  clip(fillRule?: CanvasFillRule): void {
    this.ctx.clip(fillRule);
  }

  bezierCurveTo(cp1x: number, cp1y: number, cp2x: number, cp2y: number, x: number, y: number): void {
    this.ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  }

  closePath(): void {
    this.ctx.closePath();
  }

  stroke(): void {
    this.ctx.stroke();
  }

  fill(): void {
    this.ctx.fill();
  }

  fillRect(x: number, y: number, width: number, height: number): void {
    this.ctx.fillRect(x, y, width, height);
  }

  fillText(text: string, x: number, y: number): void {
    this.ctx.fillText(text, x, y);
  }

  measureText(text: string): number {
    return this.ctx.measureText(text).width;
  }

  arc(x: number, y: number, radius: number, startAngle: number, endAngle: number): void {
    this.ctx.arc(x, y, radius, startAngle, endAngle);
  }

  setLineDash(segments: number[]): void {
    this.ctx.setLineDash(segments);
  }

  setLineDashOffset(offset: number): void {
    this.ctx.lineDashOffset = offset;
  }

  setLineWidth(width: number): void {
    this.ctx.lineWidth = width;
  }

  setLineCap(cap: CanvasLineCap): void {
    this.ctx.lineCap = cap;
  }

  setLineJoin(join: CanvasLineJoin): void {
    this.ctx.lineJoin = join;
  }

  setStrokeStyle(color: string): void {
    this.ctx.strokeStyle = color;
  }

  setFillStyle(color: string): void {
    this.ctx.fillStyle = color;
  }

  setFillPattern(image: ImageBitmap, logicalWidth: number, logicalHeight: number): boolean {
    const pattern: CanvasPattern | null = this.ctx.createPattern(image, 'repeat');
    if (pattern === null) {
      return false;
    }
    pattern.setTransform(new Matrix2D().scale(logicalWidth / image.width, logicalHeight / image.height));
    this.ctx.fillStyle = pattern;
    return true;
  }

  setFont(font: string): void {
    this.ctx.font = font;
  }

  setGlobalAlpha(alpha: number): void {
    this.ctx.globalAlpha = alpha;
  }

  setGlobalCompositeOperation(op: string): void {
    this.ctx.globalCompositeOperation = op;
  }

  setFilter(filter: string): void {
    this.ctx.filter = filter;
  }

  translate(x: number, y: number): void {
    this.ctx.translate(x, y);
  }

  rotate(angle: number): void {
    this.ctx.rotate(angle);
  }

  scale(sx: number, sy: number): void {
    this.ctx.scale(sx, sy);
  }

  // 应用 3×3 行主序仿射变换矩阵（变换选中笔画用）
  setTransform(m: number[]): void {
    this.ctx.setTransform(m[0], m[3], m[1], m[4], m[2], m[5]);
  }

  transform(m: number[]): void {
    this.ctx.transform(m[0], m[3], m[1], m[4], m[2], m[5]);
  }

  drawImage(image: ImageBitmap, dx: number, dy: number, dw: number, dh: number): void {
    this.ctx.drawImage(image, dx, dy, dw, dh);
  }
}

// 渲染上下文实现 B：包装 OffscreenCanvas 上下文 OffscreenCanvasRenderingContext2D
// 与 Canvas2DRenderContext 方法集一致（渲染器按鸭子类型调用，运行时安全）
export class Canvas2DOffscreenRenderContext implements Canvas2DDrawingContext {
  private ctx: OffscreenCanvasRenderingContext2D;

  constructor(ctx: OffscreenCanvasRenderingContext2D) {
    this.ctx = ctx;
  }

  save(): void {
    this.ctx.save();
  }

  restore(): void {
    this.ctx.restore();
  }

  clipRect(rect: Rect2D): void {
    this.ctx.beginPath();
    this.ctx.rect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    this.ctx.clip();
  }

  clear(rect: Rect2D): void {
    this.ctx.clearRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
  }

  beginPath(): void {
    this.ctx.beginPath();
  }

  moveTo(x: number, y: number): void {
    this.ctx.moveTo(x, y);
  }

  lineTo(x: number, y: number): void {
    this.ctx.lineTo(x, y);
  }

  quadraticCurveTo(cpx: number, cpy: number, x: number, y: number): void {
    this.ctx.quadraticCurveTo(cpx, cpy, x, y);
  }

  rect(x: number, y: number, width: number, height: number): void {
    this.ctx.rect(x, y, width, height);
  }

  clip(fillRule?: CanvasFillRule): void {
    this.ctx.clip(fillRule);
  }

  bezierCurveTo(cp1x: number, cp1y: number, cp2x: number, cp2y: number, x: number, y: number): void {
    this.ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  }

  closePath(): void {
    this.ctx.closePath();
  }

  stroke(): void {
    this.ctx.stroke();
  }

  fill(): void {
    this.ctx.fill();
  }

  fillRect(x: number, y: number, width: number, height: number): void {
    this.ctx.fillRect(x, y, width, height);
  }

  fillText(text: string, x: number, y: number): void {
    this.ctx.fillText(text, x, y);
  }

  measureText(text: string): number {
    return this.ctx.measureText(text).width;
  }

  arc(x: number, y: number, radius: number, startAngle: number, endAngle: number): void {
    this.ctx.arc(x, y, radius, startAngle, endAngle);
  }

  setLineDash(segments: number[]): void {
    this.ctx.setLineDash(segments);
  }

  setLineDashOffset(offset: number): void {
    this.ctx.lineDashOffset = offset;
  }

  setLineWidth(width: number): void {
    this.ctx.lineWidth = width;
  }

  setLineCap(cap: CanvasLineCap): void {
    this.ctx.lineCap = cap;
  }

  setLineJoin(join: CanvasLineJoin): void {
    this.ctx.lineJoin = join;
  }

  setStrokeStyle(color: string): void {
    this.ctx.strokeStyle = color;
  }

  setFillStyle(color: string): void {
    this.ctx.fillStyle = color;
  }

  setFillPattern(image: ImageBitmap, logicalWidth: number, logicalHeight: number): boolean {
    const pattern: CanvasPattern | null = this.ctx.createPattern(image, 'repeat');
    if (pattern === null) {
      return false;
    }
    pattern.setTransform(new Matrix2D().scale(logicalWidth / image.width, logicalHeight / image.height));
    this.ctx.fillStyle = pattern;
    return true;
  }

  setFont(font: string): void {
    this.ctx.font = font;
  }

  setGlobalAlpha(alpha: number): void {
    this.ctx.globalAlpha = alpha;
  }

  setGlobalCompositeOperation(op: string): void {
    this.ctx.globalCompositeOperation = op;
  }

  setFilter(filter: string): void {
    this.ctx.filter = filter;
  }

  translate(x: number, y: number): void {
    this.ctx.translate(x, y);
  }

  rotate(angle: number): void {
    this.ctx.rotate(angle);
  }

  scale(sx: number, sy: number): void {
    this.ctx.scale(sx, sy);
  }

  // 应用 3×3 行主序仿射变换矩阵（变换选中笔画用）
  setTransform(m: number[]): void {
    this.ctx.setTransform(m[0], m[3], m[1], m[4], m[2], m[5]);
  }

  transform(m: number[]): void {
    this.ctx.transform(m[0], m[3], m[1], m[4], m[2], m[5]);
  }

  drawImage(image: ImageBitmap, dx: number, dy: number, dw: number, dh: number): void {
    this.ctx.drawImage(image, dx, dy, dw, dh);
  }
}

export class Canvas2DStrokeRenderer implements StrokeRenderer {
  private splatTexture: ImageBitmap | null = null;
  private tintedSplatTextures: Map<number, ImageBitmap> = new Map<number, ImageBitmap>();
  private transferTracker: BitmapTransferTracker;
  private static readonly MAX_TINTED_SPLAT_TEXTURES: number = 4;
  private static readonly MAX_TAPE_TILES: number = 32;
  private tapeTiles: Map<string, TapePatternTile> = new Map<string, TapePatternTile>();
  // 擦除遮罩渲染宽度（可由页面设置）
  private eraserMaskWidth: number = 20;

  constructor(transferTracker: BitmapTransferTracker = new BitmapTransferTracker()) {
    this.transferTracker = transferTracker;
  }

  // 原版资源解码失败时使用的确定性降级纹理；正常路径始终加载原始 1024x1024 splat。
  static generatePencilTexture(transferTracker?: BitmapTransferTracker): ImageBitmap {
    const TEX: number = 64;
    const canvas = new OffscreenCanvas(TEX, TEX);
    const ctx: OffscreenCanvasRenderingContext2D =
      canvas.getContext('2d', new RenderingContextSettings(true));
    ctx.clearRect(0, 0, TEX, TEX);
    // 径向渐变（中心不透明 → 边缘透明）
    const grad = ctx.createRadialGradient(32, 32, 2, 32, 32, 31);
    grad.addColorStop(0, 'rgba(255,255,255,0.9)');
    grad.addColorStop(0.55, 'rgba(255,255,255,0.55)');
    grad.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, TEX, TEX);
    // 石墨颗粒：确定性 LCG（与笔画 seed 无关，纹理固定）
    let seed: number = 20260805;
    const rand = (): number => {
      seed = (seed * 1103515245 + 12345) % 2147483648;
      return seed / 2147483648;
    };
    for (let i = 0; i < 900; i++) {
      const px: number = rand() * TEX;
      const py: number = rand() * TEX;
      const dx: number = px - 32;
      const dy: number = py - 32;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist > 31) {
        continue;
      }
      const alpha: number = (0.15 + rand() * 0.35) * (1 - dist / 32);
      ctx.fillStyle = 'rgba(255,255,255,' + alpha.toFixed(3) + ')';
      ctx.beginPath();
      ctx.arc(px, py, 0.6 + rand() * 0.9, 0, Math.PI * 2);
      ctx.fill();
    }
    const texture: ImageBitmap = canvas.transferToImageBitmap();
    if (transferTracker !== undefined) {
      transferTracker.recordTransfer(BitmapTransferKind.PENCIL_TEXTURE);
    }
    return texture;
  }

  setSplatTexture(texture: ImageBitmap): void {
    this.releaseTintedSplatTextures();
    if (this.splatTexture !== null && this.splatTexture !== texture) {
      this.splatTexture.close();
    }
    this.splatTexture = texture;
  }

  dispose(): void {
    this.releaseTintedSplatTextures();
    this.releaseTapeTiles();
    if (this.splatTexture !== null) {
      this.splatTexture.close();
      this.splatTexture = null;
    }
  }

  setEraserMaskWidth(width: number): void {
    this.eraserMaskWidth = width;
  }

  // Original e16 draws fillPath (or centerPath fallback) before the main ink. For translucent
  // fills it excludes the explicit/generated stroke outline so the fill cannot darken the ink.
  renderInkFill(stroke: StrokeElementData, ctx: RenderContext): void {
    const fillColor: number | null = stroke.fillColor === undefined ? null : stroke.fillColor;
    if (fillColor === null) {
      return;
    }
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    const fillPath: InkPathCommand[] | null = stroke.fillPath === undefined ? null : stroke.fillPath;
    c.save();
    try {
      const alpha: number = (fillColor >>> 24) & 0xFF;
      if (alpha < 255 && stroke.renderSpec.brushWidth > 0) {
        const exclusion: InkPathCommand[] | null = stroke.customPath === undefined ? null : stroke.customPath;
        c.beginPath();
        c.rect(-10000000, -10000000, 20000000, 20000000);
        if (exclusion !== null && exclusion.length > 0) {
          this.appendInkPath(c, exclusion);
        } else {
          const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
          const outline = builder.build(stroke.pathPoints, stroke.renderSpec.brushWidth,
            stroke.cubicSegments);
          if (outline.isValid) {
            c.moveTo(outline.outlinePoints[0].x, outline.outlinePoints[0].y);
            for (let index: number = 1; index < outline.outlinePoints.length; index++) {
              c.lineTo(outline.outlinePoints[index].x, outline.outlinePoints[index].y);
            }
            c.closePath();
          }
        }
        c.clip('evenodd');
      }
      c.beginPath();
      if (fillPath !== null && fillPath.length > 0) {
        this.appendInkPath(c, fillPath);
      } else {
        this.appendCenterPath(c, stroke);
      }
      c.setFillStyle(this.colorToRgba(fillColor));
      c.fill();
    } finally {
      c.restore();
    }
  }

  renderCustomPath(stroke: StrokeElementData, ctx: RenderContext): boolean {
    const customPath: InkPathCommand[] | null =
      stroke.customPath === undefined ? null : stroke.customPath;
    if (customPath === null || customPath.length === 0) {
      return false;
    }
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    c.save();
    try {
      c.beginPath();
      this.appendInkPath(c, customPath);
      if (stroke.renderSpec.inkStyle === InkStyle.DASH ||
        stroke.renderSpec.inkStyle === InkStyle.DOTS) {
        c.clip();
        this.renderCenterPath(stroke, ctx);
      } else {
        c.setFillStyle(this.colorToRgba(stroke.renderSpec.color,
          stroke.renderSpec.isHighlighter ? 107 : undefined));
        c.fill();
      }
    } finally {
      c.restore();
    }
    return true;
  }

  // === 中心线路径（Mono/Dash/Dot，pzf.g 规格）===
  renderCenterPath(stroke: StrokeElementData, ctx: RenderContext): void {
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    const spec: RenderSpec = stroke.renderSpec;
    // 空路径检查（pzf.g 对齐）：无点直接返回
    if (stroke.pathPoints.length === 0) {
      return;
    }
    c.save();
    try {
      c.beginPath();
      this.appendCenterPath(c, stroke);
      if (stroke.pathPoints.length === 1) {
        c.lineTo(stroke.pathPoints[0].position.x, stroke.pathPoints[0].position.y);
      }
      c.setLineWidth(spec.brushWidth);
      // 原版 c5g：DASH 使用 BUTT，DOTS 与实线使用 ROUND。
      if (spec.inkStyle === InkStyle.DASH) {
        c.setLineCap('butt');
      } else {
        c.setLineCap('round');
      }
      c.setLineJoin(spec.inkStyle === InkStyle.DOTS ? 'miter' : 'round');
      // 原版 zx1.e(color, 107) 覆盖 alpha，而不是把已有 alpha 再乘 107/255。
      c.setStrokeStyle(this.colorToRgba(spec.color, spec.isHighlighter ? 107 : undefined));
      if (spec.inkStyle === InkStyle.DASH) {
        c.setLineDash([2 * spec.brushWidth, 1 * spec.brushWidth]);
      } else if (spec.inkStyle === InkStyle.DOTS) {
        c.setLineDash([0.001 * spec.brushWidth, 2 * spec.brushWidth]);
      }
      if ((spec.inkStyle === InkStyle.DASH || spec.inkStyle === InkStyle.DOTS) &&
        stroke.styleMap !== undefined && stroke.styleMap.length > 0) {
        const period: number = spec.inkStyle === InkStyle.DASH ?
          3 * spec.brushWidth : 2.001 * spec.brushWidth;
        const phase: number = stroke.styleMap[0].backingDashPhase;
        c.setLineDashOffset(period > 0 ? ((phase % period) + period) % period : 0);
      }
      c.stroke();
    } finally {
      c.restore();
    }
  }

  // === 可变宽度填充轮廓（Taper，w4a.b()）===
  renderVariableWidthOutline(stroke: StrokeElementData, ctx: RenderContext): void {
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
    const outline = builder.build(
      stroke.pathPoints, stroke.renderSpec.brushWidth, stroke.cubicSegments);
    if (!outline.isValid) {
      return;
    }
    c.save();
    try {
      c.beginPath();
      c.moveTo(outline.outlinePoints[0].x, outline.outlinePoints[0].y);
      for (let i = 1; i < outline.outlinePoints.length; i++) {
        c.lineTo(outline.outlinePoints[i].x, outline.outlinePoints[i].y);
      }
      c.closePath();
      c.setFillStyle(this.colorToRgba(stroke.renderSpec.color,
        stroke.renderSpec.isHighlighter ? 107 : undefined));
      c.fill();
    } finally {
      c.restore();
    }
  }

  // === PencilSplat 渲染（持久着色纹理 + 直接 splat，避免实时笔迹每帧位图 transfer）===
  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, ctx: RenderContext): void {
    if (splats.length === 0) {
      return;
    }
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    const tintedTexture: ImageBitmap | null = this.getTintedSplatTexture(spec.color);
    for (const s of splats) {
      c.save();
      try {
        c.translate(s.x, s.y);
        c.rotate(s.rotation);
        c.setGlobalAlpha(s.opacity);
        if (tintedTexture !== null) {
          // s.scale 的唯一单位是页面半径；原版纹理无论原始分辨率均映射到直径 2*scale。
          c.drawImage(tintedTexture, -s.scale, -s.scale, 2 * s.scale, 2 * s.scale);
        } else {
          // fallback 与纹理路径使用完全相同的外接尺寸，避免二次 scale。
          c.beginPath();
          c.arc(0, 0, s.scale, 0, Math.PI * 2);
          c.setFillStyle(this.colorToRgba(spec.color));
          c.fill();
        }
      } finally {
        c.restore();
      }
    }
  }

  private getTintedSplatTexture(color: number): ImageBitmap | null {
    if (this.splatTexture === null) {
      return null;
    }
    const cached: ImageBitmap | undefined = this.tintedSplatTextures.get(color);
    if (cached !== undefined) {
      this.tintedSplatTextures.delete(color);
      this.tintedSplatTextures.set(color, cached);
      return cached;
    }
    const width: number = this.splatTexture.width;
    const height: number = this.splatTexture.height;
    const canvas: OffscreenCanvas = new OffscreenCanvas(width, height);
    const ctx: OffscreenCanvasRenderingContext2D =
      canvas.getContext('2d', new RenderingContextSettings(true));
    ctx.drawImage(this.splatTexture, 0, 0, width, height);
    ctx.globalCompositeOperation = 'source-in';
    ctx.fillStyle = this.colorToRgba(color);
    ctx.fillRect(0, 0, width, height);
    const tinted: ImageBitmap = canvas.transferToImageBitmap();
    this.transferTracker.recordTransfer(BitmapTransferKind.PENCIL_TINT);
    if (this.tintedSplatTextures.size >= Canvas2DStrokeRenderer.MAX_TINTED_SPLAT_TEXTURES) {
      const oldestKey: number | undefined = this.tintedSplatTextures.keys().next().value;
      if (oldestKey !== undefined) {
        const oldest: ImageBitmap | undefined = this.tintedSplatTextures.get(oldestKey);
        if (oldest !== undefined) {
          oldest.close();
        }
        this.tintedSplatTextures.delete(oldestKey);
      }
    }
    this.tintedSplatTextures.set(color, tinted);
    return tinted;
  }

  private releaseTintedSplatTextures(): void {
    this.tintedSplatTextures.forEach((bitmap: ImageBitmap): void => {
      bitmap.close();
    });
    this.tintedSplatTextures.clear();
  }

  // === 擦除遮罩（destination-out 挖洞）===
  renderPartialEraser(stroke: StrokeElementData, ctx: RenderContext): void {
    if (stroke.pathPoints.length === 0) {
      return;
    }
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    c.save();
    try {
      c.setGlobalCompositeOperation('destination-out');
      c.beginPath();
      this.appendCenterPath(c, stroke);
      if (stroke.pathPoints.length === 1) {
        c.lineTo(stroke.pathPoints[0].position.x, stroke.pathPoints[0].position.y);
      }
      c.setLineWidth(stroke.renderSpec.brushWidth);
      c.setLineCap('round');
      c.setLineJoin('round');
      c.setLineDash([]);
      c.stroke();
    } finally {
      c.restore();
    }
  }

  renderEraserMask(stroke: StrokeElementData, ctx: RenderContext): void {
    if (stroke.maskPath.length === 0) {
      return;
    }
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    c.save();
    try {
      c.setGlobalCompositeOperation('destination-out');
      c.setLineWidth(this.eraserMaskWidth);
      c.setLineCap('round');
      c.setLineJoin('round');
      let index: number = 0;
      while (index < stroke.maskPath.length) {
        while (index < stroke.maskPath.length && this.isMaskBreak(stroke.maskPath[index])) {
          index++;
        }
        if (index >= stroke.maskPath.length) {
          break;
        }
        const first = stroke.maskPath[index];
        c.beginPath();
        c.moveTo(first.x, first.y);
        c.lineTo(first.x, first.y);
        index++;
        while (index < stroke.maskPath.length && !this.isMaskBreak(stroke.maskPath[index])) {
          c.lineTo(stroke.maskPath[index].x, stroke.maskPath[index].y);
          index++;
        }
        c.stroke();
      }
    } finally {
      c.restore();
    }
  }

  // Original qfe uses a bounded tile bitmap and a repeated BitmapShader. Keep that architecture:
  // direct page-bounds tiling would make malformed extreme coordinates unbounded work.
  renderTapePattern(stroke: StrokeElementData, ctx: RenderContext,
    viewportZoom: number = 1): void {
    const pattern: TapePattern | undefined = stroke.renderSpec.tapePattern;
    if (pattern === undefined || pattern === TapePattern.PLAIN || stroke.pathPoints.length === 0) {
      return;
    }
    const customPath: InkPathCommand[] | null =
      stroke.customPath === undefined ? null : stroke.customPath;
    let outlinePoints: Point2D[] = [];
    if (customPath === null || customPath.length === 0) {
      const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
      const outline = builder.build(stroke.pathPoints, stroke.renderSpec.brushWidth,
        stroke.cubicSegments);
      if (!outline.isValid) {
        return;
      }
      outlinePoints = outline.outlinePoints;
    }
    const tile: TapePatternTile = this.getTapePatternTile(pattern, stroke.renderSpec.color,
      0xFFFFFFFF, viewportZoom);
    const c: Canvas2DDrawingContext = ctx as Canvas2DDrawingContext;
    c.save();
    try {
      c.beginPath();
      if (customPath !== null && customPath.length > 0) {
        this.appendInkPath(c, customPath);
      } else {
        c.moveTo(outlinePoints[0].x, outlinePoints[0].y);
        for (let index: number = 1; index < outlinePoints.length; index++) {
          c.lineTo(outlinePoints[index].x, outlinePoints[index].y);
        }
        c.closePath();
      }
      c.setGlobalAlpha(1);
      c.setLineDash([]);
      if (c.setFillPattern(tile.bitmap, tile.logicalWidth, tile.logicalHeight)) {
        c.fill();
      }
    } finally {
      c.restore();
    }
  }

  private getTapePatternTile(pattern: TapePattern, tapeColor: number,
    overlayColor: number, viewportZoom: number): TapePatternTile {
    const colorKey: number = pattern === TapePattern.FLOWERS ? tapeColor : 0;
    const scaleBucket: number = originalTapePatternScaleBucket(viewportZoom);
    const key: string = `${pattern}:${overlayColor}:${colorKey}:${scaleBucket}`;
    const cached: TapePatternTile | undefined = this.tapeTiles.get(key);
    if (cached !== undefined) {
      this.tapeTiles.delete(key);
      this.tapeTiles.set(key, cached);
      return cached;
    }
    const size: TapePatternTileSize = this.tapePatternTileSize(pattern);
    const pixelWidth: number = originalTapePatternPixelSize(size.width, scaleBucket);
    const pixelHeight: number = originalTapePatternPixelSize(size.height, scaleBucket);
    const canvas: OffscreenCanvas = new OffscreenCanvas(pixelWidth, pixelHeight);
    const raw: OffscreenCanvasRenderingContext2D =
      canvas.getContext('2d', new RenderingContextSettings(true));
    raw.clearRect(0, 0, pixelWidth, pixelHeight);
    raw.scale(pixelWidth / size.width, pixelHeight / size.height);
    const drawing: Canvas2DOffscreenRenderContext = new Canvas2DOffscreenRenderContext(raw);
    this.drawTapePatternTile(drawing, pattern, size.width, size.height, tapeColor, overlayColor);
    const created: TapePatternTile = {
      bitmap: canvas.transferToImageBitmap(), logicalWidth: size.width, logicalHeight: size.height,
    };
    this.tapeTiles.set(key, created);
    if (this.tapeTiles.size > Canvas2DStrokeRenderer.MAX_TAPE_TILES) {
      const oldest: string | undefined = this.tapeTiles.keys().next().value;
      if (oldest !== undefined) {
        const evicted: TapePatternTile | undefined = this.tapeTiles.get(oldest);
        this.tapeTiles.delete(oldest);
        if (evicted !== undefined) {
          evicted.bitmap.close();
        }
      }
    }
    return created;
  }

  private tapePatternTileSize(pattern: TapePattern): TapePatternTileSize {
    if (pattern === TapePattern.STRIPES) {
      return { width: 11.313708, height: 11.313708 };
    }
    if (pattern === TapePattern.GRID) {
      return { width: 8, height: 8 };
    }
    if (pattern === TapePattern.DOTS) {
      return { width: 8, height: 16 };
    }
    if (pattern === TapePattern.STARS) {
      return { width: 30, height: 13 };
    }
    if (pattern === TapePattern.FLOWERS) {
      return { width: 28, height: 14 };
    }
    if (pattern === TapePattern.HEARTS) {
      return { width: 26, height: 13 };
    }
    if (pattern === TapePattern.WAVES) {
      return { width: 6, height: 8 };
    }
    return { width: 12, height: 12 };
  }

  private drawTapePatternTile(c: Canvas2DDrawingContext, pattern: TapePattern,
    width: number, height: number, tapeColor: number, overlayColor: number): void {
    const left: number = 0;
    const right: number = width;
    const top: number = 0;
    const bottom: number = height;
    c.setStrokeStyle(this.colorToRgba(overlayColor));
    c.setFillStyle(this.colorToRgba(overlayColor));
    if (pattern === TapePattern.STRIPES) {
      c.setLineWidth(2);
      const period: number = 11.313708;
      const start: number = Math.floor((top - right) / period) * period;
      for (let offset: number = start; offset <= bottom - left; offset += period) {
        c.beginPath();
        c.moveTo(left - 3, left - 3 + offset);
        c.lineTo(right + 3, right + 3 + offset);
        c.stroke();
      }
    } else if (pattern === TapePattern.GRID) {
      c.setLineWidth(1);
      for (let x: number = Math.ceil(left / 8) * 8; x <= right; x += 8) {
        c.beginPath(); c.moveTo(x, top - 3); c.lineTo(x, bottom + 3); c.stroke();
      }
      for (let y: number = Math.ceil(top / 8) * 8; y <= bottom; y += 8) {
        c.beginPath(); c.moveTo(left - 3, y); c.lineTo(right + 3, y); c.stroke();
      }
    } else if (pattern === TapePattern.DOTS) {
      let row: number = Math.ceil(top / 8);
      for (let y: number = row * 8; y <= bottom; y += 8, row++) {
        const xOffset: number = row % 2 === 0 ? 0 : 4;
        for (let x: number = Math.ceil((left - xOffset) / 8) * 8 + xOffset;
          x <= right; x += 8) {
          c.beginPath(); c.arc(x, y, 1.25, 0, Math.PI * 2); c.fill();
        }
      }
    } else if (pattern === TapePattern.STARS) {
      for (let column: number = Math.floor((left - 5) / 15);
        column <= Math.ceil((right + 5) / 15); column++) {
        const odd: boolean = column % 2 !== 0;
        const yOffset: number = odd ? 7 : 0;
        const radius: number = odd ? 3 : 5;
        for (let row: number = Math.floor((top - radius - yOffset) / 13) - 1;
          row <= Math.ceil((bottom + radius - yOffset) / 13) + 1; row++) {
          this.fillStar(c, column * 15, row * 13 + yOffset, radius);
        }
      }
    } else if (pattern === TapePattern.FLOWERS) {
      for (let column: number = Math.floor((left - 2.8) / 14);
        column <= Math.ceil((right + 2.8) / 14); column++) {
        const odd: boolean = column % 2 !== 0;
        const yOffset: number = odd ? 7 : 0;
        const radius: number = odd ? 1.6 : 2.8;
        for (let row: number = Math.floor((top - radius - yOffset) / 14) - 1;
          row <= Math.ceil((bottom + radius - yOffset) / 14) + 1; row++) {
          this.fillFlower(c, column * 14, row * 14 + yOffset, radius,
            tapeColor, overlayColor);
        }
      }
    } else if (pattern === TapePattern.HEARTS) {
      for (let column: number = Math.floor((left - 4) / 13);
        column <= Math.ceil((right + 4) / 13); column++) {
        const odd: boolean = column % 2 !== 0;
        const yOffset: number = odd ? 6 : 0;
        const size: number = odd ? 2.5 : 4;
        for (let row: number = Math.floor((top - size - yOffset) / 13) - 1;
          row <= Math.ceil((bottom + size - yOffset) / 13) + 1; row++) {
          this.fillHeart(c, column * 13, row * 13 + yOffset, size);
        }
      }
    } else if (pattern === TapePattern.WAVES) {
      c.setLineWidth(1);
      const startX: number = Math.floor(left / 6) * 6 - 6;
      for (let y: number = Math.floor(top / 8) * 8; y <= bottom; y += 8) {
        c.beginPath(); c.moveTo(startX, y);
        for (let x: number = startX; x <= right; x += 6) {
          c.bezierCurveTo(x + 1.5, y - 3, x + 4.5, y + 3, x + 6, y);
        }
        c.stroke();
      }
    } else if (pattern === TapePattern.CHECKERS) {
      for (let row: number = Math.floor(top / 6); row <= Math.ceil(bottom / 6); row++) {
        for (let column: number = Math.floor(left / 6);
          column <= Math.ceil(right / 6); column++) {
          if ((row + column) % 2 === 0) {
            c.fillRect(column * 6, row * 6, 6, 6);
          }
        }
      }
    }
  }

  private releaseTapeTiles(): void {
    this.tapeTiles.forEach((tile: TapePatternTile): void => tile.bitmap.close());
    this.tapeTiles.clear();
  }

  private fillStar(c: Canvas2DDrawingContext, centerX: number, centerY: number,
    radius: number): void {
    c.beginPath();
    for (let point: number = 0; point < 5; point++) {
      const outerAngle: number = point * 1.2566371 - Math.PI / 2;
      const innerAngle: number = outerAngle + 0.62831855;
      const outerX: number = centerX + Math.cos(outerAngle) * radius;
      const outerY: number = centerY + Math.sin(outerAngle) * radius;
      if (point === 0) { c.moveTo(outerX, outerY); } else { c.lineTo(outerX, outerY); }
      c.lineTo(centerX + Math.cos(innerAngle) * radius * 0.4,
        centerY + Math.sin(innerAngle) * radius * 0.4);
    }
    c.closePath(); c.fill();
  }

  private fillFlower(c: Canvas2DDrawingContext, centerX: number, centerY: number,
    radius: number, tapeColor: number, overlayColor: number): void {
    for (let petal: number = 0; petal < 5; petal++) {
      const angle: number = petal * 1.2566371 - Math.PI / 2;
      c.beginPath();
      c.arc(centerX + Math.cos(angle) * radius * 0.8,
        centerY + Math.sin(angle) * radius * 0.8, radius, 0, Math.PI * 2);
      c.fill();
    }
    c.setFillStyle(this.colorToRgba(tapeColor));
    c.beginPath(); c.arc(centerX, centerY, radius * 0.45, 0, Math.PI * 2); c.fill();
    c.setFillStyle(this.colorToRgba(overlayColor));
  }

  private fillHeart(c: Canvas2DDrawingContext, centerX: number, centerY: number,
    size: number): void {
    c.beginPath();
    c.moveTo(centerX, centerY + size);
    c.bezierCurveTo(centerX + size * 0.3, centerY + size,
      centerX + size, centerY + size * 0.5, centerX + size, centerY);
    c.bezierCurveTo(centerX + size, centerY - size * 0.5,
      centerX + size * 0.4, centerY - size * 0.6, centerX, centerY - size * 0.2);
    c.bezierCurveTo(centerX - size * 0.4, centerY - size * 0.6,
      centerX - size, centerY - size * 0.5, centerX - size, centerY);
    c.bezierCurveTo(centerX - size, centerY + size * 0.5,
      centerX - size * 0.3, centerY + size, centerX, centerY + size);
    c.closePath(); c.fill();
  }

  private isMaskBreak(point: Point2D): boolean {
    return point.x === ERASER_PATH_BREAK_COORDINATE && point.y === ERASER_PATH_BREAK_COORDINATE;
  }

  private appendCenterPath(c: Canvas2DDrawingContext, stroke: StrokeElementData): void {
    const pts = stroke.pathPoints;
    if (pts.length === 0) {
      return;
    }
    c.moveTo(pts[0].position.x, pts[0].position.y);
    if (stroke.cubicSegments.length > 0) {
      for (const segment of stroke.cubicSegments) {
        c.bezierCurveTo(segment.p1.x, segment.p1.y, segment.p2.x, segment.p2.y,
          segment.p3.x, segment.p3.y);
      }
      return;
    }
    for (let index: number = 1; index < pts.length; index++) {
      c.lineTo(pts[index].position.x, pts[index].position.y);
    }
  }

  private appendInkPath(c: Canvas2DDrawingContext, commands: InkPathCommand[]): void {
    for (const command of commands) {
      if (command.type === InkPathCommandType.MOVE_TO) {
        c.moveTo(command.points[0].x, command.points[0].y);
      } else if (command.type === InkPathCommandType.LINE_TO) {
        c.lineTo(command.points[0].x, command.points[0].y);
      } else if (command.type === InkPathCommandType.QUADRATIC) {
        c.quadraticCurveTo(command.points[0].x, command.points[0].y,
          command.points[1].x, command.points[1].y);
      } else {
        c.bezierCurveTo(command.points[0].x, command.points[0].y,
          command.points[1].x, command.points[1].y,
          command.points[2].x, command.points[2].y);
      }
    }
  }

  // 工具：ARGB int → rgba 字符串
  private colorToRgba(argb: number, alphaOverride?: number): string {
    const a: number = alphaOverride !== undefined ? alphaOverride : (argb >>> 24) & 0xFF;
    const r: number = (argb >>> 16) & 0xFF;
    const g: number = (argb >>> 8) & 0xFF;
    const b: number = argb & 0xFF;
    return 'rgba(' + r + ',' + g + ',' + b + ',' + (a / 255) + ')';
  }
}
