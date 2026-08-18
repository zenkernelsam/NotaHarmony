import {
  isOriginalDefaultFontFamily, isOriginalDefaultFontSize, isOriginalHandwritingLanguage,
  isOriginalNoteBlockWrapSupport, isOriginalNoteLayoutMode,
  OriginalNoteBlockWrapSupport, OriginalNoteLayoutMode,
} from '../core/model/OriginalNoteMetadataPolicy';
import { NoteMetadataHistoryState } from '../core/model/OpTypes';
import {
  OriginalNoteMetadataPatch, encodeOriginalSetMetadataFields,
} from './OriginalSetMetadataPayloadEncoder';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_STRING_BYTES,
} from './BinaryOpCodec';

// NMD1 is a Harmony history companion, not an original wire operation.  The
// original SET_METADATA envelope remains the source of truth; this payload
// only records the reversible editor mutation and the fields it touched.
const MAGIC: number[] = [0x4E, 0x4D, 0x44, 0x31];

export const NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE: number = 1;
export const NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES: number = 2;
export const NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY: number = 4;
export const NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE: number = 8;
export const NOTE_METADATA_FIELD_LAYOUT_MODE: number = 16;
export const NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT: number = 32;
export const NOTE_METADATA_FIELD_ALL: number = 63;

export type NoteMetadataMutationState = NoteMetadataHistoryState;

export interface NoteMetadataMutation {
  fromRevision: number;
  toRevision: number;
  selectedPageId: string;
  fieldMask: number;
  before: NoteMetadataMutationState;
  after: NoteMetadataMutationState;
}

export function emptyNoteMetadataMutationState(): NoteMetadataMutationState {
  return {
    handwritingLanguage: null,
    alignTextToLines: null,
    defaultFontFamily: null,
    defaultFontSize: null,
    layoutMode: null,
    blockWrapSupport: null,
  };
}

export function cloneNoteMetadataMutationState(state: NoteMetadataMutationState): NoteMetadataMutationState {
  return {
    handwritingLanguage: state.handwritingLanguage,
    alignTextToLines: state.alignTextToLines,
    defaultFontFamily: state.defaultFontFamily,
    defaultFontSize: state.defaultFontSize,
    layoutMode: state.layoutMode,
    blockWrapSupport: state.blockWrapSupport,
  };
}

export function encodeNoteMetadataMutation(mutation: NoteMetadataMutation): Uint8Array {
  validateNoteMetadataMutation(mutation);
  const selectedPageId: Uint8Array = encodeOperationString(
    mutation.selectedPageId, 'note metadata selected page ID');
  const before: Uint8Array = encodeState(mutation.before, mutation.fieldMask, 'before');
  const after: Uint8Array = encodeState(mutation.after, mutation.fieldMask, 'after');
  const size: number = MAGIC.length + 16 + 4 + selectedPageId.length + 1 +
    4 + before.length + 4 + after.length;
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(selectedPageId);
  writer.writeByte(mutation.fieldMask);
  writer.writeSizedBytes(before);
  writer.writeSizedBytes(after);
  return writer.finish();
}

export function decodeNoteMetadataMutation(bytes: Uint8Array): NoteMetadataMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: NoteMetadataMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    selectedPageId: reader.readString(),
    fieldMask: reader.readByte(),
    before: decodeState(reader.readSizedBytes(MAX_OPERATION_STRING_BYTES), 'before'),
    after: decodeState(reader.readSizedBytes(MAX_OPERATION_STRING_BYTES), 'after'),
  };
  if (!reader.atEnd()) {
    throw new Error('note metadata mutation has trailing bytes');
  }
  validateNoteMetadataMutation(mutation);
  return mutation;
}

export function validateNoteMetadataMutation(mutation: NoteMetadataMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    mutation.fromRevision >= Number.MAX_SAFE_INTEGER ||
    mutation.toRevision !== mutation.fromRevision + 1 ||
    mutation.selectedPageId.length < 1 || mutation.selectedPageId.length > 512) {
    throw new Error('note metadata mutation identity is invalid');
  }
  validateFieldMask(mutation.fieldMask);
  validateNoteMetadataMutationState(mutation.before, mutation.fieldMask, 'before');
  validateNoteMetadataMutationState(mutation.after, mutation.fieldMask, 'after');
  if (sameNoteMetadataMutationState(mutation.before, mutation.after, mutation.fieldMask)) {
    throw new Error('note metadata mutation does not change a touched register');
  }
}

export function validateNoteMetadataMutationState(state: NoteMetadataMutationState,
  fieldMask: number, label: string): void {
  validateState(state, fieldMask, label);
  try {
    // A durable history state is useful only if the production local writer can
    // encode it again. This also enforces its UTF-8 round-trip and byte budgets
    // before an irreversible original operation identity is allocated.
    encodeOriginalSetMetadataFields(patchFromValidatedState(state, fieldMask));
  } catch (_error) {
    throw new Error(`note metadata ${label} state cannot be restored on original wire`);
  }
}

export function sameNoteMetadataMutationState(left: NoteMetadataMutationState,
  right: NoteMetadataMutationState, fieldMask: number): boolean {
  validateFieldMask(fieldMask);
  if ((fieldMask & NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE) !== 0 &&
    left.handwritingLanguage !== right.handwritingLanguage) {
    return false;
  }
  if ((fieldMask & NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES) !== 0 &&
    left.alignTextToLines !== right.alignTextToLines) {
    return false;
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY) !== 0 &&
    left.defaultFontFamily !== right.defaultFontFamily) {
    return false;
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE) !== 0 &&
    left.defaultFontSize !== right.defaultFontSize) {
    return false;
  }
  if ((fieldMask & NOTE_METADATA_FIELD_LAYOUT_MODE) !== 0 &&
    left.layoutMode !== right.layoutMode) {
    return false;
  }
  if ((fieldMask & NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT) !== 0 &&
    left.blockWrapSupport !== right.blockWrapSupport) {
    return false;
  }
  return true;
}

// Convert a history target back into the production local SET_METADATA patch.
// A missing ordinary winner is deliberately rejected: deleting an LWW row is
// not an inverse operation, and the original scalar writer has no absent-winner
// representation.  Callers must keep such a mutation non-undoable instead.
export function patchFromNoteMetadataState(state: NoteMetadataMutationState,
  fieldMask: number): OriginalNoteMetadataPatch {
  validateNoteMetadataMutationState(state, fieldMask, 'target');
  return patchFromValidatedState(state, fieldMask);
}

function patchFromValidatedState(state: NoteMetadataMutationState,
  fieldMask: number): OriginalNoteMetadataPatch {
  const handwriting: string | null = state.handwritingLanguage;
  const align: boolean | null = state.alignTextToLines;
  const family: string | null = state.defaultFontFamily;
  const size: number | null = state.defaultFontSize;
  const layout: number | null = state.layoutMode;
  const wrap: number | null = state.blockWrapSupport;
  return {
    hasHandwritingLanguage: (fieldMask & NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE) !== 0,
    handwritingLanguage: handwriting,
    hasAlignTextToLines: (fieldMask & NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES) !== 0,
    alignTextToLines: align === null ? false : align,
    hasDefaultFontFamily: (fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY) !== 0,
    defaultFontFamily: family === null ? '' : family,
    hasDefaultFontSize: (fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE) !== 0,
    defaultFontSize: size === null ? 1 : size,
    hasLayoutMode: (fieldMask & NOTE_METADATA_FIELD_LAYOUT_MODE) !== 0,
    layoutMode: layout === null ? OriginalNoteLayoutMode.PAGED : layout as OriginalNoteLayoutMode,
    hasBlockWrapSupport: (fieldMask & NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT) !== 0,
    blockWrapSupport: wrap === null ? OriginalNoteBlockWrapSupport.WRAP_ENABLED :
      wrap as OriginalNoteBlockWrapSupport,
  };
}

function encodeState(state: NoteMetadataMutationState, fieldMask: number,
  label: string): Uint8Array {
  validateState(state, fieldMask, label);
  return encodeOperationString(JSON.stringify(state), `note metadata ${label} state`);
}

function decodeState(bytes: Uint8Array, label: string): NoteMetadataMutationState {
  const wrapped: Uint8Array = new Uint8Array(4 + bytes.length);
  wrapped[0] = bytes.length & 0xFF;
  wrapped[1] = bytes.length >>> 8 & 0xFF;
  wrapped[2] = bytes.length >>> 16 & 0xFF;
  wrapped[3] = bytes.length >>> 24 & 0xFF;
  wrapped.set(bytes, 4);
  const wrappedReader: BinaryOpReader = new BinaryOpReader(wrapped);
  const encoded: string = wrappedReader.readString();
  if (!wrappedReader.atEnd()) {
    throw new Error(`note metadata ${label} state has trailing bytes`);
  }
  try {
    const parsed: Object = JSON.parse(encoded) as Object;
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('state is not an object');
    }
    const raw: Record<string, Object> = parsed as Record<string, Object>;
    const fields: string[] = [
      'handwritingLanguage', 'alignTextToLines', 'defaultFontFamily',
      'defaultFontSize', 'layoutMode', 'blockWrapSupport',
    ];
    const keys: string[] = Object.keys(raw);
    if (keys.length !== fields.length) {
      throw new Error('state field count is invalid');
    }
    for (const key of fields) {
      if (!keys.includes(key)) {
        throw new Error('state field is missing');
      }
    }
    return {
      handwritingLanguage: raw.handwritingLanguage as string | null,
      alignTextToLines: raw.alignTextToLines as boolean | null,
      defaultFontFamily: raw.defaultFontFamily as string | null,
      defaultFontSize: raw.defaultFontSize as number | null,
      layoutMode: raw.layoutMode as number | null,
      blockWrapSupport: raw.blockWrapSupport as number | null,
    };
  } catch (_error) {
    throw new Error(`note metadata ${label} state is malformed`);
  }
}

function validateState(state: NoteMetadataMutationState, fieldMask: number,
  label: string): void {
  validateFieldMask(fieldMask);
  if (state === null || state === undefined) {
    throw new Error(`note metadata ${label} state is missing`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE) !== 0) {
    if (state.handwritingLanguage !== null && typeof state.handwritingLanguage !== 'string') {
      throw new Error(`note metadata ${label} handwriting language is invalid`);
    }
    if (!isOriginalHandwritingLanguage(state.handwritingLanguage)) {
      throw new Error(`note metadata ${label} handwriting language is invalid`);
    }
  } else if (state.handwritingLanguage !== null) {
    throw new Error(`note metadata ${label} has an untouched handwriting field`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES) !== 0) {
    if (state.alignTextToLines === null || typeof state.alignTextToLines !== 'boolean') {
      throw new Error(`note metadata ${label} align-to-lines value is invalid`);
    }
  } else if (state.alignTextToLines !== null) {
    throw new Error(`note metadata ${label} has an untouched align field`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY) !== 0) {
    if (state.defaultFontFamily === null || typeof state.defaultFontFamily !== 'string' ||
      !isOriginalDefaultFontFamily(state.defaultFontFamily)) {
      throw new Error(`note metadata ${label} default font family is invalid`);
    }
  } else if (state.defaultFontFamily !== null) {
    throw new Error(`note metadata ${label} has an untouched font family field`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE) !== 0) {
    if (state.defaultFontSize === null || typeof state.defaultFontSize !== 'number' ||
      !isOriginalDefaultFontSize(state.defaultFontSize)) {
      throw new Error(`note metadata ${label} default font size is invalid`);
    }
  } else if (state.defaultFontSize !== null) {
    throw new Error(`note metadata ${label} has an untouched font size field`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_LAYOUT_MODE) !== 0) {
    if (state.layoutMode === null || typeof state.layoutMode !== 'number' ||
      !isOriginalNoteLayoutMode(state.layoutMode)) {
      throw new Error(`note metadata ${label} layout mode is invalid`);
    }
  } else if (state.layoutMode !== null) {
    throw new Error(`note metadata ${label} has an untouched layout field`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT) !== 0) {
    if (state.blockWrapSupport === null || typeof state.blockWrapSupport !== 'number' ||
      !isOriginalNoteBlockWrapSupport(state.blockWrapSupport)) {
      throw new Error(`note metadata ${label} block-wrap value is invalid`);
    }
  } else if (state.blockWrapSupport !== null) {
    throw new Error(`note metadata ${label} has an untouched block-wrap field`);
  }
}

function validateFieldMask(fieldMask: number): void {
  if (!Number.isSafeInteger(fieldMask) || fieldMask <= 0 ||
    (fieldMask & ~NOTE_METADATA_FIELD_ALL) !== 0) {
    throw new Error('note metadata touched-field mask is invalid');
  }
}
