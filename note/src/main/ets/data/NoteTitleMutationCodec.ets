import { validateOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { BinaryOpReader, BinaryOpWriter, encodeOperationString } from './BinaryOpCodec';

const MAGIC: number[] = [0x4E, 0x54, 0x4C, 0x31]; // NTL1

export interface NoteTitleMutation {
  fromRevision: number;
  toRevision: number;
  selectedPageId: string;
  before: string;
  after: string;
}

export function encodeNoteTitleMutation(mutation: NoteTitleMutation): Uint8Array {
  validateNoteTitleMutation(mutation);
  const selectedPageId: Uint8Array = encodeOperationString(
    mutation.selectedPageId, 'note title selected page ID');
  const before: Uint8Array = encodeOperationString(mutation.before, 'note title before value');
  const after: Uint8Array = encodeOperationString(mutation.after, 'note title after value');
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(
    MAGIC.length + 16 + 4 + selectedPageId.length + 4 + before.length + 4 + after.length));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(selectedPageId);
  writer.writeSizedBytes(before);
  writer.writeSizedBytes(after);
  return writer.finish();
}

export function decodeNoteTitleMutation(bytes: Uint8Array): NoteTitleMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: NoteTitleMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    selectedPageId: reader.readString(),
    before: reader.readString(),
    after: reader.readString(),
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
