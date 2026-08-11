import { util } from '@kit.ArkTS';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';

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
