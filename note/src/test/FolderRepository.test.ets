import { describe, it, expect } from '@ohos/hypium';
import {
  FolderDropIntent, FolderMovePlan, NoteFolder, isFolderInSubtree, planFolderMove,
  resolveFolderDrop, validateFolderMove, validateFolderName,
} from '../main/ets/data/FolderRepositoryImpl';
import {
  FolderHierarchyRecord, FolderHierarchyRepairUpdate, planFolderHierarchyRepairs,
} from '../main/ets/data/FolderHierarchyRepair';

function folder(id: string, name: string, parentId: string | null, order: number): NoteFolder {
  return {
    id: id,
    name: name,
    createdAt: order,
    parentId: parentId,
    siblingOrder: order,
  };
}

function throws(operation: () => void): boolean {
  try {
    operation();
    return false;
  } catch (_error) {
    return true;
  }
}

function applyRepairs(records: FolderHierarchyRecord[],
  updates: FolderHierarchyRepairUpdate[]): FolderHierarchyRecord[] {
  return records.map((record: FolderHierarchyRecord): FolderHierarchyRecord => {
    for (const update of updates) {
      if (update.id === record.id) {
        return {
          id: record.id,
          createdAt: record.createdAt,
          parentId: update.parentId,
          siblingOrder: update.siblingOrder,
        };
      }
    }
    return record;
  });
}

function repairedFolder(records: FolderHierarchyRecord[], id: string): FolderHierarchyRecord {
  for (const record of records) {
    if (record.id === id) {
      return record;
    }
  }
  throw new Error(`missing repaired folder: ${id}`);
}

function hierarchyDepth(records: FolderHierarchyRecord[], id: string): number {
  let depth: number = 1;
  let current: FolderHierarchyRecord = repairedFolder(records, id);
  const visited: Set<string> = new Set<string>();
  while (current.parentId !== null) {
    if (visited.has(current.id)) {
      return 1000;
    }
    visited.add(current.id);
    current = repairedFolder(records, current.parentId);
    depth++;
  }
  return depth;
}

export default function folderRepositoryTest() {
  describe('FolderRepository validation', () => {
    it('matches the original invalid-name and sibling duplicate rules', 0, () => {
      const folders: NoteFolder[] = [
        folder('a', 'Work', null, 0),
        folder('b', 'Work', 'a', 0),
      ];
      expect(throws(() => validateFolderName(folders, ' ', null))).assertTrue();
      expect(throws(() => validateFolderName(folders, 'A/B', null))).assertTrue();
      expect(throws(() => validateFolderName(folders, 'A\\B', null))).assertTrue();
      expect(throws(() => validateFolderName(folders, 'work', null))).assertTrue();
      expect(validateFolderName(folders, 'work', 'b')).assertEqual('work');
      expect(validateFolderName(folders, ' Work ', null, 'a')).assertEqual('Work');
    });

    it('rejects moving a folder into itself or its descendants', 0, () => {
      const folders: NoteFolder[] = [
        folder('a', 'A', null, 0),
        folder('b', 'B', 'a', 0),
        folder('c', 'C', 'b', 0),
      ];
      expect(isFolderInSubtree(folders, 'a', 'c')).assertTrue();
      expect(throws(() => validateFolderMove(folders, 'a', 'a'))).assertTrue();
      expect(throws(() => validateFolderMove(folders, 'a', 'c'))).assertTrue();
      expect(throws(() => validateFolderMove(folders, 'c', null))).assertFalse();
    });

    it('does not absorb an unrelated corrupt cycle into a deleted subtree', 0, () => {
      const folders: NoteFolder[] = [
        folder('root', 'Root', null, 0),
        folder('child', 'Child', 'root', 0),
        folder('cycle-a', 'Cycle A', 'cycle-b', 1),
        folder('cycle-b', 'Cycle B', 'cycle-a', 2),
      ];
      expect(isFolderInSubtree(folders, 'root', 'child')).assertTrue();
      expect(isFolderInSubtree(folders, 'root', 'cycle-a')).assertFalse();
      expect(isFolderInSubtree(folders, 'root', 'cycle-b')).assertFalse();
      expect(throws(() => validateFolderMove(folders, 'root', 'cycle-a'))).assertTrue();
    });

    it('enforces the original maximum depth of six for the whole subtree', 0, () => {
      const folders: NoteFolder[] = [
        folder('a', 'A', null, 0),
        folder('b', 'B', 'a', 0),
        folder('c', 'C', 'b', 0),
        folder('d', 'D', 'c', 0),
        folder('e', 'E', 'd', 0),
        folder('f', 'F', 'e', 0),
        folder('move', 'Move', null, 1),
      ];
      expect(throws(() => validateFolderMove(folders, 'move', 'f'))).assertTrue();
      expect(throws(() => validateFolderMove(folders, 'move', 'e'))).assertFalse();
    });

    it('plans original parent plus child-index moves instead of always appending', 0, () => {
      const folders: NoteFolder[] = [
        folder('a', 'A', null, 0),
        folder('b', 'B', null, 1),
        folder('c', 'C', null, 2),
        folder('parent', 'Parent', null, 3),
        folder('child', 'Child', 'parent', 0),
      ];
      const beforeFirst: FolderMovePlan = planFolderMove(folders, 'b', null, 0);
      expect(beforeFirst.newSiblingIds.join(',')).assertEqual('b,a,c,parent');
      expect(beforeFirst.insertIndex).assertEqual(0);

      const afterLast: FolderMovePlan = planFolderMove(folders, 'a', null, 99);
      expect(afterLast.newSiblingIds.join(',')).assertEqual('b,c,parent,a');
      expect(afterLast.insertIndex).assertEqual(3);

      const crossParent: FolderMovePlan = planFolderMove(folders, 'c', 'parent', 0);
      expect(crossParent.oldSiblingIds.join(',')).assertEqual('a,b,parent');
      expect(crossParent.newSiblingIds.join(',')).assertEqual('c,child');
    });

    it('maps a flat drag boundary to the original destination parent and child index', 0, () => {
      const folders: NoteFolder[] = [
        folder('a', 'A', null, 0),
        folder('a-child', 'A Child', 'a', 0),
        folder('b', 'B', null, 1),
        folder('c', 'C', null, 2),
      ];
      const visible: string[] = ['a', 'a-child', 'b', 'c'];
      const depths: number[] = [0, 1, 0, 0];
      const first: FolderDropIntent | null = resolveFolderDrop(folders, visible, depths, 3, 0, 0);
      expect(first?.folderId).assertEqual('c');
      expect(first?.parentId === null).assertTrue();
      expect(first?.insertIndex).assertEqual(0);

      const subtreeAfterLast: FolderDropIntent | null = resolveFolderDrop(folders, visible, depths, 0, 4, 0);
      expect(subtreeAfterLast?.folderId).assertEqual('a');
      expect(subtreeAfterLast?.parentId === null).assertTrue();
      expect(subtreeAfterLast?.insertIndex).assertEqual(2);

      const sameDepthNoOp: FolderDropIntent | null = resolveFolderDrop(folders, visible, depths, 2, 1, 0);
      expect(sameDepthNoOp === null).assertTrue();

      const intoExpandedParent: FolderDropIntent | null = resolveFolderDrop(
        folders, visible, depths, 2, 1, 1);
      expect(intoExpandedParent?.folderId).assertEqual('b');
      expect(intoExpandedParent?.parentId).assertEqual('a');
      expect(intoExpandedParent?.insertIndex).assertEqual(0);

      const emptyParentFolders: NoteFolder[] = [
        folder('empty', 'Empty', null, 0),
        folder('move', 'Move', null, 1),
      ];
      const intoEmptyParent: FolderDropIntent | null = resolveFolderDrop(
        emptyParentFolders, ['empty', 'move'], [0, 0], 1, 1, 1);
      expect(intoEmptyParent?.parentId).assertEqual('empty');
      expect(intoEmptyParent?.insertIndex).assertEqual(0);

      // ArkUI 6.0 computes onItemDrop.insertIndex from the still-present source list.
      // Moving down therefore has to remove the source item before converting the raw boundary.
      const linearFolders: NoteFolder[] = [
        folder('linear-a', 'Linear A', null, 0),
        folder('linear-b', 'Linear B', null, 1),
        folder('linear-c', 'Linear C', null, 2),
        folder('linear-d', 'Linear D', null, 3),
      ];
      const downwardBeforeLast: FolderDropIntent | null = resolveFolderDrop(
        linearFolders, ['linear-a', 'linear-b', 'linear-c', 'linear-d'], [0, 0, 0, 0], 1, 3, 0);
      expect(downwardBeforeLast?.insertIndex).assertEqual(2);
      const downwardAfterLast: FolderDropIntent | null = resolveFolderDrop(
        linearFolders, ['linear-a', 'linear-b', 'linear-c', 'linear-d'], [0, 0, 0, 0], 1, 4, 0);
      expect(downwardAfterLast?.insertIndex).assertEqual(3);
    });

    it('repairs old-library orphans, cycles, over-depth paths and sibling gaps deterministically', 0, () => {
      const records: FolderHierarchyRecord[] = [
        { id: 'root', parentId: null, siblingOrder: 10, createdAt: 0 },
        { id: 'orphan', parentId: 'missing', siblingOrder: 5, createdAt: 1 },
        { id: 'cycle-a', parentId: 'cycle-b', siblingOrder: 1, createdAt: 2 },
        { id: 'cycle-b', parentId: 'cycle-a', siblingOrder: 2, createdAt: 3 },
        { id: 'self', parentId: 'self', siblingOrder: 4, createdAt: 10 },
        { id: 'd2', parentId: 'root', siblingOrder: 9, createdAt: 4 },
        { id: 'd3', parentId: 'd2', siblingOrder: 9, createdAt: 5 },
        { id: 'd4', parentId: 'd3', siblingOrder: 9, createdAt: 6 },
        { id: 'd5', parentId: 'd4', siblingOrder: 9, createdAt: 7 },
        { id: 'd6', parentId: 'd5', siblingOrder: 9, createdAt: 8 },
        { id: 'd7', parentId: 'd6', siblingOrder: 9, createdAt: 9 },
      ];
      const repaired: FolderHierarchyRecord[] = applyRepairs(records,
        planFolderHierarchyRepairs(records));
      expect(repairedFolder(repaired, 'orphan').parentId === null).assertTrue();
      expect(repairedFolder(repaired, 'cycle-a').parentId === null).assertTrue();
      expect(repairedFolder(repaired, 'cycle-b').parentId).assertEqual('cycle-a');
      expect(repairedFolder(repaired, 'self').parentId === null).assertTrue();
      expect(repairedFolder(repaired, 'd7').parentId === null).assertTrue();
      for (const record of repaired) {
        expect(hierarchyDepth(repaired, record.id) <= 6).assertTrue();
      }
      const roots: FolderHierarchyRecord[] = repaired.filter(
        (record: FolderHierarchyRecord): boolean => record.parentId === null);
      roots.sort((left: FolderHierarchyRecord, right: FolderHierarchyRecord): number =>
        left.siblingOrder - right.siblingOrder);
      for (let index: number = 0; index < roots.length; index++) {
        expect(roots[index].siblingOrder).assertEqual(index);
      }
      expect(planFolderHierarchyRepairs(repaired).length).assertEqual(0);
    });
  });
}
