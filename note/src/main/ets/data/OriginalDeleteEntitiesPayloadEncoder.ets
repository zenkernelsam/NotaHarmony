import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
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

  // FlatBuffer table fields: entityDeletes, entityUndeletes, pageDeletes, pageUndeletes.
  const vector: number = 36;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + deduplicated.length * 8);
  writeU32(bytes, 0, 16);
  writeU16(bytes, 4, 12);
  writeU16(bytes, 6, 20);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 0);
  writeU16(bytes, 12, 0);
  writeU16(bytes, 14, 0);
  writeU32(bytes, 16, 12);
  writeU32(bytes, 20, vector - 20);
  writeU32(bytes, vector, deduplicated.length);
  let index: number = 0;
  while (index < deduplicated.length) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, deduplicated[index].siteId);
    writeU32(bytes, offset + 4, deduplicated[index].timestamp);
    index++;
  }
  return bytes;
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
