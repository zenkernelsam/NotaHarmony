import {
  encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalModifyPosition } from './OriginalModifyPositionsOperation';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';

const MAX_MODIFICATION_COUNT: number = 10000;

interface RowLayout {
  vtable: number;
  table: number;
  rotationVtable: number;
  rotationTable: number;
  scaleVtable: number;
  scaleTable: number;
}

export function encodeOriginalModifyPositions(
  modifications: OriginalModifyPosition[]): Uint8Array {
  validateModifications(modifications);
  const rootVtable: number = 4;
  const rootTable: number = 12;
  const vector: number = 20;
  let cursor: number = align4(vector + 4 + modifications.length * 4);
  const layouts: RowLayout[] = [];
  for (const modification of modifications) {
    const vtable: number = cursor;
    const table: number = vtable + 16;
    cursor = table + 48;
    let rotationVtable: number = 0;
    let rotationTable: number = 0;
    if (modification.rotation.present) {
      rotationVtable = cursor;
      rotationTable = align4(rotationVtable + 6);
      cursor = rotationTable + 8;
    }
    let scaleVtable: number = 0;
    let scaleTable: number = 0;
    if (modification.scale.present) {
      scaleVtable = cursor;
      scaleTable = align4(scaleVtable + 6);
      cursor = scaleTable + 12;
    }
    layouts.push({ vtable: vtable, table: table,
      rotationVtable: rotationVtable, rotationTable: rotationTable,
      scaleVtable: scaleVtable, scaleTable: scaleTable });
    cursor = align4(cursor);
  }

  const bytes: Uint8Array = new Uint8Array(cursor);
  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 8, [4]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  writeU32(bytes, rootTable + 4, vector - (rootTable + 4));
  writeU32(bytes, vector, modifications.length);

  for (let index: number = 0; index < modifications.length; index++) {
    const modification: OriginalModifyPosition = modifications[index];
    const layout: RowLayout = layouts[index];
    const vectorEntry: number = vector + 4 + index * 4;
    writeU32(bytes, vectorEntry, layout.table - vectorEntry);
    writeVtable(bytes, layout.vtable, 48, [4,
      modification.pageOrigin === null ? 0 : 12,
      modification.pageOrigin === null ? 0 : 24,
      modification.rotation.present ? 32 : 0,
      modification.scale.present ? 36 : 0,
      modification.zIndex === null ? 0 : 40]);
    writeU32(bytes, layout.table, layout.table - layout.vtable);
    writeIdentity(bytes, layout.table + 4, modification.target);
    if (modification.pageOrigin !== null) {
      writeSequence(bytes, layout.table + 12, modification.pageOrigin.page);
      writeF32(bytes, layout.table + 24, modification.pageOrigin.originX);
      writeF32(bytes, layout.table + 28, modification.pageOrigin.originY);
    }
    if (modification.rotation.present) {
      writeU32(bytes, layout.table + 32, layout.rotationTable - (layout.table + 32));
      writeVtable(bytes, layout.rotationVtable, 8,
        [modification.rotation.value === null ? 0 : 4]);
      writeU32(bytes, layout.rotationTable, layout.rotationTable - layout.rotationVtable);
      if (modification.rotation.value !== null) {
        writeF32(bytes, layout.rotationTable + 4, modification.rotation.value);
      }
    }
    if (modification.scale.present) {
      writeU32(bytes, layout.table + 36, layout.scaleTable - (layout.table + 36));
      writeVtable(bytes, layout.scaleVtable, 12,
        [modification.scale.value === null ? 0 : 4]);
      writeU32(bytes, layout.scaleTable, layout.scaleTable - layout.scaleVtable);
      if (modification.scale.value !== null) {
        writeF32(bytes, layout.scaleTable + 4, modification.scale.value.x);
        writeF32(bytes, layout.scaleTable + 8, modification.scale.value.y);
      }
    }
    if (modification.zIndex !== null) {
      writeUint64Decimal(bytes, layout.table + 40, modification.zIndex);
    }
  }
  return bytes;
}

function validateModifications(modifications: OriginalModifyPosition[]): void {
  if (modifications.length === 0 || modifications.length > MAX_MODIFICATION_COUNT) {
    throw new Error('original MODIFY_POSITIONS has an invalid modification count');
  }
  const targets: Set<string> = new Set<string>();
  for (const modification of modifications) {
    validateOperationIdentity(modification.target);
    const target: string = encodeOperationId(modification.target);
    if (targets.has(target)) {
      throw new Error('original MODIFY_POSITIONS repeats a target');
    }
    targets.add(target);
    if (modification.pageOrigin !== null) {
      validateOriginalSequenceIdentity(modification.pageOrigin.page);
      finite(modification.pageOrigin.originX);
      finite(modification.pageOrigin.originY);
    }
    if (modification.rotation.value !== null) {
      finite(modification.rotation.value);
    }
    if (modification.scale.value !== null) {
      finite(modification.scale.value.x);
      finite(modification.scale.value.y);
    }
    if (modification.zIndex !== null) {
      validateUnsignedLongDecimal(modification.zIndex);
    }
    if (modification.pageOrigin === null && !modification.rotation.present &&
      !modification.scale.present && modification.zIndex === null) {
      throw new Error('original MODIFY_POSITIONS row has no update');
    }
  }
}

function finite(value: number): void {
  if (!Number.isFinite(value)) {
    throw new Error('original MODIFY_POSITIONS geometry is not finite');
  }
}

function writeIdentity(bytes: Uint8Array, offset: number, value: OperationIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
}

function writeSequence(bytes: Uint8Array, offset: number,
  value: OriginalSequenceIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
  writeU32(bytes, offset + 8, value.index);
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
}

function writeUint64Decimal(bytes: Uint8Array, offset: number, value: string): void {
  let remaining: string = value;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let remainder: number = 0;
    for (let digitIndex: number = 0; digitIndex < remaining.length; digitIndex++) {
      const current: number = remainder * 10 + remaining.charCodeAt(digitIndex) - 0x30;
      const digit: number = Math.floor(current / 256);
      remainder = current % 256;
      if (quotient.length > 0 || digit !== 0) {
        quotient += digit.toString();
      }
    }
    bytes[offset + index] = remainder;
    remaining = quotient.length === 0 ? '0' : quotient;
  }
  if (remaining !== '0') {
    throw new Error('original MODIFY_POSITIONS uint64 exceeds its field');
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
