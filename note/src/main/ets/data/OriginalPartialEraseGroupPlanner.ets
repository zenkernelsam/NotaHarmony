import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';
import { compareOperationIdentity, decodeOperationId } from './OperationIdentity';

const MAX_ORIGINAL_GROUP_MEMBERS: number = 10000;

export interface OriginalPartialEraseGroupReplacement {
  sourceId: string;
  remnantIds: string[];
}

export interface OriginalPartialEraseGroupPlan {
  beforeGroups: OriginalSelectionGroup[];
  afterGroups: OriginalSelectionGroup[];
  modifiedGroups: OriginalSelectionGroup[];
  emptyGroups: OriginalSelectionGroup[];
  groups: OriginalSelectionGroup[];
}

// Original wc mode 3 removes a source member and then appends all replacement Ink IDs.
// It does not insert remnants at the source member's previous list index.
export function planOriginalPartialEraseGroups(activeGroups: OriginalSelectionGroup[],
  replacements: OriginalPartialEraseGroupReplacement[]): OriginalPartialEraseGroupPlan {
  return planPartialEraseGroups(activeGroups, replacements, true);
}

// A failed original transaction falls back to local snapshot IDs such as
// `op:1:1#erase-0`. They are intentionally non-canonical, but Group identity and
// replacement consistency must still be checked for subsequent local erases.
export function planLocalPartialEraseGroups(activeGroups: OriginalSelectionGroup[],
  replacements: OriginalPartialEraseGroupReplacement[]): OriginalPartialEraseGroupPlan {
  return planPartialEraseGroups(activeGroups, replacements, false);
}

function planPartialEraseGroups(activeGroups: OriginalSelectionGroup[],
  replacements: OriginalPartialEraseGroupReplacement[],
  requireCanonicalMembers: boolean): OriginalPartialEraseGroupPlan {
  const groups: OriginalSelectionGroup[] =
    validateAndCloneGroupList(activeGroups, requireCanonicalMembers);
  const stableReplacements: OriginalPartialEraseGroupReplacement[] =
    validateAndCloneReplacements(replacements, groups);
  const byId: Map<string, OriginalSelectionGroup> = groupMap(groups);
  const parentByMember: Map<string, OriginalSelectionGroup> =
    highestIdentityParentByMember(groups);
  const beforeById: Map<string, OriginalSelectionGroup> =
    new Map<string, OriginalSelectionGroup>();
  const workingById: Map<string, OriginalSelectionGroup> =
    new Map<string, OriginalSelectionGroup>();
  const affectedOrder: string[] = [];

  for (const replacement of stableReplacements) {
    const parent: OriginalSelectionGroup | undefined = parentByMember.get(replacement.sourceId);
    if (parent === undefined) {
      continue;
    }
    const working: OriginalSelectionGroup = ensureWorkingGroup(
      parent.id, byId, beforeById, workingById, affectedOrder);
    working.members = withoutMember(working.members, replacement.sourceId);
    for (const remnantId of replacement.remnantIds) {
      if (contains(working.members, remnantId)) {
        throw new Error('partial erase remnant repeats a Group member');
      }
      working.members.push(remnantId);
    }
    if (working.members.length > MAX_ORIGINAL_GROUP_MEMBERS) {
      throw new Error('partial erase makes a Group too large');
    }
  }

  const emptyGroups: OriginalSelectionGroup[] = [];
  const deletedIds: Set<string> = new Set<string>();
  while (true) {
    const emptyId: string | null = firstEmptyAffectedGroup(affectedOrder, workingById);
    if (emptyId === null) {
      break;
    }
    const before: OriginalSelectionGroup | undefined = beforeById.get(emptyId);
    if (before === undefined) {
      throw new Error('partial erase empty Group lost its source state');
    }
    workingById.delete(emptyId);
    deletedIds.add(emptyId);
    emptyGroups.push(cloneGroup(before));

    const parent: OriginalSelectionGroup | undefined = parentByMember.get(emptyId);
    if (parent === undefined || deletedIds.has(parent.id)) {
      continue;
    }
    const workingParent: OriginalSelectionGroup = ensureWorkingGroup(
      parent.id, byId, beforeById, workingById, affectedOrder);
    workingParent.members = withoutMember(workingParent.members, emptyId);
  }

  const beforeGroups: OriginalSelectionGroup[] = [];
  const afterGroups: OriginalSelectionGroup[] = [];
  for (const groupId of affectedOrder) {
    const before: OriginalSelectionGroup | undefined = beforeById.get(groupId);
    if (before === undefined) {
      throw new Error('partial erase affected Group lost its before state');
    }
    beforeGroups.push(cloneGroup(before));
    const after: OriginalSelectionGroup | undefined = workingById.get(groupId);
    if (after !== undefined) {
      if (sameGroup(before, after)) {
        throw new Error('partial erase retained an unchanged affected Group');
      }
      afterGroups.push(cloneGroup(after));
    }
  }

  const finalGroups: OriginalSelectionGroup[] = [];
  for (const group of groups) {
    if (!beforeById.has(group.id)) {
      finalGroups.push(cloneGroup(group));
      continue;
    }
    const after: OriginalSelectionGroup | undefined = workingById.get(group.id);
    if (after !== undefined) {
      finalGroups.push(cloneGroup(after));
    }
  }
  return {
    beforeGroups: beforeGroups,
    afterGroups: afterGroups,
    modifiedGroups: afterGroups.map(cloneGroup),
    emptyGroups: emptyGroups,
    groups: finalGroups,
  };
}

export function replayOriginalPartialEraseGroups(currentGroups: OriginalSelectionGroup[],
  beforeGroups: OriginalSelectionGroup[], afterGroups: OriginalSelectionGroup[],
  forward: boolean): OriginalSelectionGroup[] | null {
  let current: OriginalSelectionGroup[];
  let before: OriginalSelectionGroup[];
  let after: OriginalSelectionGroup[];
  try {
    current = validateAndCloneGroupList(currentGroups, false);
    before = validateAndCloneGroupList(beforeGroups, false);
    after = validateAndCloneGroupList(afterGroups, false);
    validateAffectedRelation(before, after);
  } catch (_error) {
    return null;
  }
  const source: OriginalSelectionGroup[] = forward ? before : after;
  const target: OriginalSelectionGroup[] = forward ? after : before;
  const affected: Set<string> = new Set<string>();
  for (const group of before) {
    affected.add(group.id);
  }
  for (const group of after) {
    affected.add(group.id);
  }
  const currentById: Map<string, OriginalSelectionGroup> = groupMap(current);
  const sourceById: Map<string, OriginalSelectionGroup> = groupMap(source);
  for (const groupId of affected) {
    const actual: OriginalSelectionGroup | undefined = currentById.get(groupId);
    const expected: OriginalSelectionGroup | undefined = sourceById.get(groupId);
    if (expected === undefined ? actual !== undefined :
      actual === undefined || !sameGroup(actual, expected)) {
      return null;
    }
  }
  const result: OriginalSelectionGroup[] = current.filter(
    (group: OriginalSelectionGroup): boolean => !affected.has(group.id));
  for (const group of target) {
    result.push(cloneGroup(group));
  }
  result.sort(compareGroupIdentity);
  return result;
}

function validateAndCloneGroupList(groups: OriginalSelectionGroup[],
  requireCanonicalMembers: boolean): OriginalSelectionGroup[] {
  const result: OriginalSelectionGroup[] = [];
  const ids: Set<string> = new Set<string>();
  for (const group of groups) {
    const identity = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp || identity.siteId !== group.siteId ||
      group.members.length === 0 || group.members.length > MAX_ORIGINAL_GROUP_MEMBERS || ids.has(group.id)) {
      throw new Error('partial erase Group state is invalid');
    }
    ids.add(group.id);
    const memberIds: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (member.length === 0 || memberIds.has(member) ||
        (requireCanonicalMembers && decodeOperationId(member) === null)) {
        throw new Error('partial erase Group member is invalid');
      }
      memberIds.add(member);
    }
    result.push(cloneGroup(group));
  }
  return result;
}

function validateAndCloneReplacements(replacements: OriginalPartialEraseGroupReplacement[],
  groups: OriginalSelectionGroup[]): OriginalPartialEraseGroupReplacement[] {
  const groupIds: Set<string> = new Set<string>();
  for (const group of groups) {
    groupIds.add(group.id);
  }
  const sourceIds: Set<string> = new Set<string>();
  const remnantIds: Set<string> = new Set<string>();
  const result: OriginalPartialEraseGroupReplacement[] = [];
  for (const replacement of replacements) {
    if (replacement.sourceId.length === 0 || sourceIds.has(replacement.sourceId) ||
      remnantIds.has(replacement.sourceId) || groupIds.has(replacement.sourceId)) {
      throw new Error('partial erase Group replacement source is invalid');
    }
    sourceIds.add(replacement.sourceId);
    const remnants: string[] = [];
    for (const remnantId of replacement.remnantIds) {
      if (remnantId.length === 0 || sourceIds.has(remnantId) || remnantIds.has(remnantId) ||
        groupIds.has(remnantId)) {
        throw new Error('partial erase Group replacement remnant is invalid');
      }
      remnantIds.add(remnantId);
      remnants.push(remnantId);
    }
    result.push({ sourceId: replacement.sourceId, remnantIds: remnants });
  }
  return result;
}

function validateAffectedRelation(before: OriginalSelectionGroup[],
  after: OriginalSelectionGroup[]): void {
  if (before.length === 0 && after.length === 0) {
    return;
  }
  if (before.length === 0 || after.length > before.length) {
    throw new Error('partial erase affected Group relation is invalid');
  }
  const beforeById: Map<string, OriginalSelectionGroup> = groupMap(before);
  for (const group of after) {
    const source: OriginalSelectionGroup | undefined = beforeById.get(group.id);
    if (source === undefined || source.timestamp !== group.timestamp || source.siteId !== group.siteId ||
      sameGroup(source, group)) {
      throw new Error('partial erase affected Group target is invalid');
    }
  }
}

function highestIdentityParentByMember(groups: OriginalSelectionGroup[]):
  Map<string, OriginalSelectionGroup> {
  const result: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
  for (const group of groups) {
    for (const member of group.members) {
      const current: OriginalSelectionGroup | undefined = result.get(member);
      if (current === undefined || compareGroupIdentity(group, current) > 0) {
        result.set(member, group);
      }
    }
  }
  return result;
}

function ensureWorkingGroup(groupId: string, byId: Map<string, OriginalSelectionGroup>,
  beforeById: Map<string, OriginalSelectionGroup>, workingById: Map<string, OriginalSelectionGroup>,
  affectedOrder: string[]): OriginalSelectionGroup {
  const existing: OriginalSelectionGroup | undefined = workingById.get(groupId);
  if (existing !== undefined) {
    return existing;
  }
  const source: OriginalSelectionGroup | undefined = byId.get(groupId);
  if (source === undefined) {
    throw new Error('partial erase references a missing parent Group');
  }
  const before: OriginalSelectionGroup = cloneGroup(source);
  const working: OriginalSelectionGroup = cloneGroup(source);
  beforeById.set(groupId, before);
  workingById.set(groupId, working);
  affectedOrder.push(groupId);
  return working;
}

function firstEmptyAffectedGroup(order: string[],
  workingById: Map<string, OriginalSelectionGroup>): string | null {
  for (const groupId of order) {
    const group: OriginalSelectionGroup | undefined = workingById.get(groupId);
    if (group !== undefined && group.members.length === 0) {
      return groupId;
    }
  }
  return null;
}

function withoutMember(members: string[], removed: string): string[] {
  return members.filter((member: string): boolean => member !== removed);
}

function contains(values: string[], value: string): boolean {
  return values.indexOf(value) >= 0;
}

function groupMap(groups: OriginalSelectionGroup[]): Map<string, OriginalSelectionGroup> {
  const result: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
  for (const group of groups) {
    if (result.has(group.id)) {
      throw new Error('partial erase repeats a Group identity');
    }
    result.set(group.id, group);
  }
  return result;
}

function compareGroupIdentity(left: OriginalSelectionGroup,
  right: OriginalSelectionGroup): number {
  return compareOperationIdentity({
    timestamp: left.timestamp,
    siteId: left.siteId,
  }, {
    timestamp: right.timestamp,
    siteId: right.siteId,
  });
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

function cloneGroup(group: OriginalSelectionGroup): OriginalSelectionGroup {
  return {
    id: group.id,
    timestamp: group.timestamp,
    siteId: group.siteId,
    members: group.members.slice(),
  };
}
