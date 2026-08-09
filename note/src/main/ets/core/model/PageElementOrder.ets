import { StrokeElementData } from './StrokeTypes';
import { ShapeElement, TextBlockElement } from './ElementTypes';

export enum PageElementKind {
  STROKE = 1,
  TEXT = 2,
  SHAPE = 3,
}

export interface PageElementRef {
  kind: PageElementKind;
  elementId: string;
  zIndex: number;
}

export interface OrderedStrokeElement extends PageElementRef {
  kind: PageElementKind.STROKE;
  data: StrokeElementData;
}

export interface OrderedTextElement extends PageElementRef {
  kind: PageElementKind.TEXT;
  data: TextBlockElement;
}

export interface OrderedShapeElement extends PageElementRef {
  kind: PageElementKind.SHAPE;
  data: ShapeElement;
}

export type OrderedPageElement = OrderedStrokeElement | OrderedTextElement | OrderedShapeElement;

export function legacyPageElementOrder(strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = []): PageElementRef[] {
  const result: PageElementRef[] = [];
  for (const stroke of strokes) {
    result.push({ kind: PageElementKind.STROKE, elementId: stroke.id, zIndex: result.length });
  }
  for (const text of textBlocks) {
    result.push({ kind: PageElementKind.TEXT, elementId: text.id, zIndex: result.length });
  }
  for (const shape of shapes) {
    result.push({ kind: PageElementKind.SHAPE, elementId: shape.id, zIndex: result.length });
  }
  return result;
}

export function normalizePageElementOrder(order: PageElementRef[], strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = []): PageElementRef[] {
  const strokeIds: Set<string> = new Set<string>();
  const textIds: Set<string> = new Set<string>();
  const shapeIds: Set<string> = new Set<string>();
  for (const stroke of strokes) {
    strokeIds.add(stroke.id);
  }
  for (const text of textBlocks) {
    textIds.add(text.id);
  }
  for (const shape of shapes) {
    shapeIds.add(shape.id);
  }
  const seen: Set<string> = new Set<string>();
  const result: PageElementRef[] = [];
  for (const ref of order) {
    const valid: boolean = ref.kind === PageElementKind.STROKE
      ? strokeIds.has(ref.elementId) : ref.kind === PageElementKind.TEXT
        ? textIds.has(ref.elementId) : ref.kind === PageElementKind.SHAPE && shapeIds.has(ref.elementId);
    const key: string = pageElementKey(ref.kind, ref.elementId);
    if (valid && ref.elementId.length > 0 && !seen.has(key)) {
      seen.add(key);
      result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
    }
  }
  const legacy: PageElementRef[] = legacyPageElementOrder(strokes, textBlocks, shapes);
  for (const ref of legacy) {
    const key: string = pageElementKey(ref.kind, ref.elementId);
    if (!seen.has(key)) {
      seen.add(key);
      result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
    }
  }
  return result;
}

export function materializePageElements(order: PageElementRef[], strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = []): OrderedPageElement[] {
  const normalized: PageElementRef[] = normalizePageElementOrder(order, strokes, textBlocks, shapes);
  const strokesById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
  const textsById: Map<string, TextBlockElement> = new Map<string, TextBlockElement>();
  const shapesById: Map<string, ShapeElement> = new Map<string, ShapeElement>();
  for (const stroke of strokes) {
    strokesById.set(stroke.id, stroke);
  }
  for (const text of textBlocks) {
    textsById.set(text.id, text);
  }
  for (const shape of shapes) {
    shapesById.set(shape.id, shape);
  }
  const result: OrderedPageElement[] = [];
  for (const ref of normalized) {
    if (ref.kind === PageElementKind.STROKE) {
      const stroke: StrokeElementData | undefined = strokesById.get(ref.elementId);
      if (stroke !== undefined) {
        result.push({ kind: PageElementKind.STROKE, elementId: ref.elementId, zIndex: ref.zIndex, data: stroke });
      }
    } else if (ref.kind === PageElementKind.TEXT) {
      const text: TextBlockElement | undefined = textsById.get(ref.elementId);
      if (text !== undefined) {
        result.push({ kind: PageElementKind.TEXT, elementId: ref.elementId, zIndex: ref.zIndex, data: text });
      }
    } else {
      const shape: ShapeElement | undefined = shapesById.get(ref.elementId);
      if (shape !== undefined) {
        result.push({ kind: PageElementKind.SHAPE, elementId: ref.elementId, zIndex: ref.zIndex, data: shape });
      }
    }
  }
  return result;
}

export function appendPageElementRefs(order: PageElementRef[], kind: PageElementKind,
  elementIds: string[]): PageElementRef[] {
  const result: PageElementRef[] = clonePageElementOrder(order);
  const seen: Set<string> = new Set<string>();
  for (const ref of result) {
    seen.add(pageElementKey(ref.kind, ref.elementId));
  }
  for (const id of elementIds) {
    const key: string = pageElementKey(kind, id);
    if (id.length > 0 && !seen.has(key)) {
      seen.add(key);
      result.push({ kind: kind, elementId: id, zIndex: result.length });
    }
  }
  return reindexPageElementOrder(result);
}

export function removePageElementRefs(order: PageElementRef[], kind: PageElementKind,
  elementIds: string[]): PageElementRef[] {
  const removed: Set<string> = new Set<string>(elementIds);
  const result: PageElementRef[] = [];
  for (const ref of order) {
    if (ref.kind !== kind || !removed.has(ref.elementId)) {
      result.push(ref);
    }
  }
  return reindexPageElementOrder(result);
}

export function moveStrokeRefs(order: PageElementRef[], strokeIds: string[], forward: boolean): PageElementRef[] {
  const selectedIds: Set<string> = new Set<string>(strokeIds);
  const selected: PageElementRef[] = [];
  const remaining: PageElementRef[] = [];
  for (const ref of order) {
    if (ref.kind === PageElementKind.STROKE && selectedIds.has(ref.elementId)) {
      selected.push(ref);
    } else {
      remaining.push(ref);
    }
  }
  return reindexPageElementOrder(forward ? remaining.concat(selected) : selected.concat(remaining));
}

export function movePageElementRefs(order: PageElementRef[], strokeIds: string[], shapeIds: string[],
  forward: boolean, textIds: string[] = []): PageElementRef[] {
  const selectedStrokes: Set<string> = new Set<string>(strokeIds);
  const selectedShapes: Set<string> = new Set<string>(shapeIds);
  const selectedTexts: Set<string> = new Set<string>(textIds);
  const selected: PageElementRef[] = [];
  const remaining: PageElementRef[] = [];
  for (const ref of order) {
    const isSelected: boolean = ref.kind === PageElementKind.STROKE
      ? selectedStrokes.has(ref.elementId) : ref.kind === PageElementKind.SHAPE
        ? selectedShapes.has(ref.elementId) : ref.kind === PageElementKind.TEXT && selectedTexts.has(ref.elementId);
    if (isSelected) {
      selected.push(ref);
    } else {
      remaining.push(ref);
    }
  }
  return reindexPageElementOrder(forward ? remaining.concat(selected) : selected.concat(remaining));
}

export function clonePageElementOrder(order: PageElementRef[]): PageElementRef[] {
  const result: PageElementRef[] = [];
  for (const ref of order) {
    result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
  }
  return result;
}

export function samePageElementOrder(a: PageElementRef[], b: PageElementRef[]): boolean {
  if (a.length !== b.length) {
    return false;
  }
  for (let i: number = 0; i < a.length; i++) {
    if (a[i].kind !== b[i].kind || a[i].elementId !== b[i].elementId || a[i].zIndex !== i || b[i].zIndex !== i) {
      return false;
    }
  }
  return true;
}

export function samePageElementMembers(a: PageElementRef[], b: PageElementRef[]): boolean {
  if (a.length !== b.length) {
    return false;
  }
  const keys: Set<string> = new Set<string>();
  for (const ref of a) {
    const key: string = pageElementKey(ref.kind, ref.elementId);
    if (keys.has(key)) {
      return false;
    }
    keys.add(key);
  }
  const compared: Set<string> = new Set<string>();
  for (const ref of b) {
    const key: string = pageElementKey(ref.kind, ref.elementId);
    if (!keys.has(key) || compared.has(key)) {
      return false;
    }
    compared.add(key);
  }
  return true;
}

export function hasStrokeAboveText(order: PageElementRef[]): boolean {
  let sawText: boolean = false;
  for (const ref of order) {
    if (ref.kind === PageElementKind.TEXT) {
      sawText = true;
    } else if (sawText) {
      return true;
    }
  }
  return false;
}

export function requiresUnifiedElementRender(order: PageElementRef[]): boolean {
  let sawNonStroke: boolean = false;
  for (const ref of order) {
    if (ref.kind !== PageElementKind.STROKE) {
      sawNonStroke = true;
    } else if (sawNonStroke) {
      return true;
    }
    if (ref.kind === PageElementKind.SHAPE) {
      return true;
    }
  }
  return false;
}

export function pageElementKey(kind: PageElementKind, elementId: string): string {
  return `${kind}:${elementId}`;
}

function reindexPageElementOrder(order: PageElementRef[]): PageElementRef[] {
  const result: PageElementRef[] = [];
  for (const ref of order) {
    result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
  }
  return result;
}
