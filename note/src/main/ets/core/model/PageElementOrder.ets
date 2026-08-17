import { StrokeElementData } from './StrokeTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from './ElementTypes';
import {
  OriginalSelectionGroup, OriginalSelectionLayerUnit, resolveOriginalSelectionLayerUnits,
} from './OriginalGroupSelection';

export enum PageElementKind {
  STROKE = 1,
  TEXT = 2,
  SHAPE = 3,
  IMAGE = 4,
  MATH = 5,
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

export interface OrderedImageElement extends PageElementRef {
  kind: PageElementKind.IMAGE;
  data: ImageElement;
}

export interface OrderedMathElement extends PageElementRef {
  kind: PageElementKind.MATH;
  data: MathElement;
}

export type OrderedPageElement = OrderedStrokeElement | OrderedTextElement | OrderedShapeElement |
  OrderedImageElement | OrderedMathElement;

export function legacyPageElementOrder(strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = [], images: ImageElement[] = [],
  mathBlocks: MathElement[] = []): PageElementRef[] {
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
  for (const image of images) {
    result.push({ kind: PageElementKind.IMAGE, elementId: image.id, zIndex: result.length });
  }
  for (const math of mathBlocks) {
    result.push({ kind: PageElementKind.MATH, elementId: math.id, zIndex: result.length });
  }
  return result;
}

export function normalizePageElementOrder(order: PageElementRef[], strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = [], images: ImageElement[] = [],
  mathBlocks: MathElement[] = []): PageElementRef[] {
  const strokeIds: Set<string> = new Set<string>();
  const textIds: Set<string> = new Set<string>();
  const shapeIds: Set<string> = new Set<string>();
  const imageIds: Set<string> = new Set<string>();
  const mathIds: Set<string> = new Set<string>();
  for (const stroke of strokes) {
    strokeIds.add(stroke.id);
  }
  for (const text of textBlocks) {
    textIds.add(text.id);
  }
  for (const shape of shapes) {
    shapeIds.add(shape.id);
  }
  for (const image of images) {
    imageIds.add(image.id);
  }
  for (const math of mathBlocks) {
    mathIds.add(math.id);
  }
  // Original page entities share one stable getId() namespace.  Kind is a
  // payload discriminator, not a second identity component.
  const seen: Set<string> = new Set<string>();
  const result: PageElementRef[] = [];
  for (const ref of order) {
    const valid: boolean = ref.kind === PageElementKind.STROKE
      ? strokeIds.has(ref.elementId) : ref.kind === PageElementKind.TEXT
        ? textIds.has(ref.elementId) : ref.kind === PageElementKind.SHAPE
          ? shapeIds.has(ref.elementId) : ref.kind === PageElementKind.IMAGE
            ? imageIds.has(ref.elementId) : ref.kind === PageElementKind.MATH && mathIds.has(ref.elementId);
    if (valid && ref.elementId.length > 0 && !seen.has(ref.elementId)) {
      seen.add(ref.elementId);
      result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
    }
  }
  const legacy: PageElementRef[] = legacyPageElementOrder(strokes, textBlocks, shapes, images, mathBlocks);
  for (const ref of legacy) {
    if (!seen.has(ref.elementId)) {
      seen.add(ref.elementId);
      result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
    }
  }
  return result;
}

/**
 * Validates a complete page snapshot without repairing it.  An empty order is
 * accepted only as the legacy migration form and is expanded deterministically;
 * every explicit order must contain each globally unique entity ID exactly once.
 */
export function strictPageElementOrder(order: PageElementRef[], strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = [], images: ImageElement[] = [],
  mathBlocks: MathElement[] = []): PageElementRef[] | null {
  const expected: Map<string, PageElementKind> = new Map<string, PageElementKind>();
  for (const stroke of strokes) {
    if (!registerPageElementIdentity(expected, stroke.id, PageElementKind.STROKE)) {
      return null;
    }
  }
  for (const text of textBlocks) {
    if (!registerPageElementIdentity(expected, text.id, PageElementKind.TEXT)) {
      return null;
    }
  }
  for (const shape of shapes) {
    if (!registerPageElementIdentity(expected, shape.id, PageElementKind.SHAPE)) {
      return null;
    }
  }
  for (const image of images) {
    if (!registerPageElementIdentity(expected, image.id, PageElementKind.IMAGE)) {
      return null;
    }
  }
  for (const math of mathBlocks) {
    if (!registerPageElementIdentity(expected, math.id, PageElementKind.MATH)) {
      return null;
    }
  }
  if (order.length === 0) {
    return legacyPageElementOrder(strokes, textBlocks, shapes, images, mathBlocks);
  }
  if (order.length !== expected.size) {
    return null;
  }
  const seen: Set<string> = new Set<string>();
  const result: PageElementRef[] = [];
  for (let index: number = 0; index < order.length; index++) {
    const ref: PageElementRef = order[index];
    const expectedKind: PageElementKind | undefined = expected.get(ref.elementId);
    if (!validPageElementKind(ref.kind) || ref.elementId.length === 0 ||
      ref.zIndex !== index || expectedKind !== ref.kind || seen.has(ref.elementId)) {
      return null;
    }
    seen.add(ref.elementId);
    result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: index });
  }
  return seen.size === expected.size ? result : null;
}

export function materializePageElements(order: PageElementRef[], strokes: StrokeElementData[],
  textBlocks: TextBlockElement[], shapes: ShapeElement[] = [],
  images: ImageElement[] = [], mathBlocks: MathElement[] = [],
  transientTopStroke: StrokeElementData | null = null): OrderedPageElement[] {
  const normalized: PageElementRef[] = normalizePageElementOrder(
    order, strokes, textBlocks, shapes, images, mathBlocks);
  const strokesById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
  const textsById: Map<string, TextBlockElement> = new Map<string, TextBlockElement>();
  const shapesById: Map<string, ShapeElement> = new Map<string, ShapeElement>();
  const imagesById: Map<string, ImageElement> = new Map<string, ImageElement>();
  const mathById: Map<string, MathElement> = new Map<string, MathElement>();
  for (const stroke of strokes) {
    strokesById.set(stroke.id, stroke);
  }
  for (const text of textBlocks) {
    textsById.set(text.id, text);
  }
  for (const shape of shapes) {
    shapesById.set(shape.id, shape);
  }
  for (const image of images) {
    imagesById.set(image.id, image);
  }
  for (const math of mathBlocks) {
    mathById.set(math.id, math);
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
    } else if (ref.kind === PageElementKind.SHAPE) {
      const shape: ShapeElement | undefined = shapesById.get(ref.elementId);
      if (shape !== undefined) {
        result.push({ kind: PageElementKind.SHAPE, elementId: ref.elementId, zIndex: ref.zIndex, data: shape });
      }
    } else if (ref.kind === PageElementKind.IMAGE) {
      const image: ImageElement | undefined = imagesById.get(ref.elementId);
      if (image !== undefined) {
        result.push({ kind: PageElementKind.IMAGE, elementId: ref.elementId, zIndex: ref.zIndex, data: image });
      }
    } else if (ref.kind === PageElementKind.MATH) {
      const math: MathElement | undefined = mathById.get(ref.elementId);
      if (math !== undefined) {
        result.push({ kind: PageElementKind.MATH, elementId: ref.elementId, zIndex: ref.zIndex, data: math });
      }
    }
  }
  if (transientTopStroke !== null) {
    result.push({
      kind: PageElementKind.STROKE,
      elementId: transientTopStroke.id,
      zIndex: result.length,
      data: transientTopStroke,
    });
  }
  return result;
}

export function appendPageElementRefs(order: PageElementRef[], kind: PageElementKind,
  elementIds: string[]): PageElementRef[] {
  const result: PageElementRef[] = clonePageElementOrder(order);
  const seen: Set<string> = new Set<string>();
  for (const ref of result) {
    seen.add(ref.elementId);
  }
  for (const id of elementIds) {
    if (id.length > 0 && !seen.has(id)) {
      seen.add(id);
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
  forward: boolean, textIds: string[] = [], imageIds: string[] = [],
  mathIds: string[] = []): PageElementRef[] {
  const selectedStrokes: Set<string> = new Set<string>(strokeIds);
  const selectedShapes: Set<string> = new Set<string>(shapeIds);
  const selectedTexts: Set<string> = new Set<string>(textIds);
  const selectedImages: Set<string> = new Set<string>(imageIds);
  const selectedMath: Set<string> = new Set<string>(mathIds);
  const selected: PageElementRef[] = [];
  const remaining: PageElementRef[] = [];
  for (const ref of order) {
    const isSelected: boolean = ref.kind === PageElementKind.STROKE
      ? selectedStrokes.has(ref.elementId) : ref.kind === PageElementKind.SHAPE
        ? selectedShapes.has(ref.elementId) : ref.kind === PageElementKind.TEXT
          ? selectedTexts.has(ref.elementId) : ref.kind === PageElementKind.IMAGE
            ? selectedImages.has(ref.elementId) : ref.kind === PageElementKind.MATH && selectedMath.has(ref.elementId);
    if (isSelected) {
      selected.push(ref);
    } else {
      remaining.push(ref);
    }
  }
  return reindexPageElementOrder(forward ? remaining.concat(selected) : selected.concat(remaining));
}

export function movePageElementRefsOneStep(order: PageElementRef[], selectedEntityIds: string[],
  selectedGroupIds: string[], groups: OriginalSelectionGroup[], forward: boolean): PageElementRef[] {
  const selectedUnits: Set<string> = new Set<string>();
  const selectedEntities: Set<string> = new Set<string>();
  for (const id of selectedEntityIds) {
    if (id.length === 0 || selectedEntities.has(id)) {
      return clonePageElementOrder(order);
    }
    selectedEntities.add(id);
  }
  for (const id of selectedGroupIds) {
    if (id.length === 0 || selectedUnits.has(id)) {
      return clonePageElementOrder(order);
    }
    selectedUnits.add(id);
  }
  const units: OriginalSelectionLayerUnit[] | null = resolveOriginalSelectionLayerUnits(
    order.map((ref: PageElementRef): string => ref.elementId), groups);
  if (units === null) {
    return clonePageElementOrder(order);
  }
  const entityUnit: Map<string, OriginalSelectionLayerUnit> =
    new Map<string, OriginalSelectionLayerUnit>();
  const availableGroups: Set<string> = new Set<string>();
  for (const unit of units) {
    if (unit.group) {
      availableGroups.add(unit.id);
    }
    for (const id of unit.entityIds) {
      entityUnit.set(id, unit);
    }
  }
  for (const id of selectedEntities) {
    const unit: OriginalSelectionLayerUnit | undefined = entityUnit.get(id);
    if (unit === undefined || unit.group || selectedUnits.has(unit.id)) {
      return clonePageElementOrder(order);
    }
    selectedUnits.add(unit.id);
  }
  for (const id of selectedGroupIds) {
    if (!availableGroups.has(id)) {
      return clonePageElementOrder(order);
    }
  }
  const moved: OriginalSelectionLayerUnit[] = units.slice();
  if (forward) {
    for (let index: number = 0; index + 1 < units.length; index++) {
      if (selectedUnits.has(units[index].id) && !units[index].group &&
        !selectedUnits.has(units[index + 1].id)) {
        moved[index] = units[index + 1];
        moved[index + 1] = units[index];
      }
    }
  } else {
    for (let index: number = 1; index < units.length; index++) {
      if (selectedUnits.has(units[index].id) && !units[index].group &&
        !selectedUnits.has(units[index - 1].id)) {
        moved[index - 1] = units[index];
        moved[index] = units[index - 1];
      }
    }
  }
  const byId: Map<string, PageElementRef> = new Map<string, PageElementRef>();
  for (const ref of order) {
    if (byId.has(ref.elementId)) {
      return clonePageElementOrder(order);
    }
    byId.set(ref.elementId, ref);
  }
  const result: PageElementRef[] = [];
  for (const unit of moved) {
    for (const id of unit.entityIds) {
      const ref: PageElementRef | undefined = byId.get(id);
      if (ref === undefined) {
        return clonePageElementOrder(order);
      }
      result.push(ref);
    }
  }
  return reindexPageElementOrder(result);
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
  const kinds: Map<string, PageElementKind> = new Map<string, PageElementKind>();
  for (const ref of a) {
    if (!validPageElementKind(ref.kind) || ref.elementId.length === 0 || kinds.has(ref.elementId)) {
      return false;
    }
    kinds.set(ref.elementId, ref.kind);
  }
  const compared: Set<string> = new Set<string>();
  for (const ref of b) {
    if (kinds.get(ref.elementId) !== ref.kind || compared.has(ref.elementId)) {
      return false;
    }
    compared.add(ref.elementId);
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
    if (ref.kind === PageElementKind.SHAPE || ref.kind === PageElementKind.IMAGE ||
      ref.kind === PageElementKind.MATH) {
      return true;
    }
  }
  return false;
}

function reindexPageElementOrder(order: PageElementRef[]): PageElementRef[] {
  const result: PageElementRef[] = [];
  for (const ref of order) {
    result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
  }
  return result;
}

function registerPageElementIdentity(expected: Map<string, PageElementKind>,
  elementId: string, kind: PageElementKind): boolean {
  if (elementId.length === 0 || expected.has(elementId)) {
    return false;
  }
  expected.set(elementId, kind);
  return true;
}

function validPageElementKind(kind: PageElementKind): boolean {
  return Number.isSafeInteger(kind) && kind >= PageElementKind.STROKE && kind <= PageElementKind.MATH;
}
