import { ElementType, NoteElement, ShapeElement } from './ElementTypes';
import { cloneShapeElement, recomputeShapeBounds } from './ShapeGeometry';

// MyScript may return several ShapeDefinition elements for one held gesture.
// Normalize the result atomically: one unsupported element rejects the whole replacement.
export function prepareRecognizedShapes(elements: NoteElement[], sourceId: string,
  color: number, strokeWidth: number, originalTool?: number): ShapeElement[] {
  const result: ShapeElement[] = [];
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
    shape.originalTool = originalTool;
    shape.bounds = recomputeShapeBounds(shape);
    result.push(shape);
  }
  return result;
}
