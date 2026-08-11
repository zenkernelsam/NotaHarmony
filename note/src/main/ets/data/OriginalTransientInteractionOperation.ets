import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';

export const ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE: number = 26;

export interface OriginalTransientInteractionEndedPayload {
  interactionId: OperationIdentity;
  replacedByOp: OperationIdentity | null;
}

export interface OriginalTransientInteractionMetadata {
  interactionId: OperationIdentity;
}

export function decodeOriginalTransientInteractionMetadata(
  root: OriginalFlatBufferTableReader): OriginalTransientInteractionMetadata | null {
  const table: OriginalFlatBufferTableReader | null = root.readTable(6);
  if (table === null) {
    return null;
  }
  // sdf.timeout is rejected by the original validator because it is currently unused.
  if (table.hasField(1)) {
    throw new Error('original transient interaction timeout is unsupported');
  }
  rejectFieldsFrom(table, 2, 'original transient interaction metadata');
  return { interactionId: readRequiredIdentity(table, 0, 'transient interaction metadata') };
}

export function decodeOriginalTransientInteractionEnded(
  bytes: Uint8Array): OriginalTransientInteractionEndedPayload {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(bytes);
  rejectFieldsFrom(root, 7, 'original operation root');
  const metadata: OriginalTransientInteractionMetadata | null =
    decodeOriginalTransientInteractionMetadata(root);
  if (metadata === null) {
    throw new Error('TransientInteractionEnded has no transient metadata');
  }
  const table: OriginalFlatBufferTableReader =
    readOriginalPayloadTable(bytes, ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE);
  rejectFieldsFrom(table, 2, 'TransientInteractionEnded payload');
  const interactionId: OperationIdentity =
    readRequiredIdentity(table, 0, 'TransientInteractionEnded interactionId');
  const replacedByOp: OperationIdentity | null = readOptionalIdentity(table, 1);
  if (encodeOperationId(metadata.interactionId) !== encodeOperationId(interactionId)) {
    throw new Error('TransientInteractionEnded metadata and payload interaction IDs differ');
  }
  return { interactionId: interactionId, replacedByOp: replacedByOp };
}

// The original v69 reducer keeps these entries only in its in-memory interaction map.
// A process restart intentionally discards them instead of restoring stale previews.
export class OriginalTransientInteractionStore {
  private interactions: Map<string, Map<string, Set<string>>> =
    new Map<string, Map<string, Set<string>>>();

  recordPreview(noteId: string, interactionId: OperationIdentity,
    operationId: OperationIdentity): void {
    requireNoteId(noteId);
    const interactionKey: string = encodeOperationId(interactionId);
    let noteInteractions: Map<string, Set<string>> | undefined = this.interactions.get(noteId);
    if (noteInteractions === undefined) {
      noteInteractions = new Map<string, Set<string>>();
      this.interactions.set(noteId, noteInteractions);
    }
    let operations: Set<string> | undefined = noteInteractions.get(interactionKey);
    if (operations === undefined) {
      operations = new Set<string>();
      noteInteractions.set(interactionKey, operations);
    }
    operations.add(encodeOperationId(operationId));
  }

  endInteraction(noteId: string, interactionId: OperationIdentity): number {
    requireNoteId(noteId);
    const noteInteractions: Map<string, Set<string>> | undefined = this.interactions.get(noteId);
    if (noteInteractions === undefined) {
      return 0;
    }
    const interactionKey: string = encodeOperationId(interactionId);
    const operations: Set<string> | undefined = noteInteractions.get(interactionKey);
    if (operations === undefined) {
      return 0;
    }
    noteInteractions.delete(interactionKey);
    if (noteInteractions.size === 0) {
      this.interactions.delete(noteId);
    }
    return operations.size;
  }

  previewCount(noteId: string, interactionId: OperationIdentity): number {
    requireNoteId(noteId);
    return this.interactions.get(noteId)?.get(encodeOperationId(interactionId))?.size ?? 0;
  }
}

function readRequiredIdentity(table: OriginalFlatBufferTableReader, field: number,
  name: string): OperationIdentity {
  const identity: OperationIdentity | null = readOptionalIdentity(table, field);
  if (identity === null) {
    throw new Error(`${name} is missing`);
  }
  return identity;
}

function readOptionalIdentity(table: OriginalFlatBufferTableReader,
  field: number): OperationIdentity | null {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 8);
  if (bytes === null) {
    return null;
  }
  const identity: OperationIdentity = {
    timestamp: readU32(bytes, 4),
    siteId: readU16(bytes, 0),
  };
  validateOperationIdentity(identity);
  return identity;
}

function rejectFieldsFrom(table: OriginalFlatBufferTableReader, first: number,
  name: string): void {
  for (let field: number = first; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error(`${name} has an unknown field`);
    }
  }
}

function requireNoteId(noteId: string): void {
  if (noteId.length === 0) {
    throw new Error('transient interaction note id is invalid');
  }
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
}
