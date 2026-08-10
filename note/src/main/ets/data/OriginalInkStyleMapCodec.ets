import { InkStyleMapEntry } from '../core/model/StrokeTypes';

export const ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES: number = 20;
export const MAX_ORIGINAL_INK_STYLE_MAP_ENTRIES: number = 65535;

export function decodeOriginalInkStyleMap(bytes: Uint8Array | null): InkStyleMapEntry[] {
  if (bytes === null || bytes.length === 0) {
    return [];
  }
  if (bytes.length % ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES !== 0 ||
    bytes.length / ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES > MAX_ORIGINAL_INK_STYLE_MAP_ENTRIES) {
    throw new Error('original Ink style map has an invalid length');
  }
  const view: DataView = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const entries: InkStyleMapEntry[] = [];
  for (let offset: number = 0; offset < bytes.length;
    offset += ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES) {
    const entry: InkStyleMapEntry = {
      backingPencilSeed: view.getInt32(offset, true),
      backingPencilReferencePoint: {
        x: view.getFloat32(offset + 4, true), y: view.getFloat32(offset + 8, true),
      },
      backingDashPhase: view.getFloat32(offset + 12, true),
      backingDashPeriod: view.getFloat32(offset + 16, true),
    };
    if (!Number.isFinite(entry.backingPencilReferencePoint.x) ||
      !Number.isFinite(entry.backingPencilReferencePoint.y) ||
      !Number.isFinite(entry.backingDashPhase) || !Number.isFinite(entry.backingDashPeriod)) {
      throw new Error('original Ink style map contains a non-finite value');
    }
    entries.push(entry);
  }
  return entries;
}

export function cloneInkStyleMap(entries: InkStyleMapEntry[] | undefined): InkStyleMapEntry[] {
  if (entries === undefined) {
    return [];
  }
  return entries.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
    backingPencilSeed: entry.backingPencilSeed,
    backingPencilReferencePoint: {
      x: entry.backingPencilReferencePoint.x, y: entry.backingPencilReferencePoint.y,
    },
    backingDashPhase: entry.backingDashPhase,
    backingDashPeriod: entry.backingDashPeriod,
  }));
}

export function sameInkStyleMap(left: InkStyleMapEntry[] | undefined,
  right: InkStyleMapEntry[]): boolean {
  const normalized: InkStyleMapEntry[] = left === undefined ? [] : left;
  if (normalized.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < normalized.length; index++) {
    const a: InkStyleMapEntry = normalized[index];
    const b: InkStyleMapEntry = right[index];
    if (a.backingPencilSeed !== b.backingPencilSeed ||
      a.backingPencilReferencePoint.x !== b.backingPencilReferencePoint.x ||
      a.backingPencilReferencePoint.y !== b.backingPencilReferencePoint.y ||
      a.backingDashPhase !== b.backingDashPhase ||
      a.backingDashPeriod !== b.backingDashPeriod) {
      return false;
    }
  }
  return true;
}
