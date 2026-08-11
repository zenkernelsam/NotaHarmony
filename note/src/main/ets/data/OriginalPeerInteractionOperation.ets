import {
  encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  decodeOriginalTransientInteractionMetadata, OriginalTransientInteractionMetadata,
} from './OriginalTransientInteractionOperation';
import { IncomingSyncedOperation } from './SyncedOperationInbox';

export const ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE: number = 29;
const MAX_SELECTED_PEER_ENTITY_COUNT: number = 10000;

export enum OriginalPeerTool {
  POINTER = 0,
  PEN = 1,
  HIGHLIGHTER = 2,
  ERASER = 3,
}

export interface OriginalPeerPoint {
  x: number;
  y: number;
}

export interface OriginalPeerTextSelection {
  anchor: OriginalSequenceIdentity | null;
  focus: OriginalSequenceIdentity | null;
}

export interface OriginalPeerInteractionPayload {
  cursorPosition: OriginalPeerPoint | null;
  selectedEntities: OperationIdentity[];
  tool: OriginalPeerTool;
  textSelection: OriginalPeerTextSelection | null;
  recordingInProgress: boolean;
}

export interface OriginalPeerInteractionBatchResult {
  operationCount: number;
  updateCount: number;
  discardedCount: number;
}

export function decodeOriginalPeerInteraction(bytes: Uint8Array): OriginalPeerInteractionPayload {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(bytes);
  rejectFieldsFrom(root, 7, 'original operation root');
  const rootId: OperationIdentity = readRequiredIdentity(root, 0, 'peer operation id');
  const metadata: OriginalTransientInteractionMetadata | null =
    decodeOriginalTransientInteractionMetadata(root);
  if (metadata === null || encodeOperationId(metadata.interactionId) !== encodeOperationId(rootId)) {
    throw new Error('PeerInteraction has mismatched transient metadata');
  }
  return decodeOriginalPeerInteractionTable(
    readOriginalPayloadTable(bytes, ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE));
}

export function decodeOriginalPeerInteractionTable(
  table: OriginalFlatBufferTableReader): OriginalPeerInteractionPayload {
  if (table.hasField(1) || table.hasField(2)) {
    throw new Error('PeerInteraction uses unsupported reserved fields');
  }
  rejectFieldsFrom(table, 7, 'PeerInteraction payload');
  const cursorBytes: Uint8Array | null = table.readInlineBytes(0, 8);
  let cursorPosition: OriginalPeerPoint | null = null;
  if (cursorBytes !== null) {
    const x: number = readOriginalInlineFloat32(cursorBytes, 0);
    const y: number = readOriginalInlineFloat32(cursorBytes, 4);
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      throw new Error('PeerInteraction cursor is not finite');
    }
    cursorPosition = { x: x, y: y };
  }
  const selectedRows: number[][] =
    table.readInlineOperationIdentityVector(3, MAX_SELECTED_PEER_ENTITY_COUNT);
  const selectedEntities: OperationIdentity[] = [];
  const selectedKeys: Set<string> = new Set<string>();
  for (const row of selectedRows) {
    const identity: OperationIdentity = { timestamp: row[0], siteId: row[1] };
    validateOperationIdentity(identity);
    const key: string = encodeOperationId(identity);
    if (!selectedKeys.has(key)) {
      selectedKeys.add(key);
      selectedEntities.push(identity);
    }
  }
  const rawTool: number = table.readUint8(4, OriginalPeerTool.POINTER);
  // yda.n() maps unknown enum bytes to the first value, POINTER.
  const tool: OriginalPeerTool = rawTool <= OriginalPeerTool.ERASER ?
    rawTool as OriginalPeerTool : OriginalPeerTool.POINTER;
  const selectionTable: OriginalFlatBufferTableReader | null = table.readTable(5);
  const textSelection: OriginalPeerTextSelection | null = selectionTable === null ? null :
    decodeTextSelection(selectionTable);
  return {
    cursorPosition: cursorPosition,
    selectedEntities: selectedEntities,
    tool: tool,
    textSelection: textSelection,
    // yda.k() treats every non-zero byte as true.
    recordingInProgress: table.readUint8(6, 0) !== 0,
  };
}

// This is the pending interaction boundary used before collaboration presence supplies display
// names and colors. It intentionally has no database or process-restart restoration path.
export class OriginalPeerInteractionStore {
  private notes: Map<string, Map<number, OriginalPeerInteractionPayload>> =
    new Map<string, Map<number, OriginalPeerInteractionPayload>>();

  consume(noteId: string, siteId: number, payload: OriginalPeerInteractionPayload,
    localSiteId: number | null = null): boolean {
    requireNoteId(noteId);
    validateOperationIdentity({ timestamp: 0, siteId: siteId });
    if (localSiteId !== null) {
      validateOperationIdentity({ timestamp: 0, siteId: localSiteId });
      if (siteId === localSiteId) {
        return false;
      }
    }
    let peers: Map<number, OriginalPeerInteractionPayload> | undefined = this.notes.get(noteId);
    if (peers === undefined) {
      peers = new Map<number, OriginalPeerInteractionPayload>();
      this.notes.set(noteId, peers);
    }
    const previous: OriginalPeerInteractionPayload | undefined = peers.get(siteId);
    const snapshot: OriginalPeerInteractionPayload = copyPayload(payload);
    if (snapshot.cursorPosition === null && previous?.cursorPosition !== null &&
      previous?.cursorPosition !== undefined) {
      snapshot.cursorPosition = {
        x: previous.cursorPosition.x,
        y: previous.cursorPosition.y,
      };
    }
    peers.set(siteId, snapshot);
    return true;
  }

  read(noteId: string, siteId: number): OriginalPeerInteractionPayload | null {
    requireNoteId(noteId);
    validateOperationIdentity({ timestamp: 0, siteId: siteId });
    const payload: OriginalPeerInteractionPayload | undefined = this.notes.get(noteId)?.get(siteId);
    return payload === undefined ? null : copyPayload(payload);
  }

  clearNote(noteId: string): void {
    requireNoteId(noteId);
    this.notes.delete(noteId);
  }
}

export function consumeOriginalPeerInteractionBatch(noteId: string,
  operations: IncomingSyncedOperation[], store: OriginalPeerInteractionStore,
  localSiteId: number): OriginalPeerInteractionBatchResult {
  requireNoteId(noteId);
  validateOperationIdentity({ timestamp: 0, siteId: localSiteId });
  const lastBySite: Map<number, IncomingSyncedOperation> =
    new Map<number, IncomingSyncedOperation>();
  let operationCount: number = 0;
  for (const operation of operations) {
    if (operation.payloadType === ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE) {
      operationCount++;
      if (operation.siteId !== localSiteId) {
        lastBySite.set(operation.siteId, operation);
      }
    }
  }
  let updateCount: number = 0;
  let discardedCount: number = 0;
  lastBySite.forEach((operation: IncomingSyncedOperation, siteId: number): void => {
    try {
      const payload: OriginalPeerInteractionPayload =
        decodeOriginalPeerInteraction(operation.rawOperation);
      store.consume(noteId, siteId, payload, localSiteId);
      updateCount++;
    } catch (_error) {
      // mzc catches malformed peer interaction conversion and continues model replay.
      discardedCount++;
    }
  });
  return {
    operationCount: operationCount,
    updateCount: updateCount,
    discardedCount: discardedCount,
  };
}

function decodeTextSelection(table: OriginalFlatBufferTableReader): OriginalPeerTextSelection {
  rejectFieldsFrom(table, 2, 'PeerInteraction text selection');
  return {
    anchor: readOptionalSequenceIdentity(table, 0),
    focus: readOptionalSequenceIdentity(table, 1),
  };
}

function readOptionalSequenceIdentity(table: OriginalFlatBufferTableReader,
  field: number): OriginalSequenceIdentity | null {
  const row: number[] | null = table.readInlineSequence(field);
  if (row === null) {
    return null;
  }
  const identity: OriginalSequenceIdentity = {
    timestamp: row[0], siteId: row[1], index: row[2],
  };
  validateOriginalSequenceIdentity(identity);
  return identity;
}

function readRequiredIdentity(table: OriginalFlatBufferTableReader, field: number,
  name: string): OperationIdentity {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 8);
  if (bytes === null) {
    throw new Error(`${name} is missing`);
  }
  const identity: OperationIdentity = {
    timestamp: readU32(bytes, 4), siteId: readU16(bytes, 0),
  };
  validateOperationIdentity(identity);
  return identity;
}

function copyPayload(payload: OriginalPeerInteractionPayload): OriginalPeerInteractionPayload {
  return {
    cursorPosition: payload.cursorPosition === null ? null :
      { x: payload.cursorPosition.x, y: payload.cursorPosition.y },
    selectedEntities: payload.selectedEntities.map((identity: OperationIdentity): OperationIdentity =>
      ({ timestamp: identity.timestamp, siteId: identity.siteId })),
    tool: payload.tool,
    textSelection: payload.textSelection === null ? null : {
      anchor: copySequence(payload.textSelection.anchor),
      focus: copySequence(payload.textSelection.focus),
    },
    recordingInProgress: payload.recordingInProgress,
  };
}

function copySequence(identity: OriginalSequenceIdentity | null): OriginalSequenceIdentity | null {
  return identity === null ? null : {
    timestamp: identity.timestamp, siteId: identity.siteId, index: identity.index,
  };
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
    throw new Error('peer interaction note id is invalid');
  }
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
}
