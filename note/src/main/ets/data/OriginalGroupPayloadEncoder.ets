import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';

const MAX_ORIGINAL_GROUP_MEMBERS: number = 10000;

export function encodeOriginalCreateGroup(members: OperationIdentity[]): Uint8Array {
  const targets: OperationIdentity[] = validateMembers(members);
  const table: number = 12;
  const vector: number = table + 8;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + targets.length * 8);
  writeU32(bytes, 0, table);
  writeU16(bytes, 4, 6);
  writeU16(bytes, 6, 8);
  writeU16(bytes, 8, 4);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  writeMembers(bytes, vector, targets);
  return bytes;
}

export function encodeOriginalModifyGroup(group: OperationIdentity,
  members: OperationIdentity[]): Uint8Array {
  validateOperationIdentity(group);
  const targets: OperationIdentity[] = validateMembers(members);
  const table: number = 12;
  const vector: number = table + 16;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + targets.length * 8);
  writeU32(bytes, 0, table);
  writeU16(bytes, 4, 8);
  writeU16(bytes, 6, 16);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU32(bytes, table, table - 4);
  writeU16(bytes, table + 4, group.siteId);
  writeU32(bytes, table + 8, group.timestamp);
  writeU32(bytes, table + 12, vector - (table + 12));
  writeMembers(bytes, vector, targets);
  return bytes;
}

function validateMembers(members: OperationIdentity[]): OperationIdentity[] {
  if (members.length === 0 || members.length > MAX_ORIGINAL_GROUP_MEMBERS) {
    throw new Error('original Group has an invalid member count');
  }
  const result: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const member of members) {
    validateOperationIdentity(member);
    const key: string = encodeOperationId(member);
    if (seen.has(key)) {
      throw new Error('original Group repeats a member');
    }
    seen.add(key);
    result.push({ timestamp: member.timestamp, siteId: member.siteId });
  }
  return result;
}

function writeMembers(bytes: Uint8Array, vector: number, members: OperationIdentity[]): void {
  writeU32(bytes, vector, members.length);
  for (let index: number = 0; index < members.length; index++) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, members[index].siteId);
    writeU32(bytes, offset + 4, members[index].timestamp);
  }
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
