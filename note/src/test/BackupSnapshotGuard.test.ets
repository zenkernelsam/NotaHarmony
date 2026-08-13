import { describe, it, expect } from '@ohos/hypium';
import {
  assertStableBackupSnapshot, BackupSnapshotChangedError, BackupSnapshotEntry,
} from '../main/ets/data/BackupSnapshotGuard';

function entry(noteId: string, revision: string, updatedAt: number = 20,
  createdAt: number = 10): BackupSnapshotEntry {
  return {
    noteId: noteId,
    title: `Title ${noteId}`,
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: revision,
  };
}

function rejects(expected: BackupSnapshotEntry[], current: BackupSnapshotEntry[]): boolean {
  try {
    assertStableBackupSnapshot(expected, current);
    return false;
  } catch (error) {
    return error instanceof BackupSnapshotChangedError;
  }
}

export default function backupSnapshotGuardTest() {
  describe('BackupSnapshotGuard', () => {
    it('accepts the same complete library independent of query order', 0, () => {
      assertStableBackupSnapshot([entry('a', 'ra'), entry('b', 'rb')],
        [entry('b', 'rb'), entry('a', 'ra')]);
      assertStableBackupSnapshot([entry('epoch', 'r0', 20, 0)],
        [entry('epoch', 'r0', 20, 0)]);
      expect(true).assertTrue();
    });

    it('rejects an early note changed after its individual export', 0, () => {
      expect(rejects([entry('a', 'ra'), entry('b', 'rb')],
        [entry('a', 'ra-new'), entry('b', 'rb')])).assertTrue();
    });

    it('rejects added deleted or metadata-changed notes', 0, () => {
      expect(rejects([entry('a', 'ra')], [entry('a', 'ra'), entry('b', 'rb')])).assertTrue();
      expect(rejects([entry('a', 'ra'), entry('b', 'rb')], [entry('a', 'ra')])).assertTrue();
      expect(rejects([entry('a', 'ra', 20)], [entry('a', 'ra', 21)])).assertTrue();
    });

    it('rejects duplicate or malformed snapshot identities', 0, () => {
      expect(rejects([entry('a', 'ra'), entry('a', 'rb')], [entry('a', 'ra')])).assertTrue();
      expect(rejects([entry('', 'ra')], [entry('', 'ra')])).assertTrue();
    });
  });
}
