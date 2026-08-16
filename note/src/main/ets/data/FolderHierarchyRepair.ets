export const ORIGINAL_MAX_FOLDER_DEPTH: number = 6;

export interface FolderHierarchyRecord {
  id: string;
  parentId: string | null;
  siblingOrder: number;
  createdAt: number;
}

export interface FolderHierarchyRepairUpdate {
  id: string;
  parentId: string | null;
  siblingOrder: number;
}

function normalizedOrder(value: number): number {
  return Number.isFinite(value) ? value : 0;
}

function compareRecords(left: FolderHierarchyRecord, right: FolderHierarchyRecord): number {
  const leftOrder: number = normalizedOrder(left.siblingOrder);
  const rightOrder: number = normalizedOrder(right.siblingOrder);
  if (leftOrder !== rightOrder) {
    return leftOrder - rightOrder;
  }
  if (left.createdAt !== right.createdAt) {
    return left.createdAt - right.createdAt;
  }
  return left.id < right.id ? -1 : left.id > right.id ? 1 : 0;
}

function parentDepth(folderId: string, parents: Map<string, string | null>): number {
  let depth: number = 1;
  let currentId: string = folderId;
  const visited: Set<string> = new Set<string>();
  while (true) {
    if (visited.has(currentId)) {
      return Number.MAX_SAFE_INTEGER;
    }
    visited.add(currentId);
    const parentId: string | null | undefined = parents.get(currentId);
    if (parentId === undefined || parentId === null) {
      return depth;
    }
    depth++;
    currentId = parentId;
  }
}

function sameParent(left: string | null, right: string | null): boolean {
  return left === right;
}

// Old builds and manually recovered databases can contain parent cycles, missing parents,
// over-deep trees, duplicated/fractional sibling positions, or all of them at once. Preserve
// every folder, detach only the minimum deterministic break points, then restore the original
// six-level and child-index invariants without guessing or rewriting user-visible names.
export function planFolderHierarchyRepairs(
  records: FolderHierarchyRecord[]): FolderHierarchyRepairUpdate[] {
  const stable: FolderHierarchyRecord[] = records.slice();
  stable.sort(compareRecords);
  const byId: Map<string, FolderHierarchyRecord> = new Map<string, FolderHierarchyRecord>();
  const stableRank: Map<string, number> = new Map<string, number>();
  const parents: Map<string, string | null> = new Map<string, string | null>();
  for (let index: number = 0; index < stable.length; index++) {
    const record: FolderHierarchyRecord = stable[index];
    byId.set(record.id, record);
    stableRank.set(record.id, index);
  }
  for (const record of stable) {
    const parentId: string | null = record.parentId;
    parents.set(record.id,
      parentId === record.id || (parentId !== null && !byId.has(parentId)) ? null : parentId);
  }

  // A parent relation is a functional graph. Break each remaining cycle at its earliest stable
  // member so the other links (and therefore as much of the recovered subtree as possible) stay.
  for (const record of stable) {
    const path: string[] = [];
    const pathIndex: Map<string, number> = new Map<string, number>();
    let currentId: string | null = record.id;
    while (currentId !== null) {
      const repeatedAt: number | undefined = pathIndex.get(currentId);
      if (repeatedAt !== undefined) {
        const cycle: string[] = path.slice(repeatedAt);
        let breakId: string = cycle[0];
        for (const cycleId of cycle) {
          const candidateRank: number = stableRank.get(cycleId) ?? Number.MAX_SAFE_INTEGER;
          const breakRank: number = stableRank.get(breakId) ?? Number.MAX_SAFE_INTEGER;
          if (candidateRank < breakRank) {
            breakId = cycleId;
          }
        }
        parents.set(breakId, null);
        break;
      }
      pathIndex.set(currentId, path.length);
      path.push(currentId);
      const parentId: string | null | undefined = parents.get(currentId);
      currentId = parentId === undefined ? null : parentId;
    }
  }

  // Process shallow nodes first. The first node that would become level seven is detached to the
  // top level; its descendants keep their internal relationships and are then measured again.
  const depthOrder: FolderHierarchyRecord[] = stable.slice();
  depthOrder.sort((left: FolderHierarchyRecord, right: FolderHierarchyRecord): number => {
    const depthDifference: number = parentDepth(left.id, parents) - parentDepth(right.id, parents);
    return depthDifference !== 0 ? depthDifference : compareRecords(left, right);
  });
  for (const record of depthOrder) {
    if (parentDepth(record.id, parents) > ORIGINAL_MAX_FOLDER_DEPTH) {
      parents.set(record.id, null);
    }
  }

  const normalizedOrders: Map<string, number> = new Map<string, number>();
  const parentGroups: Array<string | null> = [];
  for (const record of stable) {
    const parentId: string | null = parents.get(record.id) ?? null;
    let known: boolean = false;
    for (const existing of parentGroups) {
      if (sameParent(existing, parentId)) {
        known = true;
        break;
      }
    }
    if (!known) {
      parentGroups.push(parentId);
    }
  }
  for (const parentId of parentGroups) {
    const siblings: FolderHierarchyRecord[] = stable.filter(
      (record: FolderHierarchyRecord): boolean => sameParent(parents.get(record.id) ?? null, parentId));
    siblings.sort(compareRecords);
    for (let index: number = 0; index < siblings.length; index++) {
      normalizedOrders.set(siblings[index].id, index);
    }
  }

  const updates: FolderHierarchyRepairUpdate[] = [];
  for (const record of stable) {
    const parentId: string | null = parents.get(record.id) ?? null;
    const siblingOrder: number = normalizedOrders.get(record.id) ?? 0;
    if (!sameParent(record.parentId, parentId) || record.siblingOrder !== siblingOrder) {
      updates.push({ id: record.id, parentId: parentId, siblingOrder: siblingOrder });
    }
  }
  return updates;
}
