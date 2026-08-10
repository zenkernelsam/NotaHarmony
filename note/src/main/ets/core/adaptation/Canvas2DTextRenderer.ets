import {
  RichTextCharacterStyle, RichTextCharacterStyleRun, RichTextParagraphStyle,
  RichTextParagraphStyleRun, TextBlockElement,
} from '../model/ElementTypes';
import { RenderContext } from './StrokeRenderer';
import { Canvas2DDrawingContext } from './Canvas2DStrokeRenderer';
import { OriginalPaperFlair, PagePaperBackground } from '../model/NoteTypes';

const TEXT_PAPER_POINTS_TO_UNITS: number = 96 / 72;

export class Canvas2DTextRenderer {
  renderText(element: TextBlockElement, context: RenderContext): void {
    const ctx: Canvas2DDrawingContext = context as Canvas2DDrawingContext;
    ctx.save();
    ctx.transform(element.transform);
    this.renderPaper(ctx, element);
    if (element.richText.length === 0) {
      ctx.restore();
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
    let lineStart: number = 0;
    let baseline: number = element.textOrigin.y + element.contentTopInset + element.fontSize;
    let numberedParagraph: number = 1;
    const lineEnds: number[] = this.lineEnds(ctx, characters, characterStyles, element);
    for (const index of lineEnds) {
      const paragraph: RichTextParagraphStyle = paragraphStyles[Math.min(
        lineStart, Math.max(0, characters.length - 1))] ?? {};
      const prefix: string = this.decoratorPrefix(paragraph.decoratorStyle, numberedParagraph);
      if (paragraph.decoratorStyle === 2) {
        numberedParagraph++;
      }
      const lineWidth: number = this.measureRange(ctx, characters, characterStyles,
        lineStart, index, element, prefix);
      let x: number = element.textOrigin.x + element.contentLeftInset +
        Math.max(0, paragraph.indentLevel ?? 0) * element.fontSize * 1.5;
      const available: number = Math.max(0, element.blockWidth - element.contentLeftInset * 2);
      if (paragraph.alignment === 2) {
        x += Math.max(0, (available - lineWidth) / 2);
      } else if (paragraph.alignment === 3) {
        x += Math.max(0, available - lineWidth);
      }
      if (prefix.length > 0) {
        const prefixStyle: RichTextCharacterStyle = characterStyles[lineStart] ?? {};
        this.applyFont(ctx, element, prefixStyle);
        ctx.setFillStyle(this.colorToRgba(prefixStyle.foregroundColor ?? element.fontColor));
        ctx.fillText(prefix, x, baseline);
        x += ctx.measureText(prefix);
      }
      for (let characterIndex: number = lineStart; characterIndex < index;) {
        let runEnd: number = characterIndex + 1;
        while (runEnd < index && this.sameCharacterStyle(
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
      lineStart = index + 1;
    }
    ctx.restore();
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
    ctx.restore();
  }

  private lineEnds(ctx: Canvas2DDrawingContext, characters: string[],
    styles: RichTextCharacterStyle[], element: TextBlockElement): number[] {
    const ends: number[] = [];
    const wrap: number = element.resizesWidthToFitText === true ? 1 :
      (element.textWrap === undefined ? 0 : element.textWrap);
    const available: number = Math.max(1, element.blockWidth - element.contentLeftInset * 2);
    let start: number = 0;
    let width: number = 0;
    let lastBreak: number = -1;
    for (let index: number = 0; index <= characters.length; index++) {
      const atEnd: boolean = index === characters.length;
      const character: string = atEnd ? '' : characters[index];
      if (atEnd || character === '\n') {
        ends.push(index);
        start = index + 1;
        width = 0;
        lastBreak = -1;
        continue;
      }
      const nextWidth: number = width + this.measureRange(ctx, characters, styles,
        index, index + 1, element, '');
      if (wrap === 0 && nextWidth > available && index > start) {
        const end: number = lastBreak > start ? lastBreak : index;
        ends.push(end);
        start = end;
        while (start < characters.length && characters[start] === ' ') {
          start++;
        }
        index = start - 1;
        width = 0;
        lastBreak = -1;
        continue;
      }
      width = nextWidth;
      if (character === ' ' || character === '\t') {
        lastBreak = index;
      }
    }
    return ends;
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
    element: TextBlockElement, prefix: string): number {
    let width: number = 0;
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

  private decoratorPrefix(style: number | undefined, number: number): string {
    if (style === 1) {
      return '\u2022 ';
    }
    if (style === 2) {
      return number.toString() + '. ';
    }
    if (style === 3) {
      return '\u2610 ';
    }
    if (style === 4) {
      return '> ';
    }
    return '';
  }

  private colorToRgba(argb: number): string {
    const alpha: number = (argb >>> 24) & 0xFF;
    const red: number = (argb >>> 16) & 0xFF;
    const green: number = (argb >>> 8) & 0xFF;
    const blue: number = argb & 0xFF;
    return `rgba(${red},${green},${blue},${alpha / 255})`;
  }
}
