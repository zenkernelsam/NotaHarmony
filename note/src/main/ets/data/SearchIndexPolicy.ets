import { PageElementKind } from '../core/model/PageElementOrder';

export interface SearchSourceElement {
  elementId: string;
  kind: number;
  payload: Uint8Array;
}

// Imported INK recognition remains valid across no-op saves and non-ink edits. Any
// stroke byte/order change makes it stale until a recognition provider replaces it.
export function handwritingSourceChanged(current: SearchSourceElement[],
  next: SearchSourceElement[]): boolean {
  const currentSource: SearchSourceElement[] = inkElements(current);
  const nextSource: SearchSourceElement[] = inkElements(next);
  if (currentSource.length !== nextSource.length) {
    return true;
  }
  for (let i: number = 0; i < currentSource.length; i++) {
    const left: SearchSourceElement = currentSource[i];
    const right: SearchSourceElement = nextSource[i];
    if (left.elementId !== right.elementId || left.kind !== right.kind ||
      !sameBytes(left.payload, right.payload)) {
      return true;
    }
  }
  return false;
}

export function pageSnapshotChanged(current: SearchSourceElement[],
  next: SearchSourceElement[]): boolean {
  if (current.length !== next.length) {
    return true;
  }
  for (let i: number = 0; i < current.length; i++) {
    const left: SearchSourceElement = current[i];
    const right: SearchSourceElement = next[i];
    if (left.elementId !== right.elementId || left.kind !== right.kind ||
      !sameBytes(left.payload, right.payload)) {
      return true;
    }
  }
  return false;
}

function inkElements(elements: SearchSourceElement[]): SearchSourceElement[] {
  const result: SearchSourceElement[] = [];
  for (const element of elements) {
    if (element.kind === PageElementKind.STROKE) {
      result.push(element);
    }
  }
  return result;
}

function sameBytes(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let i: number = 0; i < left.length; i++) {
    if (left[i] !== right[i]) {
      return false;
    }
  }
  return true;
}
