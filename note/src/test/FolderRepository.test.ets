import { describe, it, expect } from '@ohos/hypium';
import {
  NoteFolder, isFolderInSubtree, validateFolderMove, validateFolderName,
} from '../main/ets/data/FolderRepositoryImpl';

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
  });
}
