import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { RenderContext, StrokeRenderer } from '../core/adaptation/StrokeRenderer';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator, PencilSplatLimitError,
} from '../core/algorithm/PencilSplatGenerator';
import { ElementType, ShapeElement } from '../core/model/ElementTypes';
import {
  ShapeStrokeComponent, ShapeStrokeGeometry, shapeStrokeGeometry,
} from '../core/model/ShapeStrokeGeometry';
import {
  InkPathCommand, InkPathCommandType, InkStyle, PencilSplatPoint, RenderSpec,
} from '../core/model/StrokeTypes';

interface CachedShapePencilSplats {
  geometry: ShapeStrokeGeometry;
  strokeWidth: number;
  splats: PencilSplatPoint[][];
  splatCount: number;
}

const MAX_PENCIL_CACHE_ENTRIES: number = 32;
const MAX_PENCIL_CACHE_SPLATS: number = 262144;

export class ShapeCanvasRenderer {
  private renderer: StrokeRenderer;
  private pencilCache: Map<string, CachedShapePencilSplats> =
    new Map<string, CachedShapePencilSplats>();
  private cachedSplatCount: number = 0;

  constructor(renderer: StrokeRenderer) {
    this.renderer = renderer;
  }

  renderShape(shape: ShapeElement, context: RenderContext): void {
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    const geometry: ShapeStrokeGeometry = shapeStrokeGeometry(shape);
    ctx.save();
    try {
      ctx.transform(shape.transform);
      // p16/k16 uses the separate Pencil Shape content and does not pass Shape fillColor into it.
      // Pen/Highlighter/Tape retain the normal Shape fill before the border/tool rendering.
      if (shape.originalTool !== 1 && shape.type !== ElementType.LINE && shape.fillColor !== null) {
        this.fillShape(shape, geometry, ctx);
      }
      if (shape.originalTool === 1) {
        if (!this.renderPencil(shape, geometry, context)) {
          this.strokeShape(shape, geometry, ctx, false);
        }
        return;
      }
      this.strokeShape(shape, geometry, ctx, shape.originalTool === 2);
    } finally {
      ctx.restore();
    }
  }

  clearPencilCache(): void {
    this.pencilCache.clear();
    this.cachedSplatCount = 0;
  }

  private fillShape(shape: ShapeElement, geometry: ShapeStrokeGeometry,
    ctx: Canvas2DDrawingContext): void {
    if (geometry.components.length === 0) {
      return;
    }
    ctx.beginPath();
    this.appendComponent(ctx, geometry.components[0]);
    ctx.setFillStyle(this.colorToRgba(shape.fillColor as number));
    ctx.fill();
  }

  private strokeShape(shape: ShapeElement, geometry: ShapeStrokeGeometry,
    ctx: Canvas2DDrawingContext, highlighter: boolean): void {
    if (geometry.components.length === 0) {
      return;
    }
    ctx.beginPath();
    for (const component of geometry.components) {
      this.appendComponent(ctx, component);
    }
    ctx.setLineWidth(shape.strokeWidth);
    ctx.setLineCap(shape.originalStyle === 2 ? 'butt' : 'round');
    ctx.setLineJoin(shape.originalStyle === 3 ? 'miter' : 'round');
    if (shape.originalStyle === 2) {
      ctx.setLineDash([2 * shape.strokeWidth, shape.strokeWidth]);
    } else if (shape.originalStyle === 3) {
      ctx.setLineDash([0.001 * shape.strokeWidth, 2 * shape.strokeWidth]);
    } else {
      ctx.setLineDash([]);
    }
    ctx.setStrokeStyle(this.colorToRgba(shape.color, highlighter ? 107 : undefined));
    ctx.stroke();
  }

  private renderPencil(shape: ShapeElement, geometry: ShapeStrokeGeometry,
    context: RenderContext): boolean {
    const splats: PencilSplatPoint[][] | null = this.pencilSplats(shape, geometry);
    if (splats === null) {
      return false;
    }
    const spec: RenderSpec = {
      color: shape.color, brushWidth: shape.strokeWidth,
      inkStyle: this.inkStyle(shape), isHighlighter: false, isPencil: true,
      inkEffects: shape.originalInkEffects,
      inkEffectsTinted: shape.originalInkEffectsTinted,
    };
    for (const componentSplats of splats) {
      this.renderer.renderPencilSplats(componentSplats, spec, context);
    }
    return true;
  }

  private pencilSplats(shape: ShapeElement,
    geometry: ShapeStrokeGeometry): PencilSplatPoint[][] | null {
    const cached: CachedShapePencilSplats | undefined = this.pencilCache.get(shape.id);
    if (cached !== undefined && cached.strokeWidth === shape.strokeWidth &&
      this.sameGeometry(cached.geometry, geometry)) {
      this.pencilCache.delete(shape.id);
      this.pencilCache.set(shape.id, cached);
      return cached.splats;
    }
    if (cached !== undefined) {
      this.cachedSplatCount -= cached.splatCount;
      this.pencilCache.delete(shape.id);
    }
    const result: PencilSplatPoint[][] = [];
    let count: number = 0;
    try {
      for (const component of geometry.components) {
        const generator: PencilSplatGenerator = new PencilSplatGenerator({
          spacing: shape.strokeWidth,
          maximumSplatCount: Math.max(0, MAX_PENCIL_CACHE_SPLATS - count),
        });
        // y4d.b(): the arrow path is a second walk and explicitly resets the fallback seed.
        generator.reset(ORIGINAL_PENCIL_FALLBACK_SEED);
        const generated: PencilSplatPoint[] = generator.generate(
          component.cubicSegments, component.pathPoints);
        result.push(generated);
        count += generated.length;
      }
    } catch (error) {
      if (error instanceof PencilSplatLimitError) {
        console.warn(`Shape Pencil splat budget exceeded for ${shape.id}`);
        return null;
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(`Shape Pencil splat generation failed: ${JSON.stringify(error)}`);
    }
    if (count <= MAX_PENCIL_CACHE_SPLATS) {
      this.evictPencilCacheFor(count);
      const entry: CachedShapePencilSplats = {
        geometry: geometry, strokeWidth: shape.strokeWidth,
        splats: result, splatCount: count,
      };
      this.pencilCache.set(shape.id, entry);
      this.cachedSplatCount += count;
    }
    return result;
  }

  private evictPencilCacheFor(incomingCount: number): void {
    while (this.pencilCache.size >= MAX_PENCIL_CACHE_ENTRIES ||
      this.cachedSplatCount + incomingCount > MAX_PENCIL_CACHE_SPLATS) {
      const oldest: string | undefined = this.pencilCache.keys().next().value;
      if (oldest === undefined) {
        break;
      }
      const entry: CachedShapePencilSplats | undefined = this.pencilCache.get(oldest);
      if (entry !== undefined) {
        this.cachedSplatCount -= entry.splatCount;
      }
      this.pencilCache.delete(oldest);
    }
  }

  private sameGeometry(a: ShapeStrokeGeometry, b: ShapeStrokeGeometry): boolean {
    if (a.force !== b.force || a.components.length !== b.components.length) {
      return false;
    }
    for (let componentIndex: number = 0;
      componentIndex < a.components.length; componentIndex++) {
      const left: ShapeStrokeComponent = a.components[componentIndex];
      const right: ShapeStrokeComponent = b.components[componentIndex];
      if (left.closed !== right.closed || left.pathPoints.length !== right.pathPoints.length ||
        left.cubicSegments.length !== right.cubicSegments.length) {
        return false;
      }
      for (let index: number = 0; index < left.pathPoints.length; index++) {
        if (left.pathPoints[index].position.x !== right.pathPoints[index].position.x ||
          left.pathPoints[index].position.y !== right.pathPoints[index].position.y ||
          left.pathPoints[index].pressure !== right.pathPoints[index].pressure) {
          return false;
        }
      }
      for (let index: number = 0; index < left.cubicSegments.length; index++) {
        const l = left.cubicSegments[index];
        const r = right.cubicSegments[index];
        if (l.p0.x !== r.p0.x || l.p0.y !== r.p0.y ||
          l.p1.x !== r.p1.x || l.p1.y !== r.p1.y ||
          l.p2.x !== r.p2.x || l.p2.y !== r.p2.y ||
          l.p3.x !== r.p3.x || l.p3.y !== r.p3.y) {
          return false;
        }
      }
    }
    return true;
  }

  private appendComponent(ctx: Canvas2DDrawingContext, component: ShapeStrokeComponent): void {
    for (const command of component.pathCommands) {
      this.appendCommand(ctx, command);
    }
    if (component.closed) {
      ctx.closePath();
    }
  }

  private appendCommand(ctx: Canvas2DDrawingContext, command: InkPathCommand): void {
    if (command.type === InkPathCommandType.MOVE_TO) {
      ctx.moveTo(command.points[0].x, command.points[0].y);
    } else if (command.type === InkPathCommandType.LINE_TO) {
      ctx.lineTo(command.points[0].x, command.points[0].y);
    } else if (command.type === InkPathCommandType.QUADRATIC) {
      ctx.quadraticCurveTo(command.points[0].x, command.points[0].y,
        command.points[1].x, command.points[1].y);
    } else {
      ctx.bezierCurveTo(command.points[0].x, command.points[0].y,
        command.points[1].x, command.points[1].y,
        command.points[2].x, command.points[2].y);
    }
  }

  private inkStyle(shape: ShapeElement): InkStyle {
    return shape.originalStyle === 2 ? InkStyle.DASH :
      shape.originalStyle === 3 ? InkStyle.DOTS : InkStyle.FIXED_WIDTH;
  }

  private colorToRgba(argb: number, alphaOverride?: number): string {
    const alpha: number = alphaOverride === undefined ? (argb >>> 24) & 0xFF : alphaOverride;
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha / 255})`;
  }
}
