import {
  RichTextCharacterStyle, RichTextCharacterStyleRun, RichTextParagraphStyle,
  RichTextParagraphStyleRun, TextBlockElement,
} from '../model/ElementTypes';
import { RenderContext } from './StrokeRenderer';
import { Canvas2DDrawingContext } from './Canvas2DStrokeRenderer';
import { OriginalPaperFlair, PagePaperBackground } from '../model/NoteTypes';
import { Point2D } from '../model/GeometryTypes';

const TEXT_PAPER_POINTS_TO_UNITS: number = 96 / 72;

interface TextLayoutLine {
  start: number;
  end: number;
  paragraphStart: boolean;
}

export interface TextCheckboxMarker {
  codePointIndex: number;
  center: Point2D;
  radius: number;
}

export class Canvas2DTextRenderer {
  measureNaturalWidth(element: TextBlockElement, context: RenderContext): number {
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    const characters: string[] = [];
    for (const character of element.richText) {
      characters.push(character);
    }
    const characterStyles: RichTextCharacterStyle[] = this.characterStyles(
      characters.length, element.characterStyleRuns);
    const paragraphStyles: RichTextParagraphStyle[] = this.paragraphStyles(
      characters.length, element.paragraphStyleRuns);
    let maximum: number = Math.max(1, element.contentLeftInset +
      (element.contentRightInset ?? element.contentLeftInset));
    let lineStart: number = 0;
    let numberedParagraph: number = 1;
    ctx.save();
    try {
      for (let index: number = 0; index <= characters.length; index++) {
        if (index < characters.length && characters[index] !== '\n') {
          continue;
        }
        const paragraph: RichTextParagraphStyle = paragraphStyles[Math.min(
          lineStart, Math.max(0, characters.length - 1))] ?? {};
        const prefix: string = this.decoratorPrefix(
          paragraph.decoratorStyle, numberedParagraph, paragraph.isChecked);
        if (paragraph.decoratorStyle === 2) {
          numberedParagraph++;
        }
        const indent: number = this.paragraphIndent(element, paragraph);
        const lineWidth: number = this.measureRange(ctx, characters, characterStyles,
          lineStart, index, element, prefix, paragraph.decoratorStyle === 3);
        maximum = Math.max(maximum, element.contentLeftInset +
          (element.contentRightInset ?? element.contentLeftInset) + indent + lineWidth);
        lineStart = index + 1;
      }
    } finally {
      ctx.restore();
    }
    return Math.ceil(maximum);
  }

  renderText(element: TextBlockElement, context: RenderContext): void {
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    ctx.save();
    try {
      ctx.transform(element.transform);
      this.renderPaper(ctx, element);
      if (element.richText.length === 0) {
        return;
      }
      const characters: string[] = [];
      for (const character of element.richText) {
        characters.push(character);
      }
      const characterStyles: RichTextCharacterStyle[] = this.characterStyles(
        characters.length, element.characterStyleRuns);
      const paragraphStyles: RichTextParagraphStyle[] = this.paragraphStyles(
        characters.length, element.paragraphStyleRuns);
      let baseline: number = element.textOrigin.y + element.contentTopInset + element.fontSize;
      let numberedParagraph: number = 1;
      const lines: TextLayoutLine[] = this.layoutLines(ctx, characters, characterStyles, element);
      for (const line of lines) {
        const lineStart: number = line.start;
        const paragraph: RichTextParagraphStyle = paragraphStyles[Math.min(
          lineStart, Math.max(0, characters.length - 1))] ?? {};
        const prefix: string = line.paragraphStart ? this.decoratorPrefix(
          paragraph.decoratorStyle, numberedParagraph, paragraph.isChecked) : '';
        if (line.paragraphStart && paragraph.decoratorStyle === 2) {
          numberedParagraph++;
        }
        const lineWidth: number = this.measureRange(ctx, characters, characterStyles,
          lineStart, line.end, element, prefix,
          line.paragraphStart && paragraph.decoratorStyle === 3);
        let x: number = element.textOrigin.x + element.contentLeftInset +
          this.paragraphIndent(element, paragraph);
        const available: number = Math.max(0, element.blockWidth - element.contentLeftInset -
          (element.contentRightInset ?? element.contentLeftInset));
        if (paragraph.alignment === 2) {
          x += Math.max(0, (available - lineWidth) / 2);
        } else if (paragraph.alignment === 3) {
          x += Math.max(0, available - lineWidth);
        }
        if (line.paragraphStart && paragraph.decoratorStyle === 3) {
          const center: Point2D = {
            x: x + this.checkboxRadius(element),
            y: this.checkboxCenterY(element, baseline),
          };
          this.drawCheckboxMarker(ctx, center, this.checkboxRadius(element),
            paragraph.isChecked === true, characterStyles[lineStart]?.foregroundColor ??
              element.fontColor);
          x += this.checkboxColumnWidth(element);
        } else if (prefix.length > 0) {
          const prefixStyle: RichTextCharacterStyle = characterStyles[lineStart] ?? {};
          this.applyFont(ctx, element, prefixStyle);
          ctx.setFillStyle(this.colorToRgba(prefixStyle.foregroundColor ?? element.fontColor));
          ctx.fillText(prefix, x, baseline);
          x += ctx.measureText(prefix);
        }
        for (let characterIndex: number = lineStart; characterIndex < line.end;) {
          let runEnd: number = characterIndex + 1;
          while (runEnd < line.end && this.sameCharacterStyle(
            characterStyles[characterIndex], characterStyles[runEnd])) {
            runEnd++;
          }
          x = this.renderSpan(ctx, characters.slice(characterIndex, runEnd).join(''), x, baseline,
            element, characterStyles[characterIndex]);
          characterIndex = runEnd;
        }
        const spacing: number = paragraph.lineSpacing === undefined || paragraph.lineSpacing <= 0 ?
          1 : paragraph.lineSpacing;
        baseline += (element.fontSize + 8) * spacing;
      }
    } finally {
      ctx.restore();
    }
  }

  checkboxMarkers(element: TextBlockElement, context: RenderContext): TextCheckboxMarker[] {
    if (element.richText.length === 0) {
      return [];
    }
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    const characters: string[] = [];
    for (const character of element.richText) {
      characters.push(character);
    }
    const characterStyles: RichTextCharacterStyle[] = this.characterStyles(
      characters.length, element.characterStyleRuns);
    const paragraphStyles: RichTextParagraphStyle[] = this.paragraphStyles(
      characters.length, element.paragraphStyleRuns);
    const result: TextCheckboxMarker[] = [];
    let baseline: number = element.textOrigin.y + element.contentTopInset + element.fontSize;
    let numberedParagraph: number = 1;
    ctx.save();
    try {
      const lines: TextLayoutLine[] = this.layoutLines(ctx, characters, characterStyles, element);
      for (const line of lines) {
        const paragraph: RichTextParagraphStyle = paragraphStyles[Math.min(
          line.start, Math.max(0, characters.length - 1))] ?? {};
        const prefix: string = line.paragraphStart ? this.decoratorPrefix(
          paragraph.decoratorStyle, numberedParagraph, paragraph.isChecked) : '';
        if (line.paragraphStart && paragraph.decoratorStyle === 2) {
          numberedParagraph++;
        }
        const lineWidth: number = this.measureRange(ctx, characters, characterStyles,
          line.start, line.end, element, prefix,
          line.paragraphStart && paragraph.decoratorStyle === 3);
        let x: number = element.textOrigin.x + element.contentLeftInset +
          this.paragraphIndent(element, paragraph);
        const available: number = Math.max(0, element.blockWidth - element.contentLeftInset -
          (element.contentRightInset ?? element.contentLeftInset));
        if (paragraph.alignment === 2) {
          x += Math.max(0, (available - lineWidth) / 2);
        } else if (paragraph.alignment === 3) {
          x += Math.max(0, available - lineWidth);
        }
        if (line.paragraphStart && paragraph.decoratorStyle === 3) {
          const radius: number = this.checkboxRadius(element);
          result.push({
            codePointIndex: line.start,
            center: {
              x: x + radius,
              y: this.checkboxCenterY(element, baseline),
            },
            radius: radius,
          });
        }
        const spacing: number = paragraph.lineSpacing === undefined || paragraph.lineSpacing <= 0 ?
          1 : paragraph.lineSpacing;
        baseline += (element.fontSize + 8) * spacing;
      }
    } finally {
      ctx.restore();
    }
    return result;
  }

  hitCheckboxMarker(element: TextBlockElement, context: RenderContext,
    worldPoint: Point2D): number | null {
    const local: Point2D | null = this.inverseTransformPoint(worldPoint, element);
    if (local === null) {
      return null;
    }
    for (const marker of this.checkboxMarkers(element, context)) {
      const dx: number = local.x - marker.center.x;
      const dy: number = local.y - marker.center.y;
      const tolerance: number = marker.radius * 1.5;
      if (dx * dx + dy * dy < tolerance * tolerance) {
        return marker.codePointIndex;
      }
    }
    return null;
  }

  private renderPaper(ctx: Canvas2DDrawingContext, element: TextBlockElement): void {
    const paper: PagePaperBackground | null = element.paper === undefined ? null : element.paper;
    if (paper === null) {
      return;
    }
    const left: number = element.textOrigin.x;
    const top: number = element.textOrigin.y;
    const width: number = element.blockWidth;
    const height: number = element.blockHeight;
    if (paper.colorR !== null && paper.colorG !== null && paper.colorB !== null &&
      paper.colorA !== null) {
      ctx.setFillStyle(`rgba(${paper.colorR},${paper.colorG},${paper.colorB},${paper.colorA / 255})`);
      ctx.fillRect(left, top, width, height);
    }
    if (paper.flair === null || paper.flairSpacingPt === null || paper.flairSpacingPt <= 0) {
      return;
    }
    const spacing: number = paper.flairSpacingPt * TEXT_PAPER_POINTS_TO_UNITS;
    ctx.save();
    try {
      ctx.beginPath();
      ctx.rect(left, top, width, height);
      ctx.clip();
      ctx.setStrokeStyle('rgba(90,90,90,0.24)');
      ctx.setFillStyle('rgba(90,90,90,0.32)');
      ctx.setLineWidth(1);
      const offsetX: number = paper.flairCentered === true ? (width % spacing) / 2 : 0;
      const offsetY: number = paper.flairCentered === true ? (height % spacing) / 2 : 0;
      if (paper.flair === OriginalPaperFlair.LINES || paper.flair === OriginalPaperFlair.GRID) {
        for (let y: number = top + offsetY; y <= top + height; y += spacing) {
          ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(left + width, y); ctx.stroke();
        }
      }
      if (paper.flair === OriginalPaperFlair.GRID) {
        for (let x: number = left + offsetX; x <= left + width; x += spacing) {
          ctx.beginPath(); ctx.moveTo(x, top); ctx.lineTo(x, top + height); ctx.stroke();
        }
      } else if (paper.flair === OriginalPaperFlair.DOTS) {
        for (let y: number = top + offsetY; y <= top + height; y += spacing) {
          for (let x: number = left + offsetX; x <= left + width; x += spacing) {
            ctx.beginPath(); ctx.arc(x, y, 1, 0, Math.PI * 2); ctx.fill();
          }
        }
      }
    } finally {
      ctx.restore();
    }
  }

  private layoutLines(ctx: Canvas2DDrawingContext, characters: string[],
    styles: RichTextCharacterStyle[], element: TextBlockElement): TextLayoutLine[] {
    const lines: TextLayoutLine[] = [];
    const wrap: number = element.resizesWidthToFitText === true ? 1 :
      (element.textWrap === undefined ? 0 : element.textWrap);
    const baseAvailable: number = Math.max(1, element.blockWidth - element.contentLeftInset -
      (element.contentRightInset ?? element.contentLeftInset));
    const paragraphStyles: RichTextParagraphStyle[] = this.paragraphStyles(
      characters.length, element.paragraphStyleRuns);
    let numberedParagraph: number = 1;
    let paragraphStart: number = 0;
    while (paragraphStart < characters.length) {
      let paragraphEnd: number = paragraphStart;
      while (paragraphEnd < characters.length && characters[paragraphEnd] !== '\n') {
        paragraphEnd++;
      }
      const paragraph: RichTextParagraphStyle = paragraphStyles[paragraphStart] ?? {};
      const available: number = Math.max(1, baseAvailable -
        this.paragraphIndent(element, paragraph));
      let start: number = paragraphStart;
      let firstLine: boolean = true;
      if (start === paragraphEnd) {
        lines.push({ start: start, end: start, paragraphStart: true });
      }
      while (start < paragraphEnd) {
        const prefix: string = firstLine ? this.decoratorPrefix(
          paragraph.decoratorStyle, numberedParagraph, paragraph.isChecked) : '';
        let width: number = this.measureRange(ctx, characters, styles,
          start, start, element, prefix,
          firstLine && paragraph.decoratorStyle === 3);
        let end: number = start;
        let lastBreak: number = -1;
        while (end < paragraphEnd) {
          const nextWidth: number = width + this.measureRange(ctx, characters, styles,
            end, end + 1, element, '');
          if (wrap === 0 && nextWidth > available && end > start) {
            break;
          }
          width = nextWidth;
          if (characters[end] === ' ' || characters[end] === '\t') {
            lastBreak = end;
          }
          end++;
        }
        if (end < paragraphEnd && lastBreak > start) {
          end = lastBreak;
        }
        lines.push({ start: start, end: end, paragraphStart: firstLine });
        if (end >= paragraphEnd) {
          break;
        }
        start = end;
        while (start < paragraphEnd && (characters[start] === ' ' || characters[start] === '\t')) {
          start++;
        }
        firstLine = false;
      }
      if (paragraph.decoratorStyle === 2) {
        numberedParagraph++;
      }
      paragraphStart = paragraphEnd + 1;
    }
    return lines;
  }

  private inverseTransformPoint(point: Point2D, element: TextBlockElement): Point2D | null {
    const matrix = element.transform;
    const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
    if (!Number.isFinite(determinant) || Math.abs(determinant) < 0.000001) {
      return null;
    }
    const dx: number = point.x - matrix[2];
    const dy: number = point.y - matrix[5];
    return {
      x: (matrix[4] * dx - matrix[1] * dy) / determinant,
      y: (-matrix[3] * dx + matrix[0] * dy) / determinant,
    };
  }

  private renderSpan(ctx: Canvas2DDrawingContext, text: string, x: number,
    baseline: number, element: TextBlockElement, style: RichTextCharacterStyle): number {
    this.applyFont(ctx, element, style);
    const width: number = ctx.measureText(text);
    const size: number = this.fontSize(element, style);
    let y: number = baseline;
    if (style.superscript === true) {
      y -= size * 0.35;
    } else if (style.subscript === true) {
      y += size * 0.25;
    }
    if (style.highlightColor !== undefined) {
      ctx.setFillStyle(this.colorToRgba(style.highlightColor));
      ctx.fillRect(x, y - size, width, size * 1.25);
    }
    const foreground: string = this.colorToRgba(style.foregroundColor ?? element.fontColor);
    ctx.setFillStyle(foreground);
    ctx.fillText(text, x, y);
    if (style.underline === true || style.link !== undefined) {
      this.drawDecoration(ctx, x, x + width, y + Math.max(1, size * 0.08), size, foreground);
    }
    if (style.strikethrough === true) {
      this.drawDecoration(ctx, x, x + width, y - size * 0.32, size, foreground);
    }
    return x + width;
  }

  private drawDecoration(ctx: Canvas2DDrawingContext, start: number, end: number,
    y: number, size: number, color: string): void {
    ctx.beginPath();
    ctx.moveTo(start, y);
    ctx.lineTo(end, y);
    ctx.setLineWidth(Math.max(1, size / 16));
    ctx.setStrokeStyle(color);
    ctx.stroke();
  }

  private measureRange(ctx: Canvas2DDrawingContext, characters: string[],
    styles: RichTextCharacterStyle[], start: number, end: number,
    element: TextBlockElement, prefix: string, checkboxPrefix: boolean = false): number {
    let width: number = checkboxPrefix ? this.checkboxColumnWidth(element) : 0;
    const prefixStyle: RichTextCharacterStyle = styles[start] ?? {};
    if (prefix.length > 0) {
      this.applyFont(ctx, element, prefixStyle);
      width += ctx.measureText(prefix);
    }
    for (let index: number = start; index < end;) {
      let runEnd: number = index + 1;
      while (runEnd < end && this.sameCharacterStyle(styles[index], styles[runEnd])) {
        runEnd++;
      }
      this.applyFont(ctx, element, styles[index]);
      width += ctx.measureText(characters.slice(index, runEnd).join(''));
      index = runEnd;
    }
    return width;
  }

  private applyFont(ctx: Canvas2DDrawingContext, element: TextBlockElement,
    style: RichTextCharacterStyle): void {
    const tokens: string[] = [];
    if (style.italic === true) {
      tokens.push('italic');
    }
    if (style.bold === true) {
      tokens.push('bold');
    }
    tokens.push(this.fontSize(element, style).toString() + 'px');
    const family: string = style.familyName === undefined ? 'sans-serif' :
      `"${style.familyName.replaceAll('"', '')}"`;
    tokens.push(family);
    ctx.setFont(tokens.join(' '));
  }

  private fontSize(element: TextBlockElement, style: RichTextCharacterStyle): number {
    const base: number = style.fontSize !== undefined && style.fontSize > 0 ?
      style.fontSize : element.fontSize;
    return style.superscript === true || style.subscript === true ? base * 0.75 : base;
  }

  private sameCharacterStyle(left: RichTextCharacterStyle,
    right: RichTextCharacterStyle): boolean {
    return JSON.stringify(left) === JSON.stringify(right);
  }

  private characterStyles(length: number, runs: RichTextCharacterStyleRun[] | undefined):
    RichTextCharacterStyle[] {
    const result: RichTextCharacterStyle[] = [];
    for (let index: number = 0; index < length; index++) {
      result.push({});
    }
    for (const run of runs ?? []) {
      const end: number = Math.min(length, run.end);
      for (let index: number = Math.max(0, run.start); index < end; index++) {
        result[index] = run.style;
      }
    }
    return result;
  }

  private paragraphStyles(length: number, runs: RichTextParagraphStyleRun[] | undefined):
    RichTextParagraphStyle[] {
    const result: RichTextParagraphStyle[] = [];
    for (let index: number = 0; index < length; index++) {
      result.push({});
    }
    for (const run of runs ?? []) {
      const end: number = Math.min(length, run.end);
      for (let index: number = Math.max(0, run.start); index < end; index++) {
        result[index] = run.style;
      }
    }
    return result;
  }

  private decoratorPrefix(style: number | undefined, number: number,
    isChecked: boolean | undefined): string {
    if (style === 1) {
      return '\u2022 ';
    }
    if (style === 2) {
      return number.toString() + '. ';
    }
    if (style === 3) {
      return '';
    }
    if (style === 4) {
      return '> ';
    }
    return '';
  }

  private paragraphIndent(element: TextBlockElement, paragraph: RichTextParagraphStyle): number {
    return Math.max(0, paragraph.indentLevel ?? 0) * element.fontSize * 36 / 14;
  }

  private checkboxColumnWidth(element: TextBlockElement): number {
    return element.fontSize * 1.6;
  }

  private checkboxRadius(element: TextBlockElement): number {
    const naturalLineHeight: number = element.fontSize + 8;
    return Math.max(naturalLineHeight / 2 - 1, naturalLineHeight / 4);
  }

  private checkboxCenterY(element: TextBlockElement, baseline: number): number {
    return baseline - element.fontSize + (element.fontSize + 8) / 2;
  }

  private drawCheckboxMarker(ctx: Canvas2DDrawingContext, center: Point2D, radius: number,
    isChecked: boolean, color: number): void {
    ctx.beginPath();
    ctx.arc(center.x, center.y, isChecked ? radius + 0.5 : radius, 0, Math.PI * 2);
    if (!isChecked) {
      ctx.setLineWidth(1);
      ctx.setStrokeStyle(this.colorToRgba(color, 0.75));
      ctx.stroke();
      return;
    }
    ctx.setFillStyle(this.colorToRgba(color));
    ctx.fill();
    const unit: number = radius * 2 / 15;
    const left: number = center.x - radius;
    const top: number = center.y - radius;
    const anchorX: number = left + unit * 3;
    const anchorY: number = top + unit * 4;
    ctx.beginPath();
    ctx.moveTo(anchorX + unit * 1.08, anchorY + unit * 3.24);
    ctx.lineTo(anchorX + unit * 2.88, anchorY + unit * 5.04);
    ctx.lineTo(anchorX + unit * 7.92, anchorY);
    ctx.lineTo(anchorX + unit * 9, anchorY + unit * 1.08);
    ctx.lineTo(anchorX + unit * 2.88, anchorY + unit * 7.2);
    ctx.lineTo(anchorX, anchorY + unit * 4.32);
    ctx.closePath();
    ctx.setFillStyle(this.checkboxCheckColor(color));
    ctx.fill();
  }

  private checkboxCheckColor(argb: number): string {
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    const luminance: number = (red * 0.299 + green * 0.587 + blue * 0.114) / 255;
    return luminance > 0.7 ? 'rgba(0,0,0,1)' : 'rgba(255,255,255,1)';
  }

  private colorToRgba(argb: number, alphaMultiplier: number = 1): string {
    const alpha: number = ((argb >>> 24) & 0xFF) * alphaMultiplier;
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha / 255})`;
  }
}
