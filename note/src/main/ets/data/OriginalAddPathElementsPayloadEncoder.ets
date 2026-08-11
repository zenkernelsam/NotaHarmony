import { OperationIdentity, validateOperationIdentity } from './OperationIdentity';

export function encodeOriginalAddPathElementsPayload(inkId: OperationIdentity,
  actualPath: Uint8Array | null, estimatedPath: Uint8Array | null): Uint8Array {
  validateOperationIdentity(inkId);
  validatePath(actualPath, 'actual');
  validatePath(estimatedPath, 'estimated');
  if (actualPath === null && estimatedPath === null) {
    throw new Error('local ADD_PATH_ELEMENTS requires actual or estimated path');
  }

  const table: number = 16;
  const actualVector: number = actualPath === null ? 0 : 36;
  const estimatedVector: number = estimatedPath === null ? 0 :
    align4((actualPath === null ? 36 : actualVector + 4 + actualPath.length));
  const lastVector: number = estimatedPath === null ? actualVector : estimatedVector;
  const lastPath: Uint8Array | null = estimatedPath === null ? actualPath : estimatedPath;
  const total: number = lastPath === null ? 36 : align4(lastVector + 4 + lastPath.length);
  const bytes: Uint8Array = new Uint8Array(total);

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, 20, [4, actualPath === null ? 0 : 12, estimatedPath === null ? 0 : 16]);
  writeU32(bytes, table, table - 4);
  writeIdentity(bytes, table + 4, inkId);
  if (actualPath !== null) {
    writeU32(bytes, table + 12, actualVector - (table + 12));
    writeVector(bytes, actualVector, actualPath);
  }
  if (estimatedPath !== null) {
    writeU32(bytes, table + 16, estimatedVector - (table + 16));
    writeVector(bytes, estimatedVector, estimatedPath);
  }
  return bytes;
}

function validatePath(path: Uint8Array | null, name: string): void {
  if (path !== null && path.length === 0) {
    throw new Error(`local ADD_PATH_ELEMENTS ${name} path is empty`);
  }
}

function writeIdentity(bytes: Uint8Array, offset: number, value: OperationIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
}

function writeVector(bytes: Uint8Array, offset: number, value: Uint8Array): void {
  writeU32(bytes, offset, value.length);
  bytes.set(value, offset + 4);
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
}

function align4(value: number): number {
  return (value + 3) & ~3;
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
