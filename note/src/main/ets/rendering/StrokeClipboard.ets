import { CubicSegment, Point2D, Rect2D } from '../core/model/GeometryTypes';
import {
  InkPathCommand, InkStyleMapEntry, PencilSplatPoint, RenderSpec, StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';
import {
  EllipseElement, ElementType, ImageElement, LineElement, MathElement, PolygonElement,
  ShapeElement, TextBlockElement,
} from '../core/model/ElementTypes';
import { cloneShapeElement } from '../core/model/ShapeGeometry';
import { cloneTextBlockElement } from '../core/model/TextBlockGeometry';
import { cloneImageElement, imageBlockWorldBounds } from '../core/model/ImageBlockGeometry';
import { cloneMathElement, mathBlockWorldBounds } from '../core/model/MathBlockGeometry';
import {
  materializePageElements, normalizePageElementOrder, OrderedPageElement,
  PageElementKind, PageElementRef,
} from '../core/model/PageElementOrder';
import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';

export type StrokeIdFactory = (sourceId: string, pasteSequence: number, index: number) => string;

export interface ClipboardSingleOriginalSource {
  kind: PageElementKind;
  elementId: string;
  stroke?: StrokeElementData;
  shape?: ShapeElement;
  textBlock?: TextBlockElement;
}

export interface ClipboardPasteResult {
  strokes: StrokeElementData[];
  shapes: ShapeElement[];
  textBlocks: TextBlockElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
  sourcePageId: string;
  pasteSequence: number;
  offset: Point2D;
}

export interface ClipboardOriginalGroupPastePreview {
  paste: ClipboardPasteResult;
  groups: OriginalSelectionGroup[];
  topGroupIds: string[];
}

interface ClipboardOriginalGroupGraph {
  groups: OriginalSelectionGroup[];
  topGroupIds: string[];
}

export function cloneClipboardShape(shape: ShapeElement, id: string = shape.id,
  dx: number = 0, dy: number = 0): ShapeElement {
  const result: ShapeElement = cloneShapeElement(shape);
  result.id = id;
  result.originalCreate = undefined;
  result.transform[2] += dx;
  result.transform[5] += dy;
  result.bounds = {
    left: shape.bounds.left + dx, top: shape.bounds.top + dy,
    right: shape.bounds.right + dx, bottom: shape.bounds.bottom + dy,
  };
  return result;
}

export function cloneClipboardTextBlock(textBlock: TextBlockElement, id: string = textBlock.id,
  dx: number = 0, dy: number = 0): TextBlockElement {
  const result: TextBlockElement = cloneTextBlockElement(textBlock);
  result.id = id;
  result.originalCreate = undefined;
  result.transform[2] += dx;
  result.transform[5] += dy;
  result.bounds = {
    left: textBlock.bounds.left + dx, top: textBlock.bounds.top + dy,
    right: textBlock.bounds.right + dx, bottom: textBlock.bounds.bottom + dy,
  };
  return result;
}

export function cloneClipboardImage(image: ImageElement, id: string = image.id,
  dx: number = 0, dy: number = 0): ImageElement {
  const result: ImageElement = cloneImageElement(image);
  result.id = id;
  result.transform[2] += dx;
  result.transform[5] += dy;
  result.bounds = imageBlockWorldBounds(result);
  return result;
}

export function cloneClipboardMath(math: MathElement, id: string = math.id,
  dx: number = 0, dy: number = 0): MathElement {
  const result: MathElement = cloneMathElement(math);
  result.id = id;
  result.transform[2] += dx;
  result.transform[5] += dy;
  result.bounds = mathBlockWorldBounds(result);
  return result;
}

const PASTE_STEP: number = 20;
const PAGE_MARGIN: number = 8;

export function cloneStrokeElement(stroke: StrokeElementData, id: string = stroke.id,
  dx: number = 0, dy: number = 0): StrokeElementData {
  const transform: number[] = stroke.transform.slice();
  transform[2] += dx;
  transform[5] += dy;
  const pathPoints: StrokePathPoint[] = stroke.pathPoints.map(
    (point: StrokePathPoint): StrokePathPoint => ({
      position: { x: point.position.x, y: point.position.y },
      widthFactor: point.widthFactor,
      pressure: point.pressure,
      altitudeAngleRadians: point.altitudeAngleRadians,
      azimuthUnitX: point.azimuthUnitX,
      azimuthUnitY: point.azimuthUnitY,
    }));
  const cubicSegments: CubicSegment[] = stroke.cubicSegments.map(
    (segment: CubicSegment): CubicSegment => ({
      p0: { x: segment.p0.x, y: segment.p0.y },
      p1: { x: segment.p1.x, y: segment.p1.y },
      p2: { x: segment.p2.x, y: segment.p2.y },
      p3: { x: segment.p3.x, y: segment.p3.y },
    }));
  const splatPoints: PencilSplatPoint[] = stroke.splatPoints.map(
    (splat: PencilSplatPoint): PencilSplatPoint => ({
      x: splat.x,
      y: splat.y,
      rotation: splat.rotation,
      scale: splat.scale,
      opacity: splat.opacity,
    }));
  const renderSpec: RenderSpec = {
    color: stroke.renderSpec.color,
    brushWidth: stroke.renderSpec.brushWidth,
    inkStyle: stroke.renderSpec.inkStyle,
    isHighlighter: stroke.renderSpec.isHighlighter,
    isPencil: stroke.renderSpec.isPencil,
    isPartialEraser: stroke.renderSpec.isPartialEraser,
    inkEffects: stroke.renderSpec.inkEffects,
    inkEffectsTinted: stroke.renderSpec.inkEffectsTinted,
    inkEffectPhase: stroke.renderSpec.inkEffectPhase,
    tapePattern: stroke.renderSpec.tapePattern,
  };
  return {
    id: id,
    pathPoints: pathPoints,
    cubicSegments: cubicSegments,
    splatPoints: splatPoints,
    renderSpec: renderSpec,
    transform: transform,
    bounds: {
      left: stroke.bounds.left + dx,
      top: stroke.bounds.top + dy,
      right: stroke.bounds.right + dx,
      bottom: stroke.bounds.bottom + dy,
    },
    maskPath: stroke.maskPath.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
    customPath: cloneInkPath(stroke.customPath),
    fillPath: cloneInkPath(stroke.fillPath),
    fillColor: stroke.fillColor === undefined ? null : stroke.fillColor,
    styleMap: stroke.styleMap === undefined ? [] :
      stroke.styleMap.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
        backingPencilSeed: entry.backingPencilSeed,
        backingPencilReferencePoint: {
          x: entry.backingPencilReferencePoint.x, y: entry.backingPencilReferencePoint.y,
        },
        backingDashPhase: entry.backingDashPhase,
        backingDashPeriod: entry.backingDashPeriod,
      })),
    audioStartTime: stroke.audioStartTime,
    audioDuration: stroke.audioDuration,
    originalCreate: undefined,
    isFinished: stroke.isFinished,
  };
}

function cloneInkPath(path: InkPathCommand[] | null | undefined): InkPathCommand[] | null {
  if (path === null || path === undefined) {
    return null;
  }
  return path.map((command: InkPathCommand): InkPathCommand => ({
    type: command.type,
    points: command.points.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
  }));
}

export class StrokeClipboard {
  private snapshots: StrokeElementData[] = [];
  private shapeSnapshots: ShapeElement[] = [];
  private textSnapshots: TextBlockElement[] = [];
  private imageSnapshots: ImageElement[] = [];
  private mathSnapshots: MathElement[] = [];
  private elementOrder: PageElementRef[] = [];
  private sourcePageId: string = '';
  private pasteCount: number = 0;
  private groupSnapshots: OriginalSelectionGroup[] = [];
  private topGroupIds: string[] = [];

  copy(strokes: StrokeElementData[], sourcePageId: string, shapes: ShapeElement[] = [],
    elementOrder: PageElementRef[] = [], textBlocks: TextBlockElement[] = [],
    images: ImageElement[] = [], mathBlocks: MathElement[] = [],
    sourceGroups: OriginalSelectionGroup[] = [], topGroupIds: string[] = []): boolean {
    if ((strokes.length === 0 && shapes.length === 0 && textBlocks.length === 0 &&
      images.length === 0 && mathBlocks.length === 0) ||
      sourcePageId.length === 0) {
      return false;
    }
    const ids: Set<string> = new Set<string>();
    const copied: StrokeElementData[] = [];
    for (const stroke of strokes) {
      if (stroke.id.length === 0 || ids.has(stroke.id)) {
        return false;
      }
      ids.add(stroke.id);
      copied.push(cloneStrokeElement(stroke));
    }
    const copiedShapes: ShapeElement[] = [];
    for (const shape of shapes) {
      if (shape.id.length === 0 || ids.has(shape.id)) {
        return false;
      }
      ids.add(shape.id);
      copiedShapes.push(cloneClipboardShape(shape));
    }
    const copiedTexts: TextBlockElement[] = [];
    for (const textBlock of textBlocks) {
      if (textBlock.id.length === 0 || ids.has(textBlock.id)) {
        return false;
      }
      ids.add(textBlock.id);
      copiedTexts.push(cloneClipboardTextBlock(textBlock));
    }
    const copiedImages: ImageElement[] = [];
    for (const image of images) {
      if (image.id.length === 0 || ids.has(image.id)) {
        return false;
      }
      ids.add(image.id);
      copiedImages.push(cloneClipboardImage(image));
    }
    const copiedMath: MathElement[] = [];
    for (const math of mathBlocks) {
      if (math.id.length === 0 || ids.has(math.id)) {
        return false;
      }
      ids.add(math.id);
      copiedMath.push(cloneClipboardMath(math));
    }
    const groupGraph: ClipboardOriginalGroupGraph | null = copyOriginalGroupGraph(
      sourceGroups, topGroupIds, ids);
    if (groupGraph === null) {
      return false;
    }
    this.snapshots = copied;
    this.shapeSnapshots = copiedShapes;
    this.textSnapshots = copiedTexts;
    this.imageSnapshots = copiedImages;
    this.mathSnapshots = copiedMath;
    this.elementOrder = normalizePageElementOrder(
      elementOrder, copied, copiedTexts, copiedShapes, copiedImages, copiedMath);
    this.sourcePageId = sourcePageId;
    this.pasteCount = 0;
    this.groupSnapshots = groupGraph.groups;
    this.topGroupIds = groupGraph.topGroupIds;
    return true;
  }

  hasContent(): boolean {
    return this.snapshots.length > 0 || this.shapeSnapshots.length > 0 || this.textSnapshots.length > 0 ||
      this.imageSnapshots.length > 0 || this.mathSnapshots.length > 0;
  }

  size(): number {
    return this.snapshots.length + this.shapeSnapshots.length + this.textSnapshots.length +
      this.imageSnapshots.length + this.mathSnapshots.length;
  }

  singleOriginalCreateSource(): ClipboardSingleOriginalSource | null {
    if (this.groupSnapshots.length > 0 || this.size() !== 1 ||
      this.imageSnapshots.length > 0 || this.mathSnapshots.length > 0) {
      return null;
    }
    if (this.snapshots.length === 1) {
      return {
        kind: PageElementKind.STROKE, elementId: this.snapshots[0].id,
        stroke: cloneStrokeElement(this.snapshots[0]),
      };
    }
    if (this.shapeSnapshots.length === 1) {
      const shape: ShapeElement = this.shapeSnapshots[0];
      if ((shape.richText ?? '').length > 0 || (shape.characterStyleRuns ?? []).length > 0 ||
        (shape.paragraphStyleRuns ?? []).length > 0) {
        return null;
      }
      return {
        kind: PageElementKind.SHAPE, elementId: shape.id,
        shape: cloneClipboardShape(shape),
      };
    }
    if (this.textSnapshots.length === 1) {
      const text: TextBlockElement = this.textSnapshots[0];
      if (text.richText.length === 0 || (text.characterStyleRuns ?? []).length > 0 ||
        (text.paragraphStyleRuns ?? []).length > 0) {
        return null;
      }
      return {
        kind: PageElementKind.TEXT, elementId: text.id,
        textBlock: cloneClipboardTextBlock(text),
      };
    }
    return null;
  }

  clear(): void {
    this.snapshots = [];
    this.shapeSnapshots = [];
    this.textSnapshots = [];
    this.imageSnapshots = [];
    this.mathSnapshots = [];
    this.elementOrder = [];
    this.sourcePageId = '';
    this.pasteCount = 0;
    this.groupSnapshots = [];
    this.topGroupIds = [];
  }

  paste(pageWidth: number, pageHeight: number, idFactory: StrokeIdFactory,
    originalCreateKind: PageElementKind | null = null): ClipboardPasteResult | null {
    const result: ClipboardPasteResult | null = this.buildPaste(
      pageWidth, pageHeight, idFactory, originalCreateKind, false);
    if (result === null || !this.commitPreparedPaste(result.pasteSequence)) {
      return null;
    }
    return result;
  }

  hasOriginalGroupGraph(): boolean {
    return this.groupSnapshots.length > 0 && this.topGroupIds.length > 0;
  }

  prepareOriginalGroupPaste(pageWidth: number,
    pageHeight: number): ClipboardOriginalGroupPastePreview | null {
    if (!this.hasOriginalGroupGraph()) {
      return null;
    }
    const paste: ClipboardPasteResult | null = this.buildPaste(
      pageWidth, pageHeight,
      (sourceId: string, _pasteSequence: number, _index: number): string => sourceId,
      null, true);
    if (paste === null) {
      return null;
    }
    return {
      paste: paste,
      groups: this.groupSnapshots.map(cloneSelectionGroup),
      topGroupIds: this.topGroupIds.slice(),
    };
  }

  commitPreparedPaste(pasteSequence: number): boolean {
    if (!Number.isSafeInteger(pasteSequence) || pasteSequence !== this.pasteCount + 1) {
      return false;
    }
    this.pasteCount = pasteSequence;
    return true;
  }

  private buildPaste(pageWidth: number, pageHeight: number, idFactory: StrokeIdFactory,
    originalCreateKind: PageElementKind | null,
    materializeAllOriginal: boolean): ClipboardPasteResult | null {
    if (!this.hasContent() || !Number.isFinite(pageWidth) || !Number.isFinite(pageHeight) ||
      pageWidth <= PAGE_MARGIN * 2 || pageHeight <= PAGE_MARGIN * 2) {
      return null;
    }
    const sequence: number = this.pasteCount + 1;
    const bounds: Rect2D = this.unionBounds();
    const desired: number = PASTE_STEP * sequence;
    const dx: number = this.visibleDelta(bounds.left, bounds.right, pageWidth, desired);
    const dy: number = this.visibleDelta(bounds.top, bounds.bottom, pageHeight, desired);
    const ids: Set<string> = new Set<string>();
    const pasted: StrokeElementData[] = [];
    const pastedShapes: ShapeElement[] = [];
    const pastedTexts: TextBlockElement[] = [];
    const pastedImages: ImageElement[] = [];
    const pastedMath: MathElement[] = [];
    const pastedOrder: PageElementRef[] = [];
    const orderedWithMath: OrderedPageElement[] = materializePageElements(
      this.elementOrder, this.snapshots, this.textSnapshots, this.shapeSnapshots,
      this.imageSnapshots, this.mathSnapshots);
    for (let i: number = 0; i < orderedWithMath.length; i++) {
      const source: OrderedPageElement = orderedWithMath[i];
      const id: string = idFactory(source.elementId, sequence, i);
      if (id.length === 0 || ids.has(id)) {
        return null;
      }
      ids.add(id);
      if (source.kind === PageElementKind.STROKE) {
        const stroke: StrokeElementData = cloneStrokeElement(source.data, id, dx, dy);
        pasted.push(materializeAllOriginal || originalCreateKind === PageElementKind.STROKE ?
          materializeOriginalStrokeTransform(stroke) : stroke);
        pastedOrder.push({ kind: PageElementKind.STROKE, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.SHAPE) {
        const shape: ShapeElement = cloneClipboardShape(source.data, id, dx, dy);
        pastedShapes.push(materializeAllOriginal || originalCreateKind === PageElementKind.SHAPE ?
          materializeOriginalShapeTransform(shape) : shape);
        pastedOrder.push({ kind: PageElementKind.SHAPE, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.TEXT) {
        pastedTexts.push(cloneClipboardTextBlock(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.TEXT, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.IMAGE) {
        pastedImages.push(cloneClipboardImage(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.IMAGE, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.MATH) {
        pastedMath.push(cloneClipboardMath(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.MATH, elementId: id, zIndex: pastedOrder.length });
      }
    }
    return {
      strokes: pasted,
      shapes: pastedShapes,
      textBlocks: pastedTexts,
      images: pastedImages,
      mathBlocks: pastedMath,
      elementOrder: pastedOrder,
      sourcePageId: this.sourcePageId,
      pasteSequence: sequence,
      offset: { x: dx, y: dy },
    };
  }

  private unionBounds(): Rect2D {
    let bounds: Rect2D = {
      left: Number.MAX_VALUE, top: Number.MAX_VALUE,
      right: -Number.MAX_VALUE, bottom: -Number.MAX_VALUE,
    };
    const allBounds: Rect2D[] = [];
    for (const stroke of this.snapshots) {
      allBounds.push(stroke.bounds);
    }
    for (const shape of this.shapeSnapshots) {
      allBounds.push(shape.bounds);
    }
    for (const textBlock of this.textSnapshots) {
      allBounds.push(textBlock.bounds);
    }
    for (const image of this.imageSnapshots) {
      allBounds.push(image.bounds);
    }
    for (const math of this.mathSnapshots) {
      allBounds.push(math.bounds);
    }
    for (const strokeBounds of allBounds) {
      bounds = {
        left: Math.min(bounds.left, strokeBounds.left),
        top: Math.min(bounds.top, strokeBounds.top),
        right: Math.max(bounds.right, strokeBounds.right),
        bottom: Math.max(bounds.bottom, strokeBounds.bottom),
      };
    }
    return bounds;
  }

  private visibleDelta(start: number, end: number, pageExtent: number, desired: number): number {
    const available: number = pageExtent - PAGE_MARGIN * 2;
    if (end - start <= available) {
      return Math.max(PAGE_MARGIN - start, Math.min(desired, pageExtent - PAGE_MARGIN - end));
    }
    return PAGE_MARGIN - start;
  }
}

function copyOriginalGroupGraph(sourceGroups: OriginalSelectionGroup[], topGroupIds: string[],
  copiedLeafIds: Set<string>): ClipboardOriginalGroupGraph | null {
  if (topGroupIds.length === 0) {
    return { groups: [], topGroupIds: [] };
  }
  const byId: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
  for (const group of sourceGroups) {
    if (group.id.length === 0 || group.members.length === 0 || byId.has(group.id)) {
      return null;
    }
    byId.set(group.id, group);
  }
  const ordered: OriginalSelectionGroup[] = [];
  const visiting: Set<string> = new Set<string>();
  const visited: Set<string> = new Set<string>();
  const parentByMember: Map<string, string> = new Map<string, string>();
  const visit = (groupId: string): boolean => {
    if (visiting.has(groupId)) {
      return false;
    }
    if (visited.has(groupId)) {
      return true;
    }
    const group: OriginalSelectionGroup | undefined = byId.get(groupId);
    if (group === undefined) {
      return false;
    }
    visiting.add(groupId);
    const members: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (members.has(member)) {
        return false;
      }
      members.add(member);
      const parent: string | undefined = parentByMember.get(member);
      if (parent !== undefined && parent !== group.id) {
        return false;
      }
      parentByMember.set(member, group.id);
      if (byId.has(member)) {
        if (!visit(member)) {
          return false;
        }
      } else if (!copiedLeafIds.has(member)) {
        return false;
      }
    }
    visiting.delete(groupId);
    visited.add(groupId);
    ordered.push(cloneSelectionGroup(group));
    return true;
  };
  const roots: Set<string> = new Set<string>();
  for (const groupId of topGroupIds) {
    if (roots.has(groupId) || !visit(groupId)) {
      return null;
    }
    roots.add(groupId);
  }
  return { groups: ordered, topGroupIds: topGroupIds.slice() };
}

function cloneSelectionGroup(group: OriginalSelectionGroup): OriginalSelectionGroup {
  return {
    id: group.id, timestamp: group.timestamp, siteId: group.siteId,
    members: group.members.slice(),
  };
}

function materializeOriginalStrokeTransform(stroke: StrokeElementData): StrokeElementData {
  const transform: number[] = stroke.transform.slice();
  const scale: number = originalMaterializationScale(transform);
  for (const point of stroke.pathPoints) {
    transformPointInPlace(point.position, transform);
    const azimuthX: number = point.azimuthUnitX;
    const azimuthY: number = point.azimuthUnitY;
    point.azimuthUnitX = (transform[0] * azimuthX + transform[1] * azimuthY) / scale;
    point.azimuthUnitY = (transform[3] * azimuthX + transform[4] * azimuthY) / scale;
  }
  for (const segment of stroke.cubicSegments) {
    transformPointInPlace(segment.p0, transform);
    transformPointInPlace(segment.p1, transform);
    transformPointInPlace(segment.p2, transform);
    transformPointInPlace(segment.p3, transform);
  }
  for (const splat of stroke.splatPoints) {
    const point: Point2D = { x: splat.x, y: splat.y };
    transformPointInPlace(point, transform);
    splat.x = point.x;
    splat.y = point.y;
    const rotationX: number = Math.cos(splat.rotation);
    const rotationY: number = Math.sin(splat.rotation);
    splat.rotation = Math.atan2(
      transform[3] * rotationX + transform[4] * rotationY,
      transform[0] * rotationX + transform[1] * rotationY);
    splat.scale *= scale;
  }
  for (const point of stroke.maskPath) {
    transformPointInPlace(point, transform);
  }
  transformInkPath(stroke.customPath, transform);
  transformInkPath(stroke.fillPath, transform);
  if (stroke.styleMap !== undefined) {
    for (const entry of stroke.styleMap) {
      transformPointInPlace(entry.backingPencilReferencePoint, transform);
      entry.backingDashPeriod *= scale;
    }
  }
  stroke.renderSpec.brushWidth *= scale;
  stroke.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  return stroke;
}

function materializeOriginalShapeTransform(shape: ShapeElement): ShapeElement {
  const transform: number[] = shape.transform.slice();
  const scale: number = originalMaterializationScale(transform);
  if (shape.type === ElementType.ELLIPSE) {
    const ellipse: EllipseElement = shape as EllipseElement;
    const axisX: number = Math.cos(ellipse.rotationRadians);
    const axisY: number = Math.sin(ellipse.rotationRadians);
    const transformedAxisX: number = transform[0] * axisX + transform[1] * axisY;
    const transformedAxisY: number = transform[3] * axisX + transform[4] * axisY;
    transformPointInPlace(ellipse.center, transform);
    ellipse.radiusX *= scale;
    ellipse.radiusY *= scale;
    ellipse.rotationRadians = Math.atan2(transformedAxisY, transformedAxisX);
  } else if (shape.type === ElementType.LINE) {
    const line: LineElement = shape as LineElement;
    transformPointInPlace(line.start, transform);
    if (line.controlPoint1 !== null) {
      transformPointInPlace(line.controlPoint1, transform);
    }
    if (line.controlPoint2 !== null) {
      transformPointInPlace(line.controlPoint2, transform);
    }
    transformPointInPlace(line.end, transform);
  } else {
    for (const point of (shape as PolygonElement).vertices) {
      transformPointInPlace(point, transform);
    }
  }
  shape.strokeWidth *= scale;
  shape.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  return shape;
}

function transformInkPath(path: InkPathCommand[] | null | undefined,
  transform: number[]): void {
  if (path === null || path === undefined) {
    return;
  }
  for (const command of path) {
    for (const point of command.points) {
      transformPointInPlace(point, transform);
    }
  }
}

function originalMaterializationScale(transform: number[]): number {
  if (transform.length !== 9 || !transform.every((value: number): boolean => Number.isFinite(value)) ||
    Math.abs(transform[6]) > 0.000001 || Math.abs(transform[7]) > 0.000001 ||
    Math.abs(transform[8] - 1) > 0.000001) {
    throw new Error('original clipboard Paste transform is not affine');
  }
  const scaleX: number = Math.hypot(transform[0], transform[3]);
  const scaleY: number = Math.hypot(transform[1], transform[4]);
  const dot: number = transform[0] * transform[1] + transform[3] * transform[4];
  const tolerance: number = Math.max(1, scaleX, scaleY) * 0.000001;
  if (scaleX <= 0.000001 || Math.abs(scaleX - scaleY) > tolerance ||
    Math.abs(dot) > tolerance) {
    throw new Error('original clipboard Paste transform cannot be materialized exactly');
  }
  return scaleX;
}

function transformPointInPlace(point: Point2D, transform: number[]): void {
  const x: number = point.x;
  const y: number = point.y;
  point.x = transform[0] * x + transform[1] * y + transform[2];
  point.y = transform[3] * x + transform[4] * y + transform[5];
}
