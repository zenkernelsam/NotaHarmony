import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { MathElement } from '../core/model/ElementTypes';

// The original uses its private GLMath native engine. Until an equivalent engine is available,
// render only a non-semantic block boundary instead of misrepresenting LaTeX as plain text.
export class MathCanvasRenderer {
  renderMath(element: MathElement, ctx: Canvas2DDrawingContext): void {
    if (element.latex.length === 0 || element.blockWidth <= 0 || element.blockHeight <= 0) {
      return;
    }
    ctx.save();
    ctx.transform(element.transform);
    ctx.beginPath();
    ctx.rect(0, 0, element.blockWidth, element.blockHeight);
    ctx.setLineWidth(1);
    ctx.setLineDash([4, 3]);
    ctx.setStrokeStyle(colorToRgba(element.color, 0.35));
    ctx.stroke();
    ctx.restore();
  }
}

function colorToRgba(argb: number, alphaScale: number): string {
  const alpha: number = ((argb >>> 24) & 0xFF) / 255 * alphaScale;
  const red: number = (argb >>> 16) & 0xFF;
  const green: number = (argb >>> 8) & 0xFF;
  const blue: number = argb & 0xFF;
  return `rgba(${red},${green},${blue},${alpha})`;
}
