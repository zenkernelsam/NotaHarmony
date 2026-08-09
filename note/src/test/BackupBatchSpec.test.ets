import { describe, it, expect } from '@ohos/hypium';
import {
  BACKUP_BATCH_FORMAT, BACKUP_BATCH_VERSION, BackupBatchManifest,
  backupManifestFileName, parseBackupBatch, serializeBackupBatch,
} from '../main/ets/data/BackupBatchSpec';

function manifest(): BackupBatchManifest {
  return {
    format: BACKUP_BATCH_FORMAT,
    version: BACKUP_BATCH_VERSION,
    batchId: 'm4f9z120-abcd1234',
    createdAt: 1786200000000,
    entries: [{
      noteId: 'note-a',
      fileName: '0-note-a.note',
      size: 42,
      sha256: 'a'.repeat(64),
      updatedAt: 1786190000000,
      revision: '2:7:4',
    }],
  };
}

export default function backupBatchSpecTest() {
  describe('BackupBatchSpec', () => {
    it('round trips a complete manifest and derives its publication name', 0, () => {
      const value: BackupBatchManifest | null = parseBackupBatch(serializeBackupBatch(manifest()));
      expect(value === null).assertFalse();
      expect(value?.entries.length).assertEqual(1);
      expect(backupManifestFileName('m4f9z120-abcd1234')).assertEqual(
        'batch-m4f9z120-abcd1234.manifest.json');
    });

    it('rejects duplicate identities and unsafe object paths', 0, () => {
      const duplicate: BackupBatchManifest = manifest();
      duplicate.entries.push({
        noteId: 'note-a', fileName: '../escape.note', size: 1, sha256: 'b'.repeat(64),
        updatedAt: 1, revision: '1:1:1',
      });
      expect(parseBackupBatch(serializeBackupBatch(duplicate)) === null).assertTrue();
    });

    it('rejects malformed hashes, empty batches and future versions', 0, () => {
      const badHash: BackupBatchManifest = manifest();
      badHash.entries[0].sha256 = 'abc';
      expect(parseBackupBatch(serializeBackupBatch(badHash)) === null).assertTrue();
      const empty: BackupBatchManifest = manifest();
      empty.entries = [];
      expect(parseBackupBatch(serializeBackupBatch(empty)) === null).assertTrue();
      const future: BackupBatchManifest = manifest();
      future.version = BACKUP_BATCH_VERSION + 1;
      expect(parseBackupBatch(serializeBackupBatch(future)) === null).assertTrue();
    });
  });
}
