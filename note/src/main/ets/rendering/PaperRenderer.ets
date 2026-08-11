// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
// T-038：theme 参数（纸张底色/线色随主题）
import { PageInfo, PagePaperBackground, PaperTemplate } from '../core/model/NoteTypes';
import {
  effectivePageBackground, pageBackgroundCssColor, POINTS_TO_PAGE_UNITS,
} from '../core/model/PageBackgroundModel';
import { PageBackground } from '../core/model/NoteTypes';
import { LightTheme, ThemeTokens } from '../ui/theme/EditorTheme';
import {
  Canvas2DDrawingContext, Canvas2DOffscreenRenderContext, Canvas2DRenderContext,
} from '../core/adaptation/Canvas2DStrokeRenderer';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先填充底色，再叠加模板）
  // T-034：zoom 参数——线宽/点半径除以 zoom 保持视觉 1px（网格间距为画布坐标，随缩放）
  // T-038：theme 提供 paperBackground/paperLineColor
  // 纸张固定在页面坐标 (0,0)；屏幕上的居中/平移完全由 CanvasViewport 负责。
  renderBackground(ctx: CanvasRenderingContext2D, paperW: number, paperH: number,
    page: PageInfo, zoom: number = 1.0, theme: ThemeTokens = LightTheme): void {
    this.renderToContext(new Canvas2DRenderContext(ctx), paperW, paperH, page, zoom, theme);
  }

  renderOffscreenBackground(ctx: OffscreenCanvasRenderingContext2D, paperW: number, paperH: number,
    page: PageInfo, zoom: number = 1.0, theme: ThemeTokens = LightTheme): void {
    this.renderToContext(new Canvas2DOffscreenRenderContext(ctx),
      paperW, paperH, page, zoom, theme);
  }

  private renderToContext(ctx: Canvas2DDrawingContext, paperW: number, paperH: number,
    page: PageInfo, zoom: number, theme: ThemeTokens): void {
    const effectiveBackground: PageBackground | null = effectivePageBackground(page);
    ctx.save();
    ctx.setFillStyle(pageBackgroundCssColor(effectiveBackground, theme.paperBackground));
    ctx.fillRect(0, 0, paperW, paperH);
    const paper: PagePaperBackground | null = effectiveBackground === null ? null : effectiveBackground.paper;
    const spacing: number = paper === null || paper.flairSpacingPt === null
      ? 28 : paper.flairSpacingPt * POINTS_TO_PAGE_UNITS;
    if (!Number.isFinite(spacing) || spacing <= 1) {
      ctx.restore();
      return;
    }
    const centered: boolean = paper !== null && paper.flairCentered === true;
    const bleeds: boolean = paper !== null && paper.flairBleeds === true;
    switch (page.template) {
      case PaperTemplate.LINES:
        this.drawLines(ctx, paperW, paperH, spacing, centered, bleeds, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, paperW, paperH, spacing, centered, bleeds, zoom, theme.paperLineColor);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, paperW, paperH, spacing, centered, bleeds, zoom, theme.paperLineColor);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  // LINES: 水平线，间距 28vp，线宽保持视觉 0.5px
  private drawLines(ctx: Canvas2DDrawingContext, w: number, h: number, spacing: number,
    centered: boolean, bleeds: boolean, zoom: number, lineColor: string): void {
    ctx.setStrokeStyle(lineColor);
    ctx.setLineWidth(0.5 / zoom);
    ctx.beginPath();
    const positions: PaperGridPositions = this.gridPositions(w, h, spacing, centered, bleeds, false);
    for (const y of positions.horizontal) {
      ctx.moveTo(0, y);
      ctx.lineTo(w, y);
    }
    ctx.stroke();
  }

  // GRID: 水平+垂直，间距 28vp
  private drawGrid(ctx: Canvas2DDrawingContext, w: number, h: number, spacing: number,
    centered: boolean, bleeds: boolean, zoom: number, lineColor: string): void {
    ctx.setStrokeStyle(lineColor);
    ctx.setLineWidth(0.5 / zoom);
    ctx.beginPath();
    const positions: PaperGridPositions = this.gridPositions(w, h, spacing, centered, bleeds, true);
    for (const y of positions.horizontal) {
      ctx.moveTo(0, y);
      ctx.lineTo(w, y);
    }
    for (const x of positions.vertical) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
    }
    ctx.stroke();
  }

  // DOTS: 点阵，间距 28vp，点半径保持视觉 1.25px
  private drawDots(ctx: Canvas2DDrawingContext, w: number, h: number, spacing: number,
    centered: boolean, bleeds: boolean, zoom: number, dotColor: string): void {
    ctx.setFillStyle(dotColor);
    const radius: number = 1.25 / zoom;
    const positions: PaperGridPositions = this.gridPositions(w, h, spacing, centered, bleeds, true);
    for (const y of positions.horizontal) {
      for (const x of positions.vertical) {
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  // Faithful port of original i8j.b/c. The original deliberately lets a
  // bleeding grid extend just outside the page; Canvas clips those marks.
  private gridPositions(width: number, height: number, spacing: number,
    centered: boolean, bleeds: boolean, includeVertical: boolean): PaperGridPositions {
    const horizontal: number[] = [];
    const vertical: number[] = [];
    if (!centered) {
      const countY: number = Math.ceil(height / spacing);
      const countX: number = Math.ceil(width / spacing);
      const xOffset: number = bleeds ? (width - (countX + 1) * spacing) * 0.5 : 0;
      for (let index: number = 1; index <= countY; index++) {
        horizontal.push(index * spacing);
      }
      if (includeVertical) {
        for (let index: number = 0; index <= countX; index++) {
          vertical.push(index * spacing + xOffset);
        }
      }
      return { horizontal: horizontal, vertical: vertical };
    }
    const half: number = spacing / 2;
    const countY: number = Math.floor((height - half) / spacing);
    const countX: number = Math.floor((width - half) / spacing);
    const xOffset: number = (width - countX * spacing) / 2;
    let yOffset: number = (height - countY * spacing) / 2;
    if (!includeVertical) {
      yOffset -= half;
    }
    for (let index: number = includeVertical ? 0 : 1; index <= countY; index++) {
      horizontal.push(index * spacing + yOffset);
    }
    if (includeVertical) {
      for (let index: number = 0; index <= countX; index++) {
        vertical.push(index * spacing + xOffset);
      }
    }
    return { horizontal: horizontal, vertical: vertical };
  }
}

interface PaperGridPositions {
  horizontal: number[];
  vertical: number[];
}
