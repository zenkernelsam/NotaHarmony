import { validateOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { BinaryOpReader, BinaryOpWriter, encodeOperationString } from './BinaryOpCodec';

const MAGIC_V1: number[] = [0x4E, 0x54, 0x4C, 0x31]; // NTL1: both values are strings.
const MAGIC_V2: number[] = [0x4E, 0x54, 0x4C, 0x32]; // NTL2: nullable register values.

export interface NoteTitleMutation {
  fromRevision: number;
  toRevision: number;
  selectedPageId: string;
  before: string | null;
  after: string | null;
}

export function encodeNoteTitleMutation(mutation: NoteTitleMutation): Uint8Array {
  validateNoteTitleMutation(mutation);
  const selectedPageId: Uint8Array = encodeOperationString(
    mutation.selectedPageId, 'note title selected page ID');
  const before: Uint8Array | null = mutation.before === null ? null :
    encodeOperationString(mutation.before, 'note title before value');
  const after: Uint8Array | null = mutation.after === null ? null :
    encodeOperationString(mutation.after, 'note title after value');
  const flags: number = (before === null ? 0 : 1) | (after === null ? 0 : 2);
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(
    MAGIC_V2.length + 16 + 4 + selectedPageId.length + 1 +
    (before === null ? 0 : 4 + before.length) + (after === null ? 0 : 4 + after.length)));
  writer.writeBytes(new Uint8Array(MAGIC_V2));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(selectedPageId);
  writer.writeByte(flags);
  if (before !== null) {
    writer.writeSizedBytes(before);
  }
  if (after !== null) {
    writer.writeSizedBytes(after);
  }
  return writer.finish();
}

export function decodeNoteTitleMutation(bytes: Uint8Array): NoteTitleMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  const version: number = readMagicVersion(reader);
  const fromRevision: number = reader.readSafeInteger();
  const toRevision: number = reader.readSafeInteger();
  const selectedPageId: string = reader.readString();
  let before: string | null;
  let after: string | null;
  if (version === 1) {
    before = reader.readString();
    after = reader.readString();
  } else {
    const flags: number = reader.readByte();
    if (flags < 0 || flags > 3) {
      throw new Error('note title mutation nullable flags are invalid');
    }
    before = (flags & 1) === 0 ? null : reader.readString();
    after = (flags & 2) === 0 ? null : reader.readString();
  }
  const mutation: NoteTitleMutation = {
    fromRevision: fromRevision,
    toRevision: toRevision,
    selectedPageId: selectedPageId,
    before: before,
    after: after,
  };
  if (!reader.atEnd()) {
    throw new Error('note title mutation has trailing bytes');
  }
  validateNoteTitleMutation(mutation);
  return mutation;
}

export function validateNoteTitleMutation(mutation: NoteTitleMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    mutation.fromRevision >= Number.MAX_SAFE_INTEGER ||
    mutation.toRevision !== mutation.fromRevision + 1 ||
    mutation.selectedPageId.length < 1 || mutation.selectedPageId.length > 512) {
    throw new Error('note title mutation identity is invalid');
  }
  validateOriginalNoteTitleWireValue(mutation.before);
  validateOriginalNoteTitleWireValue(mutation.after);
  if (mutation.before === mutation.after) {
    throw new Error('note title mutation does not change the register');
  }
}

function readMagicVersion(reader: BinaryOpReader): number {
  const actual: number[] = [reader.readByte(), reader.readByte(), reader.readByte(), reader.readByte()];
  if (sameMagic(actual, MAGIC_V1)) {
    return 1;
  }
  if (sameMagic(actual, MAGIC_V2)) {
    return 2;
  }
  throw new Error('invalid note title mutation magic');
}

function sameMagic(left: number[], right: number[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}
