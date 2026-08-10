// T-026 .note 包 JSON 结构定义（phase-4-backup-sync.md §2.2/§2.3）
// 纯类型 + 序列化工具：不 import 平台模块
// elements 保持 object[]（JSON 原始结构），但导入前必须按 exporter 的三种 payload 做结构校验。
import { ElementType, ShapeArrowHead, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { validateOriginalPaper } from '../core/model/PageBackgroundModel';
import { Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import { InkPathCommand, InkPathCommandType, InkStyle, InkStyleMapEntry, StrokeElementData,
  StrokePathPoint } from '../core/model/StrokeTypes';
import { PageBackground } from '../core/model/NoteTypes';
import { clonePageBackground, validatePageBackground } from '../core/model/PageBackgroundModel';

// .note 格式标识
export const NOTE_FORMAT: string = 'nota.note';
export const NOTE_FORMAT_VERSION: number = 1;
export const NOTE_SOURCE: string = 'NotaHarmony';
// 当前 writer 的 ZIP 条目上限为 65535；manifest.json 和 pages/ 至少占两个条目。
export const NOTE_MAX_PAGE_COUNT: number = 65533;

// manifest.json 结构（§2.2）
export interface NoteManifest {
  format: string;        // "nota.note"
  version: number;       // 1
  title: string;
  noteId: string;
  createdAt: number;
  updatedAt: number;
  pageCount: number;
  appVersion: string;
  source: string;        // "NotaHarmony"
}

// pages/page_N.json 结构（§2.3）
export interface PageData {
  pageId: string;
  pageIndex: number;
  paperSize: number;
  paperTemplate: number;
  orientation: number;
  widthMm?: number;
  heightMm?: number;
  background?: PageBackground | null;
  elements: object[];    // NoteElement JSON 数组
}

export function isSupportedPageElementKind(kind: string): boolean {
  return kind === 'stroke' || kind === 'text' || kind === 'shape';
}

interface PageElementEnvelope {
  kind: string;
  data: object;
}

interface LegacyStrokePathPoint {
  pressure?: number;
  altitudeAngleRadians?: number;
  azimuthUnitX?: number;
  azimuthUnitY?: number;
}

// format v1 在笔姿字段加入前已经发布；先补旧版默认值，再执行当前结构校验。
export function parsePageElement(element: object): object | null {
  if (element === null || typeof element !== 'object') {
    return null;
  }
  const envelope = element as PageElementEnvelope;
  if (envelope.kind === 'stroke' && envelope.data !== null && typeof envelope.data === 'object') {
    const stroke = envelope.data as StrokeElementData;
    if (Array.isArray(stroke.pathPoints)) {
      for (const rawPoint of stroke.pathPoints) {
        const point = rawPoint as LegacyStrokePathPoint;
        if (point !== null && typeof point === 'object') {
          if (point.pressure === undefined) {
            point.pressure = -1;
          }
          if (point.altitudeAngleRadians === undefined) {
            point.altitudeAngleRadians = Math.PI / 2;
          }
          if (point.azimuthUnitX === undefined) {
            point.azimuthUnitX = 1;
          }
          if (point.azimuthUnitY === undefined) {
            point.azimuthUnitY = 0;
          }
        }
      }
    }
    if (stroke.customPath === undefined) {
      stroke.customPath = null;
    }
    if (stroke.fillPath === undefined) {
      stroke.fillPath = null;
    }
    if (stroke.fillColor === undefined) {
      stroke.fillColor = null;
    }
    if (stroke.styleMap === undefined) {
      stroke.styleMap = [];
    }
  }
  return isValidPageElement(element) ? element : null;
}

export function isValidPageElement(element: object): boolean {
  if (element === null || typeof element !== 'object') {
    return false;
  }
  const envelope = element as PageElementEnvelope;
  if (!isSupportedPageElementKind(envelope.kind) || envelope.data === null ||
    typeof envelope.data !== 'object') {
    return false;
  }
  if (envelope.kind === 'stroke') {
    return isValidStroke(envelope.data as StrokeElementData);
  }
  if (envelope.kind === 'text') {
    return isValidText(envelope.data as TextBlockElement);
  }
  return isValidShape(envelope.data as ShapeElement);
}

// 序列化 manifest
export function serializeManifest(manifest: NoteManifest): string {
  return JSON.stringify(manifest);
}

// 反序列化 manifest（格式校验：format/version 必须匹配，否则返回 null）
export function parseManifest(json: string): NoteManifest | null {
  try {
    const parsed = JSON.parse(json) as NoteManifest;
    if (parsed === null || typeof parsed !== 'object') {
      return null;
    }
    if (parsed.format !== NOTE_FORMAT || typeof parsed.version !== 'number' ||
      parsed.version > NOTE_FORMAT_VERSION) {
      return null;
    }
    // Keep older package readers explicit so a future format bump does not
    // accidentally invalidate existing backups.
    switch (parsed.version) {
      case 1:
        break;
      default:
        return null;
    }
    if (typeof parsed.title !== 'string' || typeof parsed.noteId !== 'string') {
      return null;
    }
    if (!Number.isSafeInteger(parsed.pageCount) || parsed.pageCount < 0 ||
      parsed.pageCount > NOTE_MAX_PAGE_COUNT) {
      return null;
    }
    return parsed;
  } catch (e) {
    return null;
  }
}

// 序列化页面
export function serializePage(page: PageData): string {
  return JSON.stringify(page);
}

// 反序列化页面（校验 pageId/pageIndex）
export function parsePage(json: string): PageData | null {
  try {
    const parsed = JSON.parse(json) as PageData;
    if (parsed === null || typeof parsed !== 'object') {
      return null;
    }
    if (typeof parsed.pageId !== 'string' || parsed.pageId.length === 0) {
      return null;
    }
    if (!Number.isSafeInteger(parsed.pageIndex) || parsed.pageIndex < 0 ||
      parsed.pageIndex >= NOTE_MAX_PAGE_COUNT) {
      return null;
    }
    if (!isIntegerInRange(parsed.paperSize, 0, 7) ||
      !isIntegerInRange(parsed.paperTemplate, 0, 5) ||
      !isIntegerInRange(parsed.orientation, 0, 1)) {
      return null;
    }
    if (!Array.isArray(parsed.elements)) {
      return null;
    }
    const hasWidth: boolean = parsed.widthMm !== undefined;
    const hasHeight: boolean = parsed.heightMm !== undefined;
    if (hasWidth !== hasHeight || (hasWidth && (!isPositiveFinite(parsed.widthMm as number) ||
      !isPositiveFinite(parsed.heightMm as number)))) {
      return null;
    }
    try {
      validatePageBackground(parsed.background);
      parsed.background = clonePageBackground(parsed.background);
    } catch (_error) {
      return null;
    }
    return parsed;
  } catch (e) {
    return null;
  }
}

function isValidStroke(stroke: StrokeElementData): boolean {
  if (!isElementBase(stroke.id, stroke.transform, stroke.bounds) ||
    !Array.isArray(stroke.pathPoints) || !Array.isArray(stroke.cubicSegments) ||
    !Array.isArray(stroke.splatPoints) || !Array.isArray(stroke.maskPath) ||
    stroke.renderSpec === null || typeof stroke.renderSpec !== 'object' ||
    typeof stroke.isFinished !== 'boolean') {
    return false;
  }
  if (!isFiniteNumber(stroke.renderSpec.color) || !isNonNegativeFinite(stroke.renderSpec.brushWidth) ||
    !isIntegerInRange(stroke.renderSpec.inkStyle, InkStyle.FIXED_WIDTH, InkStyle.DOTS) ||
    typeof stroke.renderSpec.isHighlighter !== 'boolean' || typeof stroke.renderSpec.isPencil !== 'boolean') {
    return false;
  }
  for (const point of stroke.pathPoints) {
    if (!isValidStrokePoint(point)) {
      return false;
    }
  }
  for (const segment of stroke.cubicSegments) {
    if (segment === null || typeof segment !== 'object' ||
      !isPoint(segment.p0) || !isPoint(segment.p1) || !isPoint(segment.p2) || !isPoint(segment.p3)) {
      return false;
    }
  }
  for (const splat of stroke.splatPoints) {
    if (splat === null || typeof splat !== 'object' ||
      !isFiniteNumber(splat.x) || !isFiniteNumber(splat.y) || !isFiniteNumber(splat.rotation) ||
      !isFiniteNumber(splat.scale) || !isFiniteNumber(splat.opacity)) {
      return false;
    }
  }
  for (const maskPoint of stroke.maskPath) {
    if (!isPoint(maskPoint)) {
      return false;
    }
  }
  if (!isValidInkPath(stroke.customPath) || !isValidInkPath(stroke.fillPath) ||
    (stroke.fillColor !== null && stroke.fillColor !== undefined &&
      !isFiniteNumber(stroke.fillColor)) || !isValidInkStyleMap(stroke.styleMap)) {
    return false;
  }
  return true;
}

function isValidInkStyleMap(styleMap: InkStyleMapEntry[] | undefined): boolean {
  if (styleMap === undefined) {
    return true;
  }
  if (!Array.isArray(styleMap) || styleMap.length > 65535) {
    return false;
  }
  for (const entry of styleMap) {
    if (entry === null || typeof entry !== 'object') {
      return false;
    }
    if (!Number.isInteger(entry.backingPencilSeed) || entry.backingPencilSeed < -2147483648 ||
      entry.backingPencilSeed > 2147483647 ||
      !isPoint(entry.backingPencilReferencePoint) ||
      !isFiniteNumber(entry.backingDashPhase) || !isFiniteNumber(entry.backingDashPeriod)) {
      return false;
    }
  }
  return true;
}

function isValidInkPath(path: InkPathCommand[] | null | undefined): boolean {
  if (path === null || path === undefined) {
    return true;
  }
  if (!Array.isArray(path)) {
    return false;
  }
  for (const command of path) {
    if (command === null || typeof command !== 'object' || !Array.isArray(command.points) ||
      !isIntegerInRange(command.type, InkPathCommandType.MOVE_TO, InkPathCommandType.CUBIC)) {
      return false;
    }
    const expected: number = command.type === InkPathCommandType.CUBIC ? 3 :
      command.type === InkPathCommandType.QUADRATIC ? 2 : 1;
    if (command.points.length !== expected) {
      return false;
    }
    for (const point of command.points) {
      if (!isPoint(point)) {
        return false;
      }
    }
  }
  return true;
}

function isValidStrokePoint(point: StrokePathPoint): boolean {
  return point !== null && typeof point === 'object' &&
    isPoint(point.position) && isFiniteNumber(point.widthFactor) &&
    isFiniteNumber(point.pressure) && isFiniteNumber(point.altitudeAngleRadians) &&
    isFiniteNumber(point.azimuthUnitX) && isFiniteNumber(point.azimuthUnitY);
}

function isValidText(text: TextBlockElement): boolean {
  return text.type === ElementType.TEXT && isElementBase(text.id, text.transform, text.bounds) &&
    typeof text.richText === 'string' && isPoint(text.textOrigin) &&
    isNonNegativeFinite(text.blockWidth) && isNonNegativeFinite(text.blockHeight) &&
    isFiniteNumber(text.rotationRadians) && isFiniteNumber(text.contentLeftInset) &&
    isFiniteNumber(text.contentTopInset) && isNonNegativeFinite(text.fontSize) &&
    isFiniteNumber(text.fontColor) && isValidRichTextRuns(text) &&
    (text.corner === undefined || text.corner === 0 || text.corner === 1) &&
    (text.textWrap === undefined || text.textWrap === 0 || text.textWrap === 1) &&
    (text.enableCaption === undefined || typeof text.enableCaption === 'boolean') &&
    isValidOptionalTextPaper(text) &&
    (text.resizesWidthToFitText === undefined || typeof text.resizesWidthToFitText === 'boolean') &&
    (text.positionLocked === undefined || typeof text.positionLocked === 'boolean');
}

function isValidOptionalTextPaper(text: TextBlockElement): boolean {
  if (text.paper === undefined || text.paper === null) {
    return true;
  }
  try {
    validateOriginalPaper(text.paper);
    return true;
  } catch (_error) {
    return false;
  }
}

function isValidRichTextRuns(text: TextBlockElement): boolean {
  let codePointLength: number = 0;
  for (const _character of text.richText) {
    codePointLength++;
  }
  if (text.characterStyleRuns !== undefined) {
    if (!Array.isArray(text.characterStyleRuns) ||
      !isValidStyleRunCollection(text.characterStyleRuns as Object[], codePointLength, false)) {
      return false;
    }
  }
  if (text.paragraphStyleRuns !== undefined) {
    if (!Array.isArray(text.paragraphStyleRuns) ||
      !isValidStyleRunCollection(text.paragraphStyleRuns as Object[], codePointLength, true)) {
      return false;
    }
  }
  return true;
}

function isValidStyleRunCollection(runs: Object[], textLength: number,
  paragraph: boolean): boolean {
  let previousEnd: number = 0;
  for (const raw of runs) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
      return false;
    }
    const run = raw as Record<string, Object>;
    const start: number = run.start as number;
    const end: number = run.end as number;
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < previousEnd ||
      end <= start || end > textLength || run.style === null ||
      typeof run.style !== 'object' || Array.isArray(run.style)) {
      return false;
    }
    if (paragraph ? !isValidParagraphStyle(run.style as Record<string, Object>) :
      !isValidCharacterStyle(run.style as Record<string, Object>)) {
      return false;
    }
    previousEnd = end;
  }
  return true;
}

function isValidCharacterStyle(style: Record<string, Object>): boolean {
  const allowed: string[] = ['bold', 'italic', 'underline', 'highlightColor', 'familyName',
    'fontSize', 'foregroundColor', 'link', 'superscript', 'subscript', 'strikethrough'];
  for (const key of Object.keys(style)) {
    if (!allowed.includes(key)) {
      return false;
    }
    const value: Object = style[key];
    if (key === 'highlightColor' || key === 'foregroundColor') {
      if (!isColorInteger(value as number)) {
        return false;
      }
    } else if (key === 'fontSize') {
      if (!isPositiveFinite(value as number)) {
        return false;
      }
    } else if (key === 'familyName' || key === 'link') {
      if (typeof value !== 'string' || (key === 'familyName' && value.length === 0) ||
        value.length > 65536) {
        return false;
      }
    } else if (typeof value !== 'boolean') {
      return false;
    }
  }
  return style.superscript !== true || style.subscript !== true;
}

function isValidParagraphStyle(style: Record<string, Object>): boolean {
  const allowed: string[] = ['indentLevel', 'alignment', 'lineSpacing', 'decoratorStyle',
    'programmingLanguage', 'writingDirection'];
  for (const key of Object.keys(style)) {
    if (!allowed.includes(key)) {
      return false;
    }
    const value: Object = style[key];
    if (key === 'indentLevel' && !isIntegerInRange(value as number, 0, 7)) {
      return false;
    }
    if (key === 'alignment' && !isIntegerInRange(value as number, 1, 3)) {
      return false;
    }
    if (key === 'decoratorStyle' && !isIntegerInRange(value as number, 0, 5)) {
      return false;
    }
    if (key === 'writingDirection' && !isIntegerInRange(value as number, 0, 1)) {
      return false;
    }
    if (key === 'lineSpacing' && !isOriginalLineSpacing(value as number)) {
      return false;
    }
    if (key === 'programmingLanguage' &&
      (typeof value !== 'string' || value.length > 65536)) {
      return false;
    }
  }
  return true;
}

function isColorInteger(value: number): boolean {
  return Number.isSafeInteger(value) && value >= -2147483648 && value <= 4294967295;
}

function isOriginalLineSpacing(value: number): boolean {
  return isFiniteNumber(value) && (Math.abs(value) < 0.01 || Math.abs(value - 1) < 0.01 ||
    Math.abs(value - 1.5) < 0.01 || Math.abs(value - 2) < 0.01);
}

function isValidShape(shape: ShapeElement): boolean {
  if (!isElementBase(shape.id, shape.transform, shape.bounds) || !isFiniteNumber(shape.color) ||
    !isNonNegativeFinite(shape.strokeWidth) ||
    (shape.fillColor !== null && !isFiniteNumber(shape.fillColor))) {
    return false;
  }
  if (shape.type === ElementType.ELLIPSE) {
    return isPoint(shape.center) && isNonNegativeFinite(shape.radiusX) &&
      isNonNegativeFinite(shape.radiusY) && isFiniteNumber(shape.rotationRadians);
  }
  if (shape.type === ElementType.POLYGON) {
    if (!Array.isArray(shape.vertices) || typeof shape.isClosed !== 'boolean') {
      return false;
    }
    for (const vertex of shape.vertices) {
      if (!isPoint(vertex)) {
        return false;
      }
    }
    return shape.vertices.length >= 2;
  }
  if (shape.type === ElementType.LINE) {
    return isPoint(shape.start) && isNullablePoint(shape.controlPoint1) &&
      isNullablePoint(shape.controlPoint2) && isPoint(shape.end) &&
      isIntegerInRange(shape.arrowHead, ShapeArrowHead.NONE, ShapeArrowHead.SINGLE);
  }
  return false;
}

function isElementBase(id: string, transform: TransformMatrix, bounds: Rect2D): boolean {
  if (typeof id !== 'string' || id.length === 0 || !Array.isArray(transform) || transform.length !== 9 ||
    bounds === null || typeof bounds !== 'object') {
    return false;
  }
  for (const value of transform) {
    if (!isFiniteNumber(value)) {
      return false;
    }
  }
  return isFiniteNumber(bounds.left) && isFiniteNumber(bounds.top) &&
    isFiniteNumber(bounds.right) && isFiniteNumber(bounds.bottom);
}

function isNullablePoint(point: Point2D | null): boolean {
  return point === null || isPoint(point);
}

function isPoint(point: Point2D): boolean {
  return point !== null && typeof point === 'object' &&
    isFiniteNumber(point.x) && isFiniteNumber(point.y);
}

function isNonNegativeFinite(value: number): boolean {
  return isFiniteNumber(value) && value >= 0;
}

function isPositiveFinite(value: number): boolean {
  return isFiniteNumber(value) && value > 0;
}

function isFiniteNumber(value: number): boolean {
  return typeof value === 'number' && Number.isFinite(value);
}

function isIntegerInRange(value: number, minimum: number, maximum: number): boolean {
  return Number.isSafeInteger(value) && value >= minimum && value <= maximum;
}
