import {
  ElementType, NoteElement, OriginalShapeCreateMetadata, ShapeElement,
} from './ElementTypes';
import { cloneShapeElement, recomputeShapeBounds } from './ShapeGeometry';
import { TapePattern } from './StrokeTypes';

export interface RecognizedShapeInkMetadata {
  tool?: number;
  style?: number;
  tapePattern?: TapePattern | null;
  smartHighlight?: boolean;
  force?: number | null;
  inkEffects?: string;
  inkEffectsTinted?: boolean;
  originalCreate?: OriginalShapeCreateMetadata;
}

// MyScript may return several ShapeDefinition elements for one held gesture.
// Normalize the result atomically: one unsupported element rejects the whole replacement.
export function prepareRecognizedShapes(elements: NoteElement[], sourceId: string,
  color: number, strokeWidth: number,
  original?: RecognizedShapeInkMetadata): ShapeElement[] {
  const result: ShapeElement[] = [];
  // ao2 refuses VARIABLE_WIDTH CREATE_SHAPE. A held variable-width Ink is recognized as the
  // original legal fixed-width Shape style so the reserved outbound identity remains usable.
  const originalStyle: number | undefined = original?.style === 0 ? 1 : original?.style;
  for (let i: number = 0; i < elements.length; i++) {
    const element: NoteElement = elements[i];
    if (element.type !== ElementType.LINE && element.type !== ElementType.ELLIPSE &&
      element.type !== ElementType.POLYGON) {
      return [];
    }
    const shape: ShapeElement = cloneShapeElement(element as ShapeElement);
    shape.id = elements.length === 1 ? sourceId : `${sourceId}:shape:${i}`;
    shape.color = color;
    shape.strokeWidth = strokeWidth;
    shape.fillColor = null;
    shape.originalTool = original?.tool;
    shape.originalStyle = originalStyle;
    shape.originalTapePattern = original?.tapePattern;
    shape.originalSmartHighlight = original?.smartHighlight;
    shape.originalForce = original?.force;
    shape.originalInkEffects = original?.inkEffects;
    shape.originalInkEffectsTinted = original?.inkEffectsTinted;
    shape.originalCreate = elements.length === 1 && originalStyle !== undefined &&
      originalStyle >= 1 && originalStyle <= 3 ? original?.originalCreate : undefined;
    shape.bounds = recomputeShapeBounds(shape);
    result.push(shape);
  }
  return result;
}
