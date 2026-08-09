// T-012 Canvas 2D 渲染器（任务卡 T-012，StrokeRenderer 接口的 Canvas 2D 实现）
// 适配层实现：允许 import Canvas 相关类型；不 import TouchEvent / UI 组件
// ArkTS 不支持结构化类型赋值：主画布与 OffscreenCanvas 上下文分属两个包装类
import { StrokeRenderer, RenderContext } from './StrokeRenderer';
import { StrokeElementData, PencilSplatPoint, RenderSpec, InkStyle,
  ERASER_PATH_BREAK_COORDINATE } from '../model/StrokeTypes';
import { Point2D, Rect2D } from '../model/GeometryTypes';
import { WidthOutlineBuilder } from '../algorithm/WidthOutlineBuilder';

// 渲染上下文实现 A：包装主画布 CanvasRenderingContext2D
export class Canvas2DRenderContext implements RenderContext {
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

  arc(x: number, y: number, radius: number, startAngle: number, endAngle: number): void {
    this.ctx.arc(x, y, radius, startAngle, endAngle);
  }

  setLineDash(segments: number[]): void {
    this.ctx.setLineDash(segments);
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

  setGlobalAlpha(alpha: number): void {
    this.ctx.globalAlpha = alpha;
  }

  setGlobalCompositeOperation(op: string): void {
    this.ctx.globalCompositeOperation = op;
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

  drawImage(image: ImageBitmap, dx: number, dy: number, dw: number, dh: number): void {
    this.ctx.drawImage(image, dx, dy, dw, dh);
  }
}

// 渲染上下文实现 B：包装 OffscreenCanvas 上下文 OffscreenCanvasRenderingContext2D
// 与 Canvas2DRenderContext 方法集一致（渲染器按鸭子类型调用，运行时安全）
export class Canvas2DOffscreenRenderContext implements RenderContext {
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

  arc(x: number, y: number, radius: number, startAngle: number, endAngle: number): void {
    this.ctx.arc(x, y, radius, startAngle, endAngle);
  }

  setLineDash(segments: number[]): void {
    this.ctx.setLineDash(segments);
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

  setGlobalAlpha(alpha: number): void {
    this.ctx.globalAlpha = alpha;
  }

  setGlobalCompositeOperation(op: string): void {
    this.ctx.globalCompositeOperation = op;
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

  drawImage(image: ImageBitmap, dx: number, dy: number, dw: number, dh: number): void {
    this.ctx.drawImage(image, dx, dy, dw, dh);
  }
}

export class Canvas2DStrokeRenderer implements StrokeRenderer {
  private splatTexture: ImageBitmap | null = null;
  private splatScratch: OffscreenCanvas | null = null;
  // 擦除遮罩渲染宽度（可由页面设置）
  private eraserMaskWidth: number = 20;

  constructor() {
  }

  // T-040 修复：程序化铅笔纹理（石墨颗粒 + 径向透明边缘）
  // 原版（uaa/PencilSplatRenderer）用资源 BitmapShader 提供铅笔质感；鸿蒙无该资源，
  // 用确定性伪随机颗粒生成 64×64 纹理替代：中心浓密、边缘渐淡，splat 叠加后形成连续铅笔痕
  static generatePencilTexture(): ImageBitmap {
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
    return canvas.transferToImageBitmap();
  }

  setSplatTexture(texture: ImageBitmap): void {
    if (this.splatTexture !== null && this.splatTexture !== texture) {
      this.splatTexture.close();
    }
    this.splatTexture = texture;
  }

  dispose(): void {
    if (this.splatTexture !== null) {
      this.splatTexture.close();
      this.splatTexture = null;
    }
    this.splatScratch = null;
  }

  setEraserMaskWidth(width: number): void {
    this.eraserMaskWidth = width;
  }

  // === 中心线路径（Mono/Dash/Dot，pzf.g 规格）===
  renderCenterPath(stroke: StrokeElementData, ctx: RenderContext): void {
    const c: Canvas2DRenderContext = ctx as Canvas2DRenderContext;
    const spec: RenderSpec = stroke.renderSpec;
    // 空路径检查（pzf.g 对齐）：无点直接返回
    if (stroke.pathPoints.length === 0) {
      return;
    }
    c.save();
    c.beginPath();
    const pts = stroke.pathPoints;
    if (pts.length > 0) {
      c.moveTo(pts[0].position.x, pts[0].position.y);
      const segs = stroke.cubicSegments;
      if (segs.length > 0) {
        for (const seg of segs) {
          c.bezierCurveTo(seg.p1.x, seg.p1.y, seg.p2.x, seg.p2.y, seg.p3.x, seg.p3.y);
        }
      } else {
        for (let i = 1; i < pts.length; i++) {
          c.lineTo(pts[i].position.x, pts[i].position.y);
        }
      }
    }
    c.setLineWidth(spec.brushWidth);
    // 原版 c5g：DASH 使用 BUTT，DOTS 与实线使用 ROUND。
    if (spec.inkStyle === InkStyle.DASH) {
      c.setLineCap('butt');
    } else {
      c.setLineCap('round');
    }
    c.setLineJoin('round');
    c.setStrokeStyle(this.colorToRgba(spec.color));
    if (spec.isHighlighter) {
      // 荧光笔：alpha 107/255 ≈ 0.42（yw1.e(color, 107)）
      c.setGlobalAlpha(107 / 255);
    }
    if (spec.inkStyle === InkStyle.DASH) {
      c.setLineDash([2 * spec.brushWidth, 1 * spec.brushWidth]);
    } else if (spec.inkStyle === InkStyle.DOTS) {
      c.setLineDash([0.001 * spec.brushWidth, 2 * spec.brushWidth]);
    }
    c.stroke();
    c.restore();
  }

  // === 可变宽度填充轮廓（Taper，w4a.b()）===
  renderVariableWidthOutline(stroke: StrokeElementData, ctx: RenderContext): void {
    const c: Canvas2DRenderContext = ctx as Canvas2DRenderContext;
    const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
    const outline = builder.build(
      stroke.pathPoints, stroke.renderSpec.brushWidth, stroke.cubicSegments);
    if (!outline.isValid) {
      return;
    }
    c.save();
    c.beginPath();
    c.moveTo(outline.outlinePoints[0].x, outline.outlinePoints[0].y);
    for (let i = 1; i < outline.outlinePoints.length; i++) {
      c.lineTo(outline.outlinePoints[i].x, outline.outlinePoints[i].y);
    }
    c.closePath();
    c.setFillStyle(this.colorToRgba(stroke.renderSpec.color));
    if (stroke.renderSpec.isHighlighter) {
      // c5g.g 对所有笔迹形态统一把荧光笔颜色 alpha 设为 107。
      c.setGlobalAlpha(107 / 255);
    }
    c.fill();
    c.restore();
  }

  // === PencilSplat 渲染（OffscreenCanvas + source-in 着色，§37）===
  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, ctx: RenderContext): void {
    if (splats.length === 0) {
      return;
    }
    const c: Canvas2DRenderContext = ctx as Canvas2DRenderContext;
    // 计算 splat 包围盒（splat 坐标为绝对画布坐标，离屏用相对坐标绘制）
    // xaa/cfa 的 scale 语义为页面半径（直径 = 2*scale）；包围盒同样以 scale 外扩。
    let minX: number = Number.MAX_VALUE;
    let minY: number = Number.MAX_VALUE;
    let maxX: number = -Number.MAX_VALUE;
    let maxY: number = -Number.MAX_VALUE;
    for (const s of splats) {
      const r: number = s.scale + 2;
      if (s.x - r < minX) {
        minX = s.x - r;
      }
      if (s.x + r > maxX) {
        maxX = s.x + r;
      }
      if (s.y - r < minY) {
        minY = s.y - r;
      }
      if (s.y + r > maxY) {
        maxY = s.y + r;
      }
    }
    const w: number = Math.max(maxX - minX, 1);
    const h: number = Math.max(maxY - minY, 1);
    let off: OffscreenCanvas;
    if (this.splatScratch === null) {
      off = new OffscreenCanvas(w, h);
      this.splatScratch = off;
    } else {
      off = this.splatScratch;
      off.width = w;
      off.height = h;
    }
    const offCtx: OffscreenCanvasRenderingContext2D =
      off.getContext('2d', new RenderingContextSettings(true));
    offCtx.clearRect(0, 0, off.width, off.height);
    const tex: ImageBitmap | null = this.splatTexture;
    for (const s of splats) {
      offCtx.save();
      offCtx.translate(s.x - minX, s.y - minY);
      offCtx.rotate(s.rotation);
      offCtx.globalAlpha = s.opacity;
      if (tex !== null) {
        // s.scale 的唯一单位是页面半径；原版纹理无论原始分辨率均映射到直径 2*scale。
        offCtx.drawImage(tex, -s.scale, -s.scale, 2 * s.scale, 2 * s.scale);
      } else {
        // fallback 与纹理路径使用完全相同的外接尺寸，避免二次 scale。
        offCtx.beginPath();
        offCtx.arc(0, 0, s.scale, 0, Math.PI * 2);
        offCtx.fillStyle = '#FFFFFF';
        offCtx.fill();
      }
      offCtx.restore();
    }
    // source-in 着色：用笔色替换 alpha 形状
    offCtx.globalCompositeOperation = 'source-in';
    offCtx.fillStyle = this.colorToRgba(spec.color);
    offCtx.fillRect(0, 0, off.width, off.height);
    offCtx.globalCompositeOperation = 'source-over';
    // 合成到主画布（相对包围盒定位）
    const bmp: ImageBitmap = off.transferToImageBitmap();
    try {
      c.drawImage(bmp, minX, minY, w, h);
    } finally {
      bmp.close();
    }
  }

  // === 擦除遮罩（destination-out 挖洞）===
  renderEraserMask(stroke: StrokeElementData, ctx: RenderContext): void {
    if (stroke.maskPath.length === 0) {
      return;
    }
    const c: Canvas2DRenderContext = ctx as Canvas2DRenderContext;
    c.save();
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
    c.restore();
  }

  private isMaskBreak(point: Point2D): boolean {
    return point.x === ERASER_PATH_BREAK_COORDINATE && point.y === ERASER_PATH_BREAK_COORDINATE;
  }

  // 工具：ARGB int → rgba 字符串
  private colorToRgba(argb: number): string {
    const a: number = (argb >>> 24) & 0xFF;
    const r: number = (argb >>> 16) & 0xFF;
    const g: number = (argb >>> 8) & 0xFF;
    const b: number = argb & 0xFF;
    return 'rgba(' + r + ',' + g + ',' + b + ',' + (a / 255) + ')';
  }
}
