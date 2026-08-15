import { NoteBackgroundSettings } from '../core/model/NoteTypes';
import {
  cloneNoteBackgroundSettings, sameNoteBackgroundSettings, validateNoteBackgroundSettings,
} from '../core/model/PageBackgroundModel';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_STRING_BYTES,
} from './BinaryOpCodec';

const MAGIC: number[] = [0x4E, 0x42, 0x47, 0x31]; // NBG1

export interface NoteBackgroundMutation {
  fromRevision: number;
  toRevision: number;
  selectedPageId: string;
  before: NoteBackgroundSettings;
  after: NoteBackgroundSettings;
}

export function encodeNoteBackgroundMutation(mutation: NoteBackgroundMutation): Uint8Array {
  validateNoteBackgroundMutation(mutation);
  const selectedPageId: Uint8Array = encodeOperationString(
    mutation.selectedPageId, 'note background selected page ID');
  const before: Uint8Array = encodeSettings(mutation.before, 'before');
  const after: Uint8Array = encodeSettings(mutation.after, 'after');
  const size: number = MAGIC.length + 16 + 4 + selectedPageId.length +
    4 + before.length + 4 + after.length;
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(selectedPageId);
  writer.writeSizedBytes(before);
  writer.writeSizedBytes(after);
  return writer.finish();
}

export function decodeNoteBackgroundMutation(bytes: Uint8Array): NoteBackgroundMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: NoteBackgroundMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    selectedPageId: reader.readString(),
    before: decodeSettings(reader.readSizedBytes(MAX_OPERATION_STRING_BYTES), 'before'),
    after: decodeSettings(reader.readSizedBytes(MAX_OPERATION_STRING_BYTES), 'after'),
  };
  if (!reader.atEnd()) {
    throw new Error('note background mutation has trailing bytes');
  }
  validateNoteBackgroundMutation(mutation);
  return mutation;
}

export function validateNoteBackgroundMutation(mutation: NoteBackgroundMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    mutation.fromRevision >= Number.MAX_SAFE_INTEGER ||
    mutation.toRevision !== mutation.fromRevision + 1 ||
    mutation.selectedPageId.length < 1 || mutation.selectedPageId.length > 512) {
    throw new Error('note background mutation identity is invalid');
  }
  validateNoteBackgroundSettings(mutation.before);
  validateNoteBackgroundSettings(mutation.after);
  if (sameNoteBackgroundSettings(mutation.before, mutation.after)) {
    throw new Error('note background mutation does not change the register');
  }
}

function encodeSettings(value: NoteBackgroundSettings, label: string): Uint8Array {
  validateNoteBackgroundSettings(value);
  const encoded: string = JSON.stringify(cloneNoteBackgroundSettings(value));
  return encodeOperationString(encoded, `note background ${label} settings`);
}

function decodeSettings(bytes: Uint8Array, label: string): NoteBackgroundSettings {
  const wrapper: Uint8Array = new Uint8Array(4 + bytes.length);
  wrapper[0] = bytes.length & 0xFF;
  wrapper[1] = bytes.length >>> 8 & 0xFF;
  wrapper[2] = bytes.length >>> 16 & 0xFF;
  wrapper[3] = bytes.length >>> 24 & 0xFF;
  wrapper.set(bytes, 4);
  const reader: BinaryOpReader = new BinaryOpReader(wrapper);
  const encoded: string = reader.readString();
  if (!reader.atEnd()) {
    throw new Error(`note background ${label} settings are malformed`);
  }
  try {
    const value: NoteBackgroundSettings = JSON.parse(encoded) as NoteBackgroundSettings;
    validateNoteBackgroundSettings(value);
    return cloneNoteBackgroundSettings(value);
  } catch (_error) {
    throw new Error(`note background ${label} settings are invalid`);
  }
}
