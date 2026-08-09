export const MAX_OPERATION_TIMESTAMP: number = 0xFFFFFFFF;
export const MAX_EDITOR_SITE_ID: number = 0xFFFF;

export interface OperationIdentity {
  timestamp: number;
  siteId: number;
}

export interface OriginalSequenceIdentity extends OperationIdentity {
  index: number;
}

export function validateOperationIdentity(identity: OperationIdentity): void {
  if (!Number.isSafeInteger(identity.timestamp) || identity.timestamp < 0 ||
    identity.timestamp > MAX_OPERATION_TIMESTAMP || !Number.isSafeInteger(identity.siteId) ||
    identity.siteId < 0 || identity.siteId > MAX_EDITOR_SITE_ID) {
    throw new Error('operation identity is outside the original unsigned clock range');
  }
}

export function nextOperationTimestamp(current: number): number {
  if (!Number.isSafeInteger(current) || current < 0 || current >= MAX_OPERATION_TIMESTAMP) {
    throw new Error('operation timestamp is invalid or exhausted');
  }
  return current + 1;
}

// The original packs timestamp/site into a 64-bit integer. Keep the components split in
// ArkTS so JavaScript number precision cannot corrupt the identity.
export function encodeOperationId(identity: OperationIdentity): string {
  validateOperationIdentity(identity);
  return `op:${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
}

export function validateOriginalSequenceIdentity(identity: OriginalSequenceIdentity): void {
  validateOperationIdentity(identity);
  if (!Number.isSafeInteger(identity.index) || identity.index < 0 || identity.index > MAX_OPERATION_TIMESTAMP) {
    throw new Error('sequence identity index is outside the original unsigned range');
  }
}

export function encodeOriginalSequenceId(identity: OriginalSequenceIdentity): string {
  validateOriginalSequenceIdentity(identity);
  return `seq:${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}:${identity.index.toString(16)}`;
}

export function encodeOriginalPageStorageId(noteId: string, identity: OriginalSequenceIdentity): string {
  if (noteId.length === 0) {
    throw new Error('original page storage ID requires a note ID');
  }
  return `original-page:${noteId.length}:${noteId}:${encodeOriginalSequenceId(identity)}`;
}

// exc.A0 in the original compares the signed int timestamp first, unsigned site second,
// and the sequence index in reverse. Keep Java int overflow semantics for byte fidelity.
export function compareOriginalSequenceIdentity(left: OriginalSequenceIdentity,
  right: OriginalSequenceIdentity): number {
  validateOriginalSequenceIdentity(left);
  validateOriginalSequenceIdentity(right);
  const timestampDifference: number = (toJavaInt(left.timestamp) - toJavaInt(right.timestamp)) | 0;
  if (timestampDifference !== 0) {
    return timestampDifference < 0 ? -1 : 1;
  }
  if (left.siteId !== right.siteId) {
    return left.siteId < right.siteId ? -1 : 1;
  }
  const indexDifference: number = (toJavaInt(right.index) - toJavaInt(left.index)) | 0;
  return indexDifference === 0 ? 0 : indexDifference < 0 ? -1 : 1;
}

function toJavaInt(value: number): number {
  return value >= 0x80000000 ? value - 0x100000000 : value;
}

export function compareOperationIdentity(left: OperationIdentity, right: OperationIdentity): number {
  validateOperationIdentity(left);
  validateOperationIdentity(right);
  if (left.timestamp !== right.timestamp) {
    return left.timestamp < right.timestamp ? -1 : 1;
  }
  if (left.siteId === right.siteId) {
    return 0;
  }
  return left.siteId < right.siteId ? -1 : 1;
}
