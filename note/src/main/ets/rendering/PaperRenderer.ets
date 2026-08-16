// T-020 纸张模板程序化绘制（§7：PLAIN/LINES/GRID/DOTS）
// T-038：theme 参数（纸张底色/线色随主题）
import { PageInfo, PagePaperBackground, PaperTemplate } from '../core/model/NoteTypes';
import {
  effectivePageBackground, POINTS_TO_PAGE_UNITS,
} from '../core/model/PageBackgroundModel';
import { PageBackground } from '../core/model/NoteTypes';
import { DarkTheme, LightTheme, ThemeTokens } from '../ui/theme/EditorTheme';
import {
  Canvas2DDrawingContext, Canvas2DOffscreenRenderContext, Canvas2DRenderContext,
} from '../core/adaptation/Canvas2DStrokeRenderer';
import {
  LoadedOriginalPaperTexture, ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE,
} from '../core/adaptation/OriginalPaperTextureLoader';
import {
  OriginalPaperRenderStyle, originalPaperRenderStyle,
} from '../core/model/OriginalPaperColor';
import { Rect2D } from '../core/model/GeometryTypes';

export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景（先填充底色，再叠加模板）
  // T-034：zoom 参数——线宽/点半径除以 zoom 保持视觉 1px（网格间距为画布坐标，随缩放）
  // T-038：theme 提供 paperBackground/paperLineColor
  // 纸张固定在页面坐标 (0,0)；屏幕上的居中/平移完全由 CanvasViewport 负责。
  renderBackground(ctx: CanvasRenderingContext2D, paperW: number, paperH: number,
    page: PageInfo, zoom: number = 1.0, theme: ThemeTokens = LightTheme,
    pdfBitmap: ImageBitmap | null = null,
    legacyTexture: LoadedOriginalPaperTexture | null = null,
    pdfRenderRect: Rect2D | null = null): void {
    this.renderToContext(new Canvas2DRenderContext(ctx), paperW, paperH, page, zoom, theme,
      pdfBitmap, legacyTexture, pdfRenderRect);
  }

  renderOffscreenBackground(ctx: OffscreenCanvasRenderingContext2D, paperW: number, paperH: number,
    page: PageInfo, zoom: number = 1.0, theme: ThemeTokens = LightTheme,
    pdfBitmap: ImageBitmap | null = null,
    legacyTexture: LoadedOriginalPaperTexture | null = null,
    pdfRenderRect: Rect2D | null = null): void {
    this.renderToContext(new Canvas2DOffscreenRenderContext(ctx),
      paperW, paperH, page, zoom, theme, pdfBitmap, legacyTexture, pdfRenderRect);
  }

  private renderToContext(ctx: Canvas2DDrawingContext, paperW: number, paperH: number,
    page: PageInfo, zoom: number, theme: ThemeTokens, pdfBitmap: ImageBitmap | null,
    legacyTexture: LoadedOriginalPaperTexture | null, pdfRenderRect: Rect2D | null): void {
    const effectiveBackground: PageBackground | null = effectivePageBackground(page);
    const paper: PagePaperBackground | null = effectiveBackground === null ? null : effectiveBackground.paper;
    const style: OriginalPaperRenderStyle = originalPaperRenderStyle(
      paper, theme.paperBackground, theme.paperLineColor, this.isDarkTheme(theme));
    ctx.save();
    ctx.setFillStyle(style.backgroundColor);
    ctx.fillRect(0, 0, paperW, paperH);
    if (paper !== null && paper.legacyPaperIndex !== null && legacyTexture !== null &&
      legacyTexture.legacyPaperIndex === paper.legacyPaperIndex) {
      ctx.save();
      ctx.setFilter(style.invertLegacyTexture ? 'invert(1)' : 'none');
      if (ctx.setFillPattern(legacyTexture.bitmap, ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE,
        ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE)) {
        ctx.fillRect(0, 0, paperW, paperH);
      }
      ctx.restore();
    }
    if (effectiveBackground !== null && effectiveBackground.pdf !== undefined &&
      effectiveBackground.pdf !== null && pdfBitmap !== null) {
      this.drawPdfBackground(ctx, paperW, paperH, effectiveBackground, pdfBitmap, pdfRenderRect);
    }
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
        this.drawLines(ctx, paperW, paperH, spacing, centered, bleeds, zoom, style.lineColor);
        break;
      case PaperTemplate.GRID:
        this.drawGrid(ctx, paperW, paperH, spacing, centered, bleeds, zoom, style.lineColor);
        break;
      case PaperTemplate.DOTS:
        this.drawDots(ctx, paperW, paperH, spacing, centered, bleeds, zoom, style.lineColor);
        break;
      default:
        break;  // PLAIN 空白
    }
    ctx.restore();
  }

  private isDarkTheme(theme: ThemeTokens): boolean {
    return theme.background === DarkTheme.background &&
      theme.paperBackground === DarkTheme.paperBackground;
  }

  private drawPdfBackground(ctx: Canvas2DDrawingContext, paperW: number, paperH: number,
    background: PageBackground, bitmap: ImageBitmap, pdfRenderRect: Rect2D | null): void {
    const margins = background.margins;
    const left: number = margins === null ? 0 : margins.leftPt * POINTS_TO_PAGE_UNITS;
    const top: number = margins === null ? 0 : margins.topPt * POINTS_TO_PAGE_UNITS;
    const right: number = margins === null ? 0 : margins.rightPt * POINTS_TO_PAGE_UNITS;
    const bottom: number = margins === null ? 0 : margins.bottomPt * POINTS_TO_PAGE_UNITS;
    const rotated: boolean = Math.abs(background.rotationRadians - Math.PI / 2) < 0.0001 ||
      Math.abs(background.rotationRadians - Math.PI * 3 / 2) < 0.0001;
    const sourceWidth: number = rotated ? paperH : paperW;
    const sourceHeight: number = rotated ? paperW : paperH;
    const contentRect: Rect2D = {
      left: left,
      top: top,
      right: Math.max(left, sourceWidth - right),
      bottom: Math.max(top, sourceHeight - bottom),
    };
    const destination: Rect2D = pdfRenderRect === null ? contentRect : {
      left: Math.max(contentRect.left, pdfRenderRect.left),
      top: Math.max(contentRect.top, pdfRenderRect.top),
      right: Math.min(contentRect.right, pdfRenderRect.right),
      bottom: Math.min(contentRect.bottom, pdfRenderRect.bottom),
    };
    if (destination.left >= destination.right || destination.top >= destination.bottom) {
      return;
    }
    ctx.save();
    if (Math.abs(background.rotationRadians - Math.PI / 2) < 0.0001) {
      ctx.translate(paperW, 0);
      ctx.rotate(Math.PI / 2);
    } else if (Math.abs(background.rotationRadians - Math.PI) < 0.0001) {
      ctx.translate(paperW, paperH);
      ctx.rotate(Math.PI);
    } else if (Math.abs(background.rotationRadians - Math.PI * 3 / 2) < 0.0001) {
      ctx.translate(0, paperH);
      ctx.rotate(Math.PI * 3 / 2);
    }
    ctx.drawImage(bitmap, destination.left, destination.top,
      destination.right - destination.left, destination.bottom - destination.top);
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
