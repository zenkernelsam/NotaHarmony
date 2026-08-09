import { TextBlockElement } from '../model/ElementTypes';
import { RenderContext } from './StrokeRenderer';
import { Canvas2DDrawingContext } from './Canvas2DStrokeRenderer';

export class Canvas2DTextRenderer {
  renderText(element: TextBlockElement, context: RenderContext): void {
    if (element.richText.length === 0) {
      return;
    }
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    ctx.save();
    ctx.transform(element.transform);
    ctx.setFont(element.fontSize.toString() + 'px sans-serif');
    ctx.setFillStyle(this.colorToRgba(element.fontColor));
    const x: number = element.textOrigin.x + element.contentLeftInset;
    const y: number = element.textOrigin.y + element.contentTopInset + element.fontSize;
    const lines: string[] = element.richText.split('\n');
    for (let i: number = 0; i < lines.length; i++) {
      ctx.fillText(lines[i], x, y + i * (element.fontSize + 8));
    }
    ctx.restore();
  }

  private colorToRgba(argb: number): string {
    const alpha: number = (argb >>> 24) & 0xFF;
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha / 255})`;
  }
}
