// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
// T-038：theme 参数（纸张底色/线色随主题）
import { PaperTemplate } from '../core/model/NoteTypes';
import { LightTheme, ThemeTokens } from '../ui/theme/EditorTheme';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先填充底色，再叠加模板）
  // T-034：zoom 参数——线宽/点半径除以 zoom 保持视觉 1px（网格间距为画布坐标，随缩放）
  // T-038：theme 提供 paperBackground/paperLineColor
  renderBackground(ctx: CanvasRenderingContext2D, width: number, height: number,
    template: PaperTemplate, zoom: number = 1.0, theme: ThemeTokens = LightTheme): void {
    ctx.save();
    ctx.fillStyle = theme.paperBackground;
    ctx.fillRect(0, 0, width, height);
    switch (template) {
      case PaperTemplate.LINES:
        this.drawLines(ctx, width, height, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, width, height, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, width, height, zoom, theme.paperLineColor);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  // LINES: 水平线，间距 28vp，线宽保持视觉 0.5px
  private drawLines(ctx: CanvasRenderingContext2D, width: number, height: number,
    zoom: number, lineColor: string): void {
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 0.5 / zoom;
    ctx.beginPath();
    const spacing: number = 28;
    for (let y = spacing; y < height; y += spacing) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }

  // GRID: 水平+垂直，间距 28vp
  private drawGrid(ctx: CanvasRenderingContext2D, width: number, height: number,
    zoom: number, lineColor: string): void {
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 0.5 / zoom;
    ctx.beginPath();
    const spacing: number = 28;
    for (let y = spacing; y < height; y += spacing) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    for (let x = spacing; x < width; x += spacing) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
    }
    ctx.stroke();
  }

  // DOTS: 点阵，间距 28vp，点半径保持视觉 1.25px
  private drawDots(ctx: CanvasRenderingContext2D, width: number, height: number,
    zoom: number, dotColor: string): void {
    ctx.fillStyle = dotColor;
    const spacing: number = 28;
    const radius: number = 1.25 / zoom;
    for (let y = spacing; y < height; y += spacing) {
      for (let x = spacing; x < width; x += spacing) {
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
