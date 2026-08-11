import { OpType } from '../core/model/OpTypes';
import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS,
} from './BinaryOpCodec';
import { decodeOperationId } from './OperationIdentity';
import {
  classifyPageMutation, decodePageMutationOp, encodePageMutationOp, PageMutationOpPayload,
} from './PageMutationOpCodec';

const MAGIC: number[] = [0x4E, 0x43, 0x50, 0x31]; // NCP1
const MAX_ORIGINAL_GROUP_MEMBERS: number = 10000;

export interface OriginalClipboardPasteMutation {
  pageMutation: PageMutationOpPayload;
  groups: OriginalSelectionGroup[];
  topGroupIds: string[];
}

interface EncodedGroup {
  value: OriginalSelectionGroup;
  id: Uint8Array;
  members: Uint8Array[];
}

export function encodeOriginalClipboardPasteMutation(
  mutation: OriginalClipboardPasteMutation): Uint8Array {
  validateOriginalClipboardPasteMutation(mutation);
  const pageMutation: Uint8Array = encodePageMutationOp(mutation.pageMutation);
  const groups: EncodedGroup[] = mutation.groups.map(
    (group: OriginalSelectionGroup): EncodedGroup => ({
      value: group,
      id: encodeOperationString(group.id, 'clipboard Paste Group ID'),
      members: group.members.map((member: string): Uint8Array =>
        encodeOperationString(member, 'clipboard Paste Group member ID')),
    }));
  const topGroupIds: Uint8Array[] = mutation.topGroupIds.map((id: string): Uint8Array =>
    encodeOperationString(id, 'clipboard Paste top Group ID'));
  let size: number = MAGIC.length + 4 + pageMutation.length + 4 + 4;
  for (const group of groups) {
    size += 4 + group.id.length + 4 + 4 + 4;
    for (const member of group.members) {
      size += 4 + member.length;
    }
  }
  for (const id of topGroupIds) {
    size += 4 + id.length;
  }
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('clipboard Paste mutation exceeds operation byte budget');
  }
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageMutation);
  writer.writeUint32(groups.length);
  for (const group of groups) {
    writer.writeSizedBytes(group.id);
    writer.writeUint32(group.value.timestamp);
    writer.writeUint32(group.value.siteId);
    writer.writeUint32(group.members.length);
    for (const member of group.members) {
      writer.writeSizedBytes(member);
    }
  }
  writer.writeUint32(topGroupIds.length);
  for (const id of topGroupIds) {
    writer.writeSizedBytes(id);
  }
  return writer.finish();
}

export function decodeOriginalClipboardPasteMutation(
  bytes: Uint8Array): OriginalClipboardPasteMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const pageMutation: PageMutationOpPayload = decodePageMutationOp(
    reader.readSizedBytes(MAX_OPERATION_BYTES));
  const groupCount: number = reader.readUint32();
  if (groupCount === 0 || groupCount > MAX_OPERATION_ELEMENTS) {
    throw new Error('clipboard Paste mutation has an invalid Group count');
  }
  const groups: OriginalSelectionGroup[] = [];
  for (let index: number = 0; index < groupCount; index++) {
    const id: string = reader.readString();
    const timestamp: number = reader.readUint32();
    const siteId: number = reader.readUint32();
    const memberCount: number = reader.readUint32();
    if (memberCount === 0 || memberCount > MAX_ORIGINAL_GROUP_MEMBERS) {
      throw new Error('clipboard Paste mutation has an invalid Group member count');
    }
    const members: string[] = [];
    for (let member: number = 0; member < memberCount; member++) {
      members.push(reader.readString());
    }
    groups.push({ id: id, timestamp: timestamp, siteId: siteId, members: members });
  }
  const topCount: number = reader.readUint32();
  if (topCount === 0 || topCount > groupCount) {
    throw new Error('clipboard Paste mutation has an invalid top Group count');
  }
  const topGroupIds: string[] = [];
  for (let index: number = 0; index < topCount; index++) {
    topGroupIds.push(reader.readString());
  }
  if (!reader.atEnd()) {
    throw new Error('clipboard Paste mutation has trailing bytes');
  }
  const mutation: OriginalClipboardPasteMutation = {
    pageMutation: pageMutation,
    groups: groups,
    topGroupIds: topGroupIds,
  };
  validateOriginalClipboardPasteMutation(mutation);
  return mutation;
}

export function validateOriginalClipboardPasteMutation(
  mutation: OriginalClipboardPasteMutation): void {
  if (classifyPageMutation(mutation.pageMutation) !== OpType.INSERT_ELEMENTS ||
    mutation.pageMutation.afterElements.length === 0 || mutation.groups.length === 0 ||
    mutation.groups.length > MAX_OPERATION_ELEMENTS || mutation.topGroupIds.length === 0 ||
    mutation.topGroupIds.length > mutation.groups.length) {
    throw new Error('clipboard Paste mutation must insert entities and Groups');
  }

  const insertedIds: Set<string> = new Set<string>();
  for (const element of mutation.pageMutation.afterElements) {
    if (decodeOperationId(element.elementId) === null || insertedIds.has(element.elementId)) {
      throw new Error('clipboard Paste mutation has an invalid inserted entity identity');
    }
    insertedIds.add(element.elementId);
  }
  const pageEntityIds: Set<string> = new Set<string>();
  for (const ref of mutation.pageMutation.afterOrder) {
    if (pageEntityIds.has(ref.elementId)) {
      throw new Error('clipboard Paste mutation repeats an entity identity');
    }
    pageEntityIds.add(ref.elementId);
  }

  const availableMembers: Set<string> = new Set<string>();
  insertedIds.forEach((id: string): void => { availableMembers.add(id); });
  const groupIds: Set<string> = new Set<string>();
  const parentByMember: Map<string, string> = new Map<string, string>();
  let entryCount: number = mutation.pageMutation.beforeOrder.length +
    mutation.pageMutation.afterOrder.length + mutation.pageMutation.afterElements.length +
    mutation.groups.length + mutation.topGroupIds.length;
  for (const group of mutation.groups) {
    const identity = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp ||
      identity.siteId !== group.siteId || groupIds.has(group.id) ||
      pageEntityIds.has(group.id) || group.members.length === 0 ||
      group.members.length > MAX_ORIGINAL_GROUP_MEMBERS) {
      throw new Error('clipboard Paste mutation has an invalid Group identity');
    }
    const members: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (!availableMembers.has(member) || members.has(member) || parentByMember.has(member)) {
        throw new Error('clipboard Paste Group must reference unique earlier Paste members');
      }
      members.add(member);
      parentByMember.set(member, group.id);
    }
    entryCount += group.members.length;
    groupIds.add(group.id);
    availableMembers.add(group.id);
  }
  if (entryCount > MAX_OPERATION_ELEMENTS) {
    throw new Error('clipboard Paste mutation exceeds operation element budget');
  }

  const expectedRoots: Set<string> = new Set<string>();
  groupIds.forEach((id: string): void => {
    if (!parentByMember.has(id)) {
      expectedRoots.add(id);
    }
  });
  const actualRoots: Set<string> = new Set<string>();
  for (const id of mutation.topGroupIds) {
    if (decodeOperationId(id) === null || !expectedRoots.has(id) || actualRoots.has(id)) {
      throw new Error('clipboard Paste mutation has invalid top Groups');
    }
    actualRoots.add(id);
  }
  if (actualRoots.size !== expectedRoots.size) {
    throw new Error('clipboard Paste mutation omits a top Group');
  }
}
