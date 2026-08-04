// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
import { PaperTemplate } from '../core/model/NoteTypes';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先白色填充，再叠加模板）
  // T-034：zoom 参数——线宽/点半径除以 zoom 保持视觉 1px（网格间距为画布坐标，随缩放）
  renderBackground(ctx: CanvasRenderingContext2D, width: number, height: number,
    template: PaperTemplate, zoom: number = 1.0): void {
    ctx.save();
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, width, height);
    switch (template) {
      case PaperTemplate.LINES:
        this.drawLines(ctx, width, height, zoom);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, width, height, zoom);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, width, height, zoom);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  // LINES: 水平线，间距 28vp，线宽保持视觉 0.5px
  private drawLines(ctx: CanvasRenderingContext2D, width: number, height: number,
    zoom: number): void {
    ctx.strokeStyle = '#E0E0E0';
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
    zoom: number): void {
    ctx.strokeStyle = '#E0E0E0';
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
    zoom: number): void {
    ctx.fillStyle = '#BDBDBD';
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
