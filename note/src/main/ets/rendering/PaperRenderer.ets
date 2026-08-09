// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
// T-038：theme 参数（纸张底色/线色随主题）
import { PaperTemplate } from '../core/model/NoteTypes';
import { LightTheme, ThemeTokens } from '../ui/theme/EditorTheme';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先填充底色，再叠加模板）
  // T-034：zoom 参数——线宽/点半径除以 zoom 保持视觉 1px（网格间距为画布坐标，随缩放）
  // T-038：theme 提供 paperBackground/paperLineColor
  // 纸张固定在页面坐标 (0,0)；屏幕上的居中/平移完全由 CanvasViewport 负责。
  renderBackground(ctx: CanvasRenderingContext2D, paperW: number, paperH: number,
    template: PaperTemplate, zoom: number = 1.0, theme: ThemeTokens = LightTheme): void {
    ctx.save();
    // 纸张底色
    ctx.fillStyle = theme.paperBackground;
    ctx.fillRect(0, 0, paperW, paperH);
    switch (template) {
      case PaperTemplate.LINES:
        this.drawLines(ctx, 0, 0, paperW, paperH, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, 0, 0, paperW, paperH, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, 0, 0, paperW, paperH, zoom, theme.paperLineColor);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  // LINES: 水平线，间距 28vp，线宽保持视觉 0.5px
  private drawLines(ctx: CanvasRenderingContext2D, x0: number, y0: number, w: number, h: number,
    zoom: number, lineColor: string): void {
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 0.5 / zoom;
    ctx.beginPath();
    const spacing: number = 28;
    for (let y = y0 + spacing; y < y0 + h; y += spacing) {
      ctx.moveTo(x0, y);
      ctx.lineTo(x0 + w, y);
    }
    ctx.stroke();
  }

  // GRID: 水平+垂直，间距 28vp
  private drawGrid(ctx: CanvasRenderingContext2D, x0: number, y0: number, w: number, h: number,
    zoom: number, lineColor: string): void {
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 0.5 / zoom;
    ctx.beginPath();
    const spacing: number = 28;
    for (let y = y0 + spacing; y < y0 + h; y += spacing) {
      ctx.moveTo(x0, y);
      ctx.lineTo(x0 + w, y);
    }
    for (let x = x0 + spacing; x < x0 + w; x += spacing) {
      ctx.moveTo(x, y0);
      ctx.lineTo(x, y0 + h);
    }
    ctx.stroke();
  }

  // DOTS: 点阵，间距 28vp，点半径保持视觉 1.25px
  private drawDots(ctx: CanvasRenderingContext2D, x0: number, y0: number, w: number, h: number,
    zoom: number, dotColor: string): void {
    ctx.fillStyle = dotColor;
    const spacing: number = 28;
    const radius: number = 1.25 / zoom;
    for (let y = y0 + spacing; y < y0 + h; y += spacing) {
      for (let x = x0 + spacing; x < x0 + w; x += spacing) {
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
