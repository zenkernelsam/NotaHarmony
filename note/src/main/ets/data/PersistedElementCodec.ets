import { util } from '@kit.ArkTS';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { PageElementKind } from '../core/model/PageElementOrder';

export interface PersistedElement {
  kind: string;
  data: StrokeElementData | TextBlockElement | ShapeElement | ImageElement | MathElement;
}

export function encodePersistedElement(element: PersistedElement): Uint8Array {
  return new util.TextEncoder().encodeInto(JSON.stringify(element));
}

export function decodePersistedElement(payload: Uint8Array): PersistedElement {
  return JSON.parse(util.TextDecoder.create('utf-8').decodeToString(payload)) as PersistedElement;
}

export function decodeStoredPageElement(elementId: string, kind: number,
  payload: Uint8Array): PersistedElement {
  if (elementId.length === 0 || !Number.isSafeInteger(kind) ||
    kind < PageElementKind.STROKE || kind > PageElementKind.MATH || payload.length === 0) {
    throw new Error('stored page element identity is invalid');
  }
  const persisted: PersistedElement = decodePersistedElement(payload);
  const expectedKind: string = kind === PageElementKind.STROKE ? 'stroke' :
    (kind === PageElementKind.TEXT ? 'text' :
      (kind === PageElementKind.SHAPE ? 'shape' :
        (kind === PageElementKind.IMAGE ? 'image' : 'math')));
  if (persisted.kind !== expectedKind || persisted.data.id !== elementId) {
    throw new Error('stored page element payload identity does not match its row');
  }
  return persisted;
}
