export const MAX_OPERATION_TIMESTAMP: number = 0xFFFFFFFF;
export const MAX_EDITOR_SITE_ID: number = 0xFFFF;

export interface OperationIdentity {
  timestamp: number;
  siteId: number;
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
