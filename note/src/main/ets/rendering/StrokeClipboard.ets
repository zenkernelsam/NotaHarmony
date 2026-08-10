import { CubicSegment, Point2D, Rect2D } from '../core/model/GeometryTypes';
import {
  InkPathCommand, InkStyleMapEntry, PencilSplatPoint, RenderSpec, StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';
import { ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { cloneShapeElement } from '../core/model/ShapeGeometry';
import { cloneTextBlockElement } from '../core/model/TextBlockGeometry';
import {
  materializePageElements, normalizePageElementOrder, OrderedPageElement,
  PageElementKind, PageElementRef,
} from '../core/model/PageElementOrder';

export type StrokeIdFactory = (sourceId: string, pasteSequence: number, index: number) => string;

export interface ClipboardPasteResult {
  strokes: StrokeElementData[];
  shapes: ShapeElement[];
  textBlocks: TextBlockElement[];
  elementOrder: PageElementRef[];
  sourcePageId: string;
  pasteSequence: number;
  offset: Point2D;
}

export function cloneClipboardShape(shape: ShapeElement, id: string = shape.id,
  dx: number = 0, dy: number = 0): ShapeElement {
  const result: ShapeElement = cloneShapeElement(shape);
  result.id = id;
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
  result.transform[2] += dx;
  result.transform[5] += dy;
  result.bounds = {
    left: textBlock.bounds.left + dx, top: textBlock.bounds.top + dy,
    right: textBlock.bounds.right + dx, bottom: textBlock.bounds.bottom + dy,
  };
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
  private elementOrder: PageElementRef[] = [];
  private sourcePageId: string = '';
  private pasteCount: number = 0;

  copy(strokes: StrokeElementData[], sourcePageId: string, shapes: ShapeElement[] = [],
    elementOrder: PageElementRef[] = [], textBlocks: TextBlockElement[] = []): boolean {
    if ((strokes.length === 0 && shapes.length === 0 && textBlocks.length === 0) || sourcePageId.length === 0) {
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
    this.snapshots = copied;
    this.shapeSnapshots = copiedShapes;
    this.textSnapshots = copiedTexts;
    this.elementOrder = normalizePageElementOrder(elementOrder, copied, copiedTexts, copiedShapes);
    this.sourcePageId = sourcePageId;
    this.pasteCount = 0;
    return true;
  }

  hasContent(): boolean {
    return this.snapshots.length > 0 || this.shapeSnapshots.length > 0 || this.textSnapshots.length > 0;
  }

  size(): number {
    return this.snapshots.length + this.shapeSnapshots.length + this.textSnapshots.length;
  }

  clear(): void {
    this.snapshots = [];
    this.shapeSnapshots = [];
    this.textSnapshots = [];
    this.elementOrder = [];
    this.sourcePageId = '';
    this.pasteCount = 0;
  }

  paste(pageWidth: number, pageHeight: number, idFactory: StrokeIdFactory): ClipboardPasteResult | null {
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
    const pastedOrder: PageElementRef[] = [];
    const ordered: OrderedPageElement[] = materializePageElements(
      this.elementOrder, this.snapshots, this.textSnapshots, this.shapeSnapshots);
    for (let i: number = 0; i < ordered.length; i++) {
      const source: OrderedPageElement = ordered[i];
      const id: string = idFactory(source.elementId, sequence, i);
      if (id.length === 0 || ids.has(id)) {
        return null;
      }
      ids.add(id);
      if (source.kind === PageElementKind.STROKE) {
        pasted.push(cloneStrokeElement(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.STROKE, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.SHAPE) {
        pastedShapes.push(cloneClipboardShape(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.SHAPE, elementId: id, zIndex: pastedOrder.length });
      } else if (source.kind === PageElementKind.TEXT) {
        pastedTexts.push(cloneClipboardTextBlock(source.data, id, dx, dy));
        pastedOrder.push({ kind: PageElementKind.TEXT, elementId: id, zIndex: pastedOrder.length });
      }
    }
    this.pasteCount = sequence;
    return {
      strokes: pasted,
      shapes: pastedShapes,
      textBlocks: pastedTexts,
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
