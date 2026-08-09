import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { RenderContext } from '../core/adaptation/StrokeRenderer';
import { ElementType, EllipseElement, PolygonElement, ShapeElement } from '../core/model/ElementTypes';
import { Point2D } from '../core/model/GeometryTypes';

const ELLIPSE_SEGMENTS: number = 64;

export class ShapeCanvasRenderer {
  renderShape(shape: ShapeElement, context: RenderContext): void {
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    ctx.save();
    ctx.transform(shape.transform);
    ctx.beginPath();
    if (shape.type === ElementType.ELLIPSE) {
      this.traceEllipse(shape, ctx);
    } else {
      this.tracePolygon(shape, ctx);
    }
    ctx.setLineWidth(shape.strokeWidth);
    ctx.setLineCap('round');
    ctx.setLineJoin('round');
    if (shape.fillColor !== null) {
      ctx.setFillStyle(this.colorToRgba(shape.fillColor));
      ctx.fill();
    }
    ctx.setStrokeStyle(this.colorToRgba(shape.color));
    ctx.stroke();
    ctx.restore();
  }

  private traceEllipse(shape: EllipseElement, ctx: Canvas2DDrawingContext): void {
    const cosRotation: number = Math.cos(shape.rotationRadians);
    const sinRotation: number = Math.sin(shape.rotationRadians);
    for (let i: number = 0; i <= ELLIPSE_SEGMENTS; i++) {
      const angle: number = i / ELLIPSE_SEGMENTS * Math.PI * 2;
      const localX: number = Math.cos(angle) * shape.radiusX;
      const localY: number = Math.sin(angle) * shape.radiusY;
      const point: Point2D = {
        x: shape.center.x + localX * cosRotation - localY * sinRotation,
        y: shape.center.y + localX * sinRotation + localY * cosRotation,
      };
      if (i === 0) {
        ctx.moveTo(point.x, point.y);
      } else {
        ctx.lineTo(point.x, point.y);
      }
    }
    ctx.closePath();
  }

  private tracePolygon(shape: PolygonElement, ctx: Canvas2DDrawingContext): void {
    if (shape.vertices.length === 0) {
      return;
    }
    ctx.moveTo(shape.vertices[0].x, shape.vertices[0].y);
    for (let i: number = 1; i < shape.vertices.length; i++) {
      ctx.lineTo(shape.vertices[i].x, shape.vertices[i].y);
    }
    if (shape.isClosed) {
      ctx.closePath();
    }
  }

  private colorToRgba(argb: number): string {
    const alpha: number = (argb >>> 24) & 0xFF;
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha / 255})`;
  }
}
