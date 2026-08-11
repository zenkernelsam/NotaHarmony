import {
  encodeOperationId, encodeOriginalSequenceId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { MAX_ORIGINAL_DELETE_ENTITY_COUNT } from './OriginalDeleteEntitiesOperation';

export function encodeOriginalEntityDeletes(entities: OperationIdentity[]): Uint8Array {
  if (entities.length === 0 || entities.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original entity delete payload has an invalid target count');
  }
  const deduplicated: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const entity of entities) {
    validateOperationIdentity(entity);
    const key: string = encodeOperationId(entity);
    if (!seen.has(key)) {
      seen.add(key);
      deduplicated.push({ timestamp: entity.timestamp, siteId: entity.siteId });
    }
  }

  return encodeVisibilityVectors(deduplicated, [], [], []);
}

export function encodeOriginalPageVisibility(pageDeletes: OriginalSequenceIdentity[],
  pageUndeletes: OriginalSequenceIdentity[]): Uint8Array {
  return encodeVisibilityVectors([], [], deduplicatePages(pageDeletes),
    deduplicatePages(pageUndeletes));
}

function encodeVisibilityVectors(entityDeletes: OperationIdentity[],
  entityUndeletes: OperationIdentity[], pageDeletes: OriginalSequenceIdentity[],
  pageUndeletes: OriginalSequenceIdentity[]): Uint8Array {
  // FlatBuffer fields: entityDeletes, entityUndeletes, pageDeletes, pageUndeletes.
  const counts: number[] = [entityDeletes.length, entityUndeletes.length,
    pageDeletes.length, pageUndeletes.length];
  if (counts[0] + counts[1] + counts[2] + counts[3] === 0) {
    throw new Error('original visibility payload has no targets');
  }
  const elementSizes: number[] = [8, 8, 12, 12];
  const starts: number[] = [0, 0, 0, 0];
  let cursor: number = 36;
  for (let field: number = 0; field < counts.length; field++) {
    if (counts[field] > 0) {
      starts[field] = cursor;
      cursor += 4 + counts[field] * elementSizes[field];
    }
  }
  const bytes: Uint8Array = new Uint8Array(cursor);
  writeU32(bytes, 0, 16);
  writeU16(bytes, 4, 12);
  writeU16(bytes, 6, 20);
  for (let field: number = 0; field < starts.length; field++) {
    writeU16(bytes, 8 + field * 2, starts[field] === 0 ? 0 : 4 + field * 4);
  }
  writeU32(bytes, 16, 12);
  for (let field: number = 0; field < starts.length; field++) {
    if (starts[field] !== 0) {
      const pointer: number = 20 + field * 4;
      writeU32(bytes, pointer, starts[field] - pointer);
      writeU32(bytes, starts[field], counts[field]);
    }
  }
  writeOperations(bytes, starts[0], entityDeletes);
  writeOperations(bytes, starts[1], entityUndeletes);
  writePages(bytes, starts[2], pageDeletes);
  writePages(bytes, starts[3], pageUndeletes);
  return bytes;
}

function deduplicatePages(pages: OriginalSequenceIdentity[]): OriginalSequenceIdentity[] {
  if (pages.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original page visibility payload has too many targets');
  }
  const result: OriginalSequenceIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const page of pages) {
    validateOriginalSequenceIdentity(page);
    const key: string = encodeOriginalSequenceId(page);
    if (!seen.has(key)) {
      seen.add(key);
      result.push({ timestamp: page.timestamp, siteId: page.siteId, index: page.index });
    }
  }
  return result;
}

function writeOperations(bytes: Uint8Array, vector: number,
  values: OperationIdentity[]): void {
  for (let index: number = 0; index < values.length; index++) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, values[index].siteId);
    writeU32(bytes, offset + 4, values[index].timestamp);
  }
}

function writePages(bytes: Uint8Array, vector: number,
  values: OriginalSequenceIdentity[]): void {
  for (let index: number = 0; index < values.length; index++) {
    const offset: number = vector + 4 + index * 12;
    writeU16(bytes, offset, values[index].siteId);
    writeU32(bytes, offset + 4, values[index].timestamp);
    writeU32(bytes, offset + 8, values[index].index);
  }
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
  bytes[offset + 2] = value >>> 16 & 0xFF;
  bytes[offset + 3] = value >>> 24 & 0xFF;
}
