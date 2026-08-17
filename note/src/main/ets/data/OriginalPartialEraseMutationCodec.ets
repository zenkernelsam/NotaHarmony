import { OpType } from '../core/model/OpTypes';
import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';
import { PageElementKind } from '../core/model/PageElementOrder';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS,
} from './BinaryOpCodec';
import { MAX_ORIGINAL_DELETE_ENTITY_COUNT } from './OriginalDeleteEntitiesOperation';
import { decodeOperationId } from './OperationIdentity';
import {
  OriginalPartialEraseGroupPlan, OriginalPartialEraseGroupReplacement,
  planOriginalPartialEraseGroups,
} from './OriginalPartialEraseGroupPlanner';
import {
  classifyPageMutation, decodePageMutationOp, encodePageMutationOp, PageMutationOpPayload,
} from './PageMutationOpCodec';

const MAGIC: number[] = [0x4E, 0x50, 0x45, 0x32]; // NPE2
const LEGACY_PAGE_MAGIC: number[] = [0x4E, 0x50, 0x4D, 0x31]; // NPM1
const MAX_ORIGINAL_GROUP_MEMBERS: number = 10000;

export interface OriginalPartialEraseMutation {
  pageMutation: PageMutationOpPayload;
  replacements: OriginalPartialEraseGroupReplacement[];
  beforeGroups: OriginalSelectionGroup[];
  afterGroups: OriginalSelectionGroup[];
}

interface EncodedGroup {
  value: OriginalSelectionGroup;
  id: Uint8Array;
  members: Uint8Array[];
}

interface EncodedReplacement {
  value: OriginalPartialEraseGroupReplacement;
  sourceId: Uint8Array;
  remnantIds: Uint8Array[];
}

export function encodeOriginalPartialEraseMutation(
  mutation: OriginalPartialEraseMutation): Uint8Array {
  validateOriginalPartialEraseMutation(mutation);
  if (mutation.beforeGroups.length === 0 && mutation.afterGroups.length === 0 &&
    mutation.replacements.length === 0) {
    // Keep Phase 237 ungrouped history byte-compatible with its NPM1 payload.
    return encodePageMutationOp(mutation.pageMutation);
  }
  const pageMutation: Uint8Array = encodePageMutationOp(mutation.pageMutation);
  const beforeGroups: EncodedGroup[] = encodeGroups(mutation.beforeGroups);
  const afterGroups: EncodedGroup[] = encodeGroups(mutation.afterGroups);
  const replacements: EncodedReplacement[] = encodeReplacements(mutation.replacements);
  const size: number = MAGIC.length + 4 + pageMutation.length +
    encodedReplacementsSize(replacements) +
    encodedGroupsSize(beforeGroups) + encodedGroupsSize(afterGroups);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('original partial erase mutation exceeds operation byte budget');
  }
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageMutation);
  writeReplacements(writer, replacements);
  writeGroups(writer, beforeGroups);
  writeGroups(writer, afterGroups);
  return writer.finish();
}

export function decodeOriginalPartialEraseMutation(
  bytes: Uint8Array): OriginalPartialEraseMutation {
  let mutation: OriginalPartialEraseMutation;
  if (hasMagic(bytes, LEGACY_PAGE_MAGIC)) {
    mutation = {
      pageMutation: decodePageMutationOp(bytes), replacements: [], beforeGroups: [], afterGroups: [],
    };
  } else {
    const reader: BinaryOpReader = new BinaryOpReader(bytes);
    reader.readMagic(MAGIC);
    mutation = {
      pageMutation: decodePageMutationOp(reader.readSizedBytes(MAX_OPERATION_BYTES)),
      replacements: readReplacements(reader),
      beforeGroups: readGroups(reader),
      afterGroups: readGroups(reader),
    };
    if (!reader.atEnd()) {
      throw new Error('original partial erase mutation has trailing bytes');
    }
  }
  validateOriginalPartialEraseMutation(mutation);
  return mutation;
}

export function validateOriginalPartialEraseMutation(
  mutation: OriginalPartialEraseMutation): void {
  const pageMutation: PageMutationOpPayload = mutation.pageMutation;
  if (pageMutation.beforeElements.length === 0) {
    throw new Error('original partial erase must replace or delete at least one Ink');
  }
  const type: OpType = classifyPageMutation(pageMutation);
  if (type !== OpType.REPLACE_ELEMENTS && type !== OpType.DELETE_ELEMENTS) {
    throw new Error('original partial erase must replace or delete at least one Ink');
  }
  const beforeIds: Set<string> = new Set<string>();
  for (const element of pageMutation.beforeElements) {
    if ((element.kind !== PageElementKind.STROKE && element.kind !== PageElementKind.SHAPE) ||
      decodeOperationId(element.elementId) === null ||
      beforeIds.has(element.elementId)) {
      throw new Error('original partial erase has an invalid source entity identity');
    }
    beforeIds.add(element.elementId);
  }
  const afterIds: Set<string> = new Set<string>();
  for (const element of pageMutation.afterElements) {
    if (element.kind !== PageElementKind.STROKE || decodeOperationId(element.elementId) === null ||
      beforeIds.has(element.elementId) || afterIds.has(element.elementId)) {
      throw new Error('original partial erase has an invalid remnant Ink identity');
    }
    afterIds.add(element.elementId);
  }
  const beforeOrder: Set<string> = new Set<string>();
  for (const ref of pageMutation.beforeOrder) {
    beforeOrder.add(ref.elementId);
  }
  const afterOrder: Set<string> = new Set<string>();
  for (const ref of pageMutation.afterOrder) {
    afterOrder.add(ref.elementId);
  }
  for (const element of pageMutation.beforeElements) {
    if (!beforeOrder.has(element.elementId) || afterOrder.has(element.elementId)) {
      throw new Error('original partial erase did not remove a source entity');
    }
  }
  afterIds.forEach((id: string): void => {
    if (beforeOrder.has(id) || !afterOrder.has(id)) {
      throw new Error('original partial erase did not insert a remnant Ink');
    }
  });

  const beforeGroups: Map<string, OriginalSelectionGroup> = validateGroups(
    mutation.beforeGroups, 'before');
  const afterGroups: Map<string, OriginalSelectionGroup> = validateGroups(
    mutation.afterGroups, 'after');
  validateReplacements(mutation.replacements, beforeIds, afterIds);
  if (beforeGroups.size === 0 && afterGroups.size > 0) {
    throw new Error('original partial erase cannot create Groups');
  }
  if (afterGroups.size > beforeGroups.size) {
    throw new Error('original partial erase cannot add affected Groups');
  }
  let deletedGroupCount: number = 0;
  beforeGroups.forEach((before: OriginalSelectionGroup, id: string): void => {
    if (beforeOrder.has(id) || afterOrder.has(id)) {
      throw new Error('original partial erase Group collides with a page entity identity');
    }
    const after: OriginalSelectionGroup | undefined = afterGroups.get(id);
    if (after === undefined) {
      deletedGroupCount++;
      return;
    }
    if (before.timestamp !== after.timestamp || before.siteId !== after.siteId ||
      sameGroup(before, after)) {
      throw new Error('original partial erase has an invalid modified Group');
    }
  });
  afterGroups.forEach((_after: OriginalSelectionGroup, id: string): void => {
    if (!beforeGroups.has(id) || beforeOrder.has(id) || afterOrder.has(id)) {
      throw new Error('original partial erase has an invalid target Group');
    }
  });
  if (beforeGroups.size === 0) {
    if (mutation.replacements.length !== 0) {
      throw new Error('ungrouped original partial erase must use legacy page history');
    }
  } else {
    if (mutation.replacements.length === 0) {
      throw new Error('grouped original partial erase lost its replacement mapping');
    }
    let planned: OriginalPartialEraseGroupPlan;
    try {
      planned = planOriginalPartialEraseGroups(
        mutation.beforeGroups, mutation.replacements);
    } catch (_error) {
      throw new Error('original partial erase Group replacement plan is invalid');
    }
    if (!sameGroups(planned.beforeGroups, mutation.beforeGroups) ||
      !sameGroups(planned.afterGroups, mutation.afterGroups)) {
      throw new Error('original partial erase Group snapshots contradict replacement mapping');
    }
  }
  if (pageMutation.beforeElements.length + pageMutation.afterElements.length + deletedGroupCount >
    MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original partial erase must fit one type-25 visibility payload');
  }
}

function validateReplacements(replacements: OriginalPartialEraseGroupReplacement[],
  beforeIds: Set<string>, afterIds: Set<string>): void {
  if (replacements.length > MAX_OPERATION_ELEMENTS) {
    throw new Error('original partial erase replacement mapping exceeds operation budget');
  }
  const sources: Set<string> = new Set<string>();
  const remnants: Set<string> = new Set<string>();
  for (const replacement of replacements) {
    if (!beforeIds.has(replacement.sourceId) || sources.has(replacement.sourceId) ||
      remnants.has(replacement.sourceId)) {
      throw new Error('original partial erase replacement source is invalid');
    }
    sources.add(replacement.sourceId);
    for (const remnantId of replacement.remnantIds) {
      if (!afterIds.has(remnantId) || sources.has(remnantId) || remnants.has(remnantId)) {
        throw new Error('original partial erase replacement remnant is invalid');
      }
      remnants.add(remnantId);
    }
  }
  if (replacements.length > 0 &&
    (sources.size !== beforeIds.size || remnants.size !== afterIds.size)) {
    throw new Error('original partial erase replacement mapping is incomplete');
  }
}

function validateGroups(groups: OriginalSelectionGroup[], label: string):
  Map<string, OriginalSelectionGroup> {
  if (groups.length > MAX_OPERATION_ELEMENTS) {
    throw new Error(`original partial erase ${label} Group count is invalid`);
  }
  const result: Map<string, OriginalSelectionGroup> =
    new Map<string, OriginalSelectionGroup>();
  for (const group of groups) {
    const identity = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp || identity.siteId !== group.siteId ||
      group.members.length === 0 || group.members.length > MAX_ORIGINAL_GROUP_MEMBERS ||
      result.has(group.id)) {
      throw new Error(`original partial erase ${label} Group is invalid`);
    }
    const members: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (decodeOperationId(member) === null || members.has(member)) {
        throw new Error(`original partial erase ${label} Group member is invalid`);
      }
      members.add(member);
    }
    result.set(group.id, group);
  }
  return result;
}

function encodeReplacements(replacements: OriginalPartialEraseGroupReplacement[]):
  EncodedReplacement[] {
  return replacements.map(
    (replacement: OriginalPartialEraseGroupReplacement): EncodedReplacement => ({
      value: replacement,
      sourceId: encodeOperationString(
        replacement.sourceId, 'original partial erase replacement source ID'),
      remnantIds: replacement.remnantIds.map((id: string): Uint8Array =>
        encodeOperationString(id, 'original partial erase replacement remnant ID')),
    }));
}

function encodedReplacementsSize(replacements: EncodedReplacement[]): number {
  let size: number = 4;
  for (const replacement of replacements) {
    size += 4 + replacement.sourceId.length + 4;
    for (const remnantId of replacement.remnantIds) {
      size += 4 + remnantId.length;
    }
  }
  return size;
}

function writeReplacements(writer: BinaryOpWriter, replacements: EncodedReplacement[]): void {
  writer.writeUint32(replacements.length);
  for (const replacement of replacements) {
    writer.writeSizedBytes(replacement.sourceId);
    writer.writeUint32(replacement.remnantIds.length);
    for (const remnantId of replacement.remnantIds) {
      writer.writeSizedBytes(remnantId);
    }
  }
}

function readReplacements(reader: BinaryOpReader): OriginalPartialEraseGroupReplacement[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('original partial erase replacement count exceeds operation budget');
  }
  const replacements: OriginalPartialEraseGroupReplacement[] = [];
  for (let index: number = 0; index < count; index++) {
    const sourceId: string = reader.readString();
    const remnantCount: number = reader.readUint32();
    if (remnantCount > MAX_OPERATION_ELEMENTS) {
      throw new Error('original partial erase remnant count exceeds operation budget');
    }
    const remnantIds: string[] = [];
    for (let remnant: number = 0; remnant < remnantCount; remnant++) {
      remnantIds.push(reader.readString());
    }
    replacements.push({ sourceId: sourceId, remnantIds: remnantIds });
  }
  return replacements;
}

function encodeGroups(groups: OriginalSelectionGroup[]): EncodedGroup[] {
  return groups.map((group: OriginalSelectionGroup): EncodedGroup => ({
    value: group,
    id: encodeOperationString(group.id, 'original partial erase Group ID'),
    members: group.members.map((member: string): Uint8Array =>
      encodeOperationString(member, 'original partial erase Group member ID')),
  }));
}

function encodedGroupsSize(groups: EncodedGroup[]): number {
  let size: number = 4;
  for (const group of groups) {
    size += 4 + group.id.length + 4 + 4 + 4;
    for (const member of group.members) {
      size += 4 + member.length;
    }
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

function readGroups(reader: BinaryOpReader): OriginalSelectionGroup[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('original partial erase Group count exceeds operation budget');
  }
  const groups: OriginalSelectionGroup[] = [];
  for (let index: number = 0; index < count; index++) {
    const id: string = reader.readString();
    const timestamp: number = reader.readUint32();
    const siteId: number = reader.readUint32();
    const memberCount: number = reader.readUint32();
    if (memberCount === 0 || memberCount > MAX_ORIGINAL_GROUP_MEMBERS) {
      throw new Error('original partial erase Group member count is invalid');
    }
    const members: string[] = [];
    for (let member: number = 0; member < memberCount; member++) {
      members.push(reader.readString());
    }
    groups.push({ id: id, timestamp: timestamp, siteId: siteId, members: members });
  }
  return groups;
}

function hasMagic(bytes: Uint8Array, magic: number[]): boolean {
  if (bytes.length < magic.length) {
    return false;
  }
  for (let index: number = 0; index < magic.length; index++) {
    if (bytes[index] !== magic[index]) {
      return false;
    }
  }
  return true;
}

function sameGroups(left: OriginalSelectionGroup[], right: OriginalSelectionGroup[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (!sameGroup(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

function sameGroup(left: OriginalSelectionGroup, right: OriginalSelectionGroup): boolean {
  if (left.id !== right.id || left.timestamp !== right.timestamp || left.siteId !== right.siteId ||
    left.members.length !== right.members.length) {
    return false;
  }
  for (let index: number = 0; index < left.members.length; index++) {
    if (left.members[index] !== right.members[index]) {
      return false;
    }
  }
  return true;
}
