import { PageElementRef, samePageElementMembers } from '../core/model/PageElementOrder';
import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS,
} from './BinaryOpCodec';
import { decodeOperationId } from './OperationIdentity';

const MAGIC: number[] = [0x4E, 0x47, 0x4D, 0x31]; // NGM1
const MAX_GROUPS_PER_MUTATION: number = 1;

export interface OriginalGroupMutationOpPayload {
  pageId: string;
  beforeGroups: OriginalSelectionGroup[];
  afterGroups: OriginalSelectionGroup[];
  elementOrderBefore: PageElementRef[];
  elementOrderAfter: PageElementRef[];
}

interface EncodedGroup {
  value: OriginalSelectionGroup;
  id: Uint8Array;
  members: Uint8Array[];
}

interface EncodedOrderRef { value: PageElementRef; id: Uint8Array; }

export function encodeOriginalGroupMutation(
  mutation: OriginalGroupMutationOpPayload): Uint8Array {
  validateOriginalGroupMutation(mutation);
  const pageId: Uint8Array = encodeOperationString(mutation.pageId, 'Group mutation page ID');
  const beforeGroups: EncodedGroup[] = encodeGroups(mutation.beforeGroups);
  const afterGroups: EncodedGroup[] = encodeGroups(mutation.afterGroups);
  const beforeOrder: EncodedOrderRef[] = encodeOrder(mutation.elementOrderBefore);
  const afterOrder: EncodedOrderRef[] = encodeOrder(mutation.elementOrderAfter);
  const size: number = MAGIC.length + 4 + pageId.length + groupSize(beforeGroups) +
    groupSize(afterGroups) + orderSize(beforeOrder) + orderSize(afterOrder);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('Group mutation exceeds operation budget');
  }
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageId);
  writeGroups(writer, beforeGroups);
  writeGroups(writer, afterGroups);
  writeOrder(writer, beforeOrder);
  writeOrder(writer, afterOrder);
  return writer.finish();
}

export function decodeOriginalGroupMutation(bytes: Uint8Array): OriginalGroupMutationOpPayload {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: OriginalGroupMutationOpPayload = {
    pageId: reader.readString(),
    beforeGroups: readGroups(reader),
    afterGroups: readGroups(reader),
    elementOrderBefore: readOrder(reader),
    elementOrderAfter: readOrder(reader),
  };
  if (!reader.atEnd()) {
    throw new Error('Group mutation has trailing bytes');
  }
  validateOriginalGroupMutation(mutation);
  return mutation;
}

export function validateOriginalGroupMutation(mutation: OriginalGroupMutationOpPayload): void {
  if (mutation.pageId.length === 0 || mutation.beforeGroups.length > MAX_GROUPS_PER_MUTATION ||
    mutation.afterGroups.length > MAX_GROUPS_PER_MUTATION ||
    mutation.beforeGroups.length + mutation.afterGroups.length === 0) {
    throw new Error('Group mutation identity is invalid');
  }
  validateGroups(mutation.beforeGroups);
  validateGroups(mutation.afterGroups);
  validateOrder(mutation.elementOrderBefore);
  validateOrder(mutation.elementOrderAfter);
  if (!samePageElementMembers(mutation.elementOrderBefore, mutation.elementOrderAfter)) {
    throw new Error('Group mutation changes page membership');
  }
  if (sameGroups(mutation.beforeGroups, mutation.afterGroups)) {
    throw new Error('Group mutation does not change Group state');
  }
}

export function sameOriginalSelectionGroups(left: OriginalSelectionGroup[],
  right: OriginalSelectionGroup[]): boolean {
  return sameGroups(left, right);
}

function validateGroups(groups: OriginalSelectionGroup[]): void {
  const seen: Set<string> = new Set<string>();
  for (const group of groups) {
    const identity = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp || identity.siteId !== group.siteId ||
      group.members.length === 0 || group.members.length > MAX_OPERATION_ELEMENTS || seen.has(group.id)) {
      throw new Error('Group mutation contains an invalid Group');
    }
    seen.add(group.id);
    const members: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (decodeOperationId(member) === null || members.has(member)) {
        throw new Error('Group mutation contains an invalid member');
      }
      members.add(member);
    }
  }
}

function validateOrder(order: PageElementRef[]): void {
  if (order.length > MAX_OPERATION_ELEMENTS) {
    throw new Error('Group mutation order exceeds element budget');
  }
  const seen: Set<string> = new Set<string>();
  for (let index: number = 0; index < order.length; index++) {
    const ref: PageElementRef = order[index];
    const key: string = `${ref.kind}:${ref.elementId}`;
    if (!Number.isSafeInteger(ref.kind) || ref.kind < 0 || ref.elementId.length === 0 ||
      ref.zIndex !== index || decodeOperationId(ref.elementId) === null || seen.has(key)) {
      throw new Error('Group mutation order is invalid');
    }
    seen.add(key);
  }
}

function encodeGroups(groups: OriginalSelectionGroup[]): EncodedGroup[] {
  return groups.map((group: OriginalSelectionGroup): EncodedGroup => ({
    value: group,
    id: encodeOperationString(group.id, 'Group mutation Group ID'),
    members: group.members.map((member: string): Uint8Array =>
      encodeOperationString(member, 'Group mutation member ID')),
  }));
}

function encodeOrder(order: PageElementRef[]): EncodedOrderRef[] {
  return order.map((ref: PageElementRef): EncodedOrderRef => ({
    value: ref, id: encodeOperationString(ref.elementId, 'Group mutation element ID'),
  }));
}

function groupSize(groups: EncodedGroup[]): number {
  let size: number = 4;
  for (const group of groups) {
    size += 4 + group.id.length + 4 + 4 + 4;
    for (const member of group.members) {
      size += 4 + member.length;
    }
  }
  return size;
}

function orderSize(order: EncodedOrderRef[]): number {
  let size: number = 4;
  for (const ref of order) {
    size += 4 + 4 + ref.id.length;
  }
  return size;
}

function writeGroups(writer: BinaryOpWriter, groups: EncodedGroup[]): void {
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
}

function writeOrder(writer: BinaryOpWriter, order: EncodedOrderRef[]): void {
  writer.writeUint32(order.length);
  for (const ref of order) {
    writer.writeUint32(ref.value.kind);
    writer.writeSizedBytes(ref.id);
  }
}

function readGroups(reader: BinaryOpReader): OriginalSelectionGroup[] {
  const count: number = reader.readUint32();
  if (count > MAX_GROUPS_PER_MUTATION) {
    throw new Error('Group mutation has too many Groups');
  }
  const groups: OriginalSelectionGroup[] = [];
  for (let index: number = 0; index < count; index++) {
    const id: string = reader.readString();
    const timestamp: number = reader.readUint32();
    const siteId: number = reader.readUint32();
    const memberCount: number = reader.readUint32();
    if (memberCount > MAX_OPERATION_ELEMENTS) {
      throw new Error('Group mutation has too many members');
    }
    const members: string[] = [];
    for (let member: number = 0; member < memberCount; member++) {
      members.push(reader.readString());
    }
    groups.push({ id: id, timestamp: timestamp, siteId: siteId, members: members });
  }
  return groups;
}

function readOrder(reader: BinaryOpReader): PageElementRef[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('Group mutation order exceeds element budget');
  }
  const order: PageElementRef[] = [];
  for (let index: number = 0; index < count; index++) {
    order.push({ kind: reader.readUint32(), elementId: reader.readString(), zIndex: index });
  }
  return order;
}

function sameGroups(left: OriginalSelectionGroup[], right: OriginalSelectionGroup[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index].id !== right[index].id || left[index].timestamp !== right[index].timestamp ||
      left[index].siteId !== right[index].siteId ||
      left[index].members.length !== right[index].members.length) {
      return false;
    }
    for (let member: number = 0; member < left[index].members.length; member++) {
      if (left[index].members[member] !== right[index].members[member]) {
        return false;
      }
    }
  }
  return true;
}
