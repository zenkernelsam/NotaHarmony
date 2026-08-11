import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';

const MAX_ORIGINAL_MODIFY_SHAPE_COUNT: number = 10000;

export interface OriginalShapeRenderRegisterUpdate {
  style: number | null;
  color: number | null;
  borderWidth: number | null;
  fillColorPresent: boolean;
  fillColor: number | null;
}

export function encodeOriginalShapeRenderRegisters(shapes: OperationIdentity[],
  update: OriginalShapeRenderRegisterUpdate): Uint8Array {
  const targets: OperationIdentity[] = validateTargets(shapes);
  if (targets.length === 0 || targets.length > MAX_ORIGINAL_MODIFY_SHAPE_COUNT) {
    throw new Error('original MODIFY_SHAPE has an invalid target count');
  }
  if (update.style === null && update.color === null &&
    update.borderWidth === null && !update.fillColorPresent) {
    throw new Error('original MODIFY_SHAPE has no render register update');
  }
  if (update.style !== null &&
    (!Number.isInteger(update.style) || update.style < 1 || update.style > 3)) {
    throw new Error('original MODIFY_SHAPE style is invalid');
  }
  if (update.color !== null && !validColor(update.color)) {
    throw new Error('original MODIFY_SHAPE color is invalid');
  }
  if (update.borderWidth !== null &&
    (!Number.isFinite(update.borderWidth) || update.borderWidth < 0)) {
    throw new Error('original MODIFY_SHAPE border width is invalid');
  }
  if (update.fillColorPresent && update.fillColor !== null && !validColor(update.fillColor)) {
    throw new Error('original MODIFY_SHAPE fill color is invalid');
  }
  if (update.fillColorPresent && update.fillColor !== null &&
    (update.fillColor >>> 24 & 0xFF) === 0) {
    throw new Error('original MODIFY_SHAPE fill color is transparent');
  }

  // le8 has 17 fields. u5j.x writes style/color/borderWidth/fillColor at fields 8/10/11/12.
  const table: number = 44;
  const objectSize: number = 24;
  const vector: number = table + objectSize;
  const vectorEnd: number = vector + 4 + targets.length * 8;
  const setterVtable: number = update.fillColorPresent ? align4(vectorEnd) : 0;
  const setterTable: number = update.fillColorPresent ? align4(setterVtable + 6) : 0;
  const setterSize: number = update.fillColor === null ? 4 : 8;
  const total: number = update.fillColorPresent ? setterTable + setterSize : vectorEnd;
  const bytes: Uint8Array = new Uint8Array(total);
  const fields: number[] = new Array<number>(17).fill(0);
  fields[0] = 4;
  fields[8] = update.style === null ? 0 : 8;
  fields[10] = update.color === null ? 0 : 12;
  fields[11] = update.borderWidth === null ? 0 : 16;
  fields[12] = update.fillColorPresent ? 20 : 0;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  if (update.style !== null) {
    bytes[table + 8] = update.style;
  }
  if (update.color !== null) {
    writeColor(bytes, table + 12, update.color);
  }
  if (update.borderWidth !== null) {
    writeF32(bytes, table + 16, update.borderWidth);
  }
  if (update.fillColorPresent) {
    writeU32(bytes, table + 20, setterTable - (table + 20));
  }
  writeU32(bytes, vector, targets.length);
  for (let index: number = 0; index < targets.length; index++) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, targets[index].siteId);
    writeU32(bytes, offset + 4, targets[index].timestamp);
  }
  if (update.fillColorPresent) {
    writeVtable(bytes, setterVtable, setterSize,
      [update.fillColor === null ? 0 : 4]);
    writeU32(bytes, setterTable, setterTable - setterVtable);
    if (update.fillColor !== null) {
      writeColor(bytes, setterTable + 4, update.fillColor);
    }
  }
  return bytes;
}

function validateTargets(shapes: OperationIdentity[]): OperationIdentity[] {
  const result: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const shape of shapes) {
    validateOperationIdentity(shape);
    const key: string = encodeOperationId(shape);
    if (seen.has(key)) {
      throw new Error('original MODIFY_SHAPE repeats a target Shape');
    }
    seen.add(key);
    result.push({ timestamp: shape.timestamp, siteId: shape.siteId });
  }
  return result;
}

function validColor(color: number): boolean {
  return Number.isSafeInteger(color) && color >= -2147483648 && color <= 4294967295;
}

function writeColor(bytes: Uint8Array, offset: number, argb: number): void {
  bytes[offset] = argb >>> 16 & 0xFF;
  bytes[offset + 1] = argb >>> 8 & 0xFF;
  bytes[offset + 2] = argb & 0xFF;
  bytes[offset + 3] = argb >>> 24 & 0xFF;
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

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(offset, value, true);
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
