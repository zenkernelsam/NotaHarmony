// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
import { PaperTemplate } from '../core/model/NoteTypes';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先白色填充，再叠加模板）
  renderBackground(ctx: CanvasRenderingContext2D, width: number, height: number,
    template: PaperTemplate): void {
    ctx.save();
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, width, height);
    switch (template) {
      case PaperTemplate.LINES:
        this.drawLines(ctx, width, height);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, width, height);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, width, height);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  // LINES: 水平线，间距 28vp，线宽 0.5，颜色 #E0E0E0
  private drawLines(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.strokeStyle = '#E0E0E0';
    ctx.lineWidth = 0.5;
    ctx.beginPath();
    const spacing: number = 28;
    for (let y = spacing; y < height; y += spacing) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }

  // GRID: 水平+垂直，间距 28vp
  private drawGrid(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.strokeStyle = '#E0E0E0';
    ctx.lineWidth = 0.5;
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

  // DOTS: 点阵，间距 28vp，半径 1.25，颜色 #BDBDBD
  private drawDots(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.fillStyle = '#BDBDBD';
    const spacing: number = 28;
    for (let y = spacing; y < height; y += spacing) {
      for (let x = spacing; x < width; x += spacing) {
        ctx.beginPath();
        ctx.arc(x, y, 1.25, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
