export interface OriginalSelectionGroup {
  id: string;
  timestamp: number;
  siteId: number;
  members: string[];
}

export interface OriginalGroupSelectionResult {
  entityIds: string[];
  groupIds: string[];
}

interface GroupExpansion {
  valid: boolean;
  leaves: string[];
}

export function resolveOriginalGroupSelection(selectedIds: string[], availableIds: string[],
  groups: OriginalSelectionGroup[]): OriginalGroupSelectionResult {
  const available: Set<string> = new Set<string>(availableIds);
  const byId: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
  const parentByMember: Map<string, OriginalSelectionGroup> =
    new Map<string, OriginalSelectionGroup>();
  for (const group of groups) {
    if (group.id.length === 0 || group.members.length === 0) {
      continue;
    }
    byId.set(group.id, group);
    for (const member of group.members) {
      const current: OriginalSelectionGroup | undefined = parentByMember.get(member);
      if (current === undefined || compareGroupIdentity(group, current) > 0) {
        parentByMember.set(member, group);
      }
    }
  }

  const selected: Set<string> = new Set<string>();
  const selectedGroups: Set<string> = new Set<string>();
  const handledGroups: Set<string> = new Set<string>();
  for (const entityId of selectedIds) {
    if (!available.has(entityId)) {
      continue;
    }
    const top: OriginalSelectionGroup | null = topContainingGroup(entityId, parentByMember);
    if (top === null) {
      selected.add(entityId);
      continue;
    }
    if (handledGroups.has(top.id)) {
      continue;
    }
    const expansion: GroupExpansion = expandGroup(top.id, byId, available, new Set<string>());
    if (!expansion.valid || expansion.leaves.length === 0) {
      selected.add(entityId);
      continue;
    }
    handledGroups.add(top.id);
    selectedGroups.add(top.id);
    for (const leaf of expansion.leaves) {
      selected.add(leaf);
    }
  }
  return { entityIds: Array.from(selected), groupIds: Array.from(selectedGroups) };
}

export function resolveOriginalSelectedGroupLeaves(groupIds: string[], selectedEntityIds: string[],
  groups: OriginalSelectionGroup[]): string[] | null {
  if (groupIds.length === 0) {
    return [];
  }
  const available: Set<string> = new Set<string>(selectedEntityIds);
  const byId: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
  for (const group of groups) {
    if (group.id.length > 0 && group.members.length > 0 && !byId.has(group.id)) {
      byId.set(group.id, group);
    }
  }
  const leaves: string[] = [];
  const seenGroups: Set<string> = new Set<string>();
  const seenLeaves: Set<string> = new Set<string>();
  for (const groupId of groupIds) {
    if (seenGroups.has(groupId)) {
      return null;
    }
    seenGroups.add(groupId);
    const expansion: GroupExpansion = expandGroup(groupId, byId, available, new Set<string>());
    if (!expansion.valid || expansion.leaves.length === 0) {
      return null;
    }
    for (const leaf of expansion.leaves) {
      if (!seenLeaves.has(leaf)) {
        seenLeaves.add(leaf);
        leaves.push(leaf);
      }
    }
  }
  return leaves;
}

function topContainingGroup(entityId: string,
  parentByMember: Map<string, OriginalSelectionGroup>): OriginalSelectionGroup | null {
  let current: OriginalSelectionGroup | undefined = parentByMember.get(entityId);
  if (current === undefined) {
    return null;
  }
  const visited: Set<string> = new Set<string>();
  while (current !== undefined) {
    if (visited.has(current.id)) {
      return null;
    }
    visited.add(current.id);
    const parent: OriginalSelectionGroup | undefined = parentByMember.get(current.id);
    if (parent === undefined) {
      return current;
    }
    current = parent;
  }
  return null;
}

function expandGroup(groupId: string, byId: Map<string, OriginalSelectionGroup>,
  available: Set<string>, visiting: Set<string>): GroupExpansion {
  if (visiting.has(groupId)) {
    return { valid: false, leaves: [] };
  }
  const group: OriginalSelectionGroup | undefined = byId.get(groupId);
  if (group === undefined) {
    return { valid: false, leaves: [] };
  }
  visiting.add(groupId);
  const leaves: string[] = [];
  const seen: Set<string> = new Set<string>();
  for (const member of group.members) {
    if (byId.has(member)) {
      const nested: GroupExpansion = expandGroup(member, byId, available, visiting);
      if (!nested.valid) {
        visiting.delete(groupId);
        return { valid: false, leaves: [] };
      }
      for (const leaf of nested.leaves) {
        if (!seen.has(leaf)) {
          seen.add(leaf);
          leaves.push(leaf);
        }
      }
    } else if (!available.has(member)) {
      visiting.delete(groupId);
      return { valid: false, leaves: [] };
    } else if (!seen.has(member)) {
      seen.add(member);
      leaves.push(member);
    }
  }
  visiting.delete(groupId);
  return { valid: true, leaves: leaves };
}

function compareGroupIdentity(left: OriginalSelectionGroup,
  right: OriginalSelectionGroup): number {
  return left.timestamp === right.timestamp ? left.siteId - right.siteId :
    left.timestamp - right.timestamp;
}
