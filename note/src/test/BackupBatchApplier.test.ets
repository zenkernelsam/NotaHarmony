import { describe, it, expect } from '@ohos/hypium';
import {
  BackupBatchApplier, BackupBatchApplyResult, BackupBatchApplyStatus, BackupObjectImporter,
  ImportedNoteRemover,
} from '../main/ets/data/BackupBatchApplier';
import { VerifiedBackupObject } from '../main/ets/data/BackupBatchRestorer';
import { ImportReport, ImportResult } from '../main/ets/data/NoteImporter';

class FakeImporter implements BackupObjectImporter {
  reports: ImportReport[];
  calls: number = 0;
  throwAt: number = -1;

  constructor(reports: ImportReport[]) {
    this.reports = reports;
  }

  async importFromData(_data: Uint8Array): Promise<ImportReport> {
    const call: number = this.calls++;
    if (call === this.throwAt) {
      throw new Error('expected import failure');
    }
    return this.reports[call];
  }
}

class FakeRemover implements ImportedNoteRemover {
  removed: string[] = [];
  failNoteId: string = '';

  async removeImportedNote(noteId: string): Promise<boolean> {
    this.removed.push(noteId);
    if (noteId === this.failNoteId) {
      return false;
    }
    return true;
  }
}

function report(result: ImportResult, noteId: string | null): ImportReport {
  return {
    result: result, noteId: noteId, title: null, pageCount: 1,
    missingAssets: [], warnings: [], message: '',
  };
}

function object(noteId: string, value: number): VerifiedBackupObject {
  return {
    entry: {
      noteId: noteId, fileName: `${noteId}.note`, size: 1, sha256: 'a'.repeat(64),
      updatedAt: value, revision: `1:${value}:${value}`,
    },
    data: new Uint8Array([value]),
  };
}

function objects(): VerifiedBackupObject[] {
  return [object('source-a', 1), object('source-b', 2), object('source-c', 3)];
}

export default function backupBatchApplierTest() {
  describe('BackupBatchApplier', () => {
    it('commits successful and explicitly partial verified notes', 0, async () => {
      const importer = new FakeImporter([
        report(ImportResult.SUCCESS, 'local-a'), report(ImportResult.PARTIAL, 'local-b'),
      ]);
      const remover = new FakeRemover();
      const result: BackupBatchApplyResult = await new BackupBatchApplier(importer, remover)
        .apply(objects().slice(0, 2));
      expect(result.status).assertEqual(BackupBatchApplyStatus.APPLIED);
      expect(result.restored).assertEqual(2);
      expect(result.degraded).assertEqual(1);
      expect(remover.removed.length).assertEqual(0);
    });

    it('rolls prior notes and a failed import residue back in reverse order', 0, async () => {
      const importer = new FakeImporter([
        report(ImportResult.SUCCESS, 'local-a'), report(ImportResult.PARTIAL, 'local-b'),
        report(ImportResult.CORRUPTED, 'residual-c'),
      ]);
      const remover = new FakeRemover();
      const result: BackupBatchApplyResult = await new BackupBatchApplier(importer, remover)
        .apply(objects());
      expect(result.status).assertEqual(BackupBatchApplyStatus.ROLLED_BACK);
      expect(result.restored).assertEqual(0);
      expect(result.rolledBack).assertEqual(3);
      expect(remover.removed.join(',')).assertEqual('residual-c,local-b,local-a');
      expect(result.failedSourceNoteId).assertEqual('source-c');
    });

    it('continues compensating after one rollback deletion fails', 0, async () => {
      const importer = new FakeImporter([
        report(ImportResult.SUCCESS, 'local-a'), report(ImportResult.SUCCESS, 'local-b'),
        report(ImportResult.UNSUPPORTED_FORMAT, null),
      ]);
      const remover = new FakeRemover();
      remover.failNoteId = 'local-b';
      const result: BackupBatchApplyResult = await new BackupBatchApplier(importer, remover)
        .apply(objects());
      expect(result.status).assertEqual(BackupBatchApplyStatus.ROLLBACK_INCOMPLETE);
      expect(result.rolledBack).assertEqual(1);
      expect(result.unresolvedRollbackCount).assertEqual(1);
      expect(result.rollbackFailedNoteIds.join(',')).assertEqual('local-b');
      expect(remover.removed.join(',')).assertEqual('local-b,local-a');
    });

    it('rejects a committed report without a fresh note identity', 0, async () => {
      const importer = new FakeImporter([
        report(ImportResult.SUCCESS, 'local-a'), report(ImportResult.SUCCESS, null),
      ]);
      const remover = new FakeRemover();
      const result: BackupBatchApplyResult = await new BackupBatchApplier(importer, remover)
        .apply(objects().slice(0, 2));
      expect(result.status).assertEqual(BackupBatchApplyStatus.ROLLBACK_INCOMPLETE);
      expect(result.unresolvedRollbackCount).assertEqual(1);
      expect(remover.removed.join(',')).assertEqual('local-a');
    });

    it('rolls back known notes but marks an unexpected importer throw unresolved', 0, async () => {
      const importer = new FakeImporter([
        report(ImportResult.SUCCESS, 'local-a'), report(ImportResult.SUCCESS, 'unused'),
      ]);
      importer.throwAt = 1;
      const remover = new FakeRemover();
      const result: BackupBatchApplyResult = await new BackupBatchApplier(importer, remover)
        .apply(objects().slice(0, 2));
      expect(result.status).assertEqual(BackupBatchApplyStatus.ROLLBACK_INCOMPLETE);
      expect(remover.removed.join(',')).assertEqual('local-a');
      expect(result.failedSourceNoteId).assertEqual('source-b');
      expect(result.unresolvedRollbackCount).assertEqual(1);
    });
  });
}
