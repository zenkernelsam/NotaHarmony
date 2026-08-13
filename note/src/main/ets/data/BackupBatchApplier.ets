import { VerifiedBackupObject } from './BackupBatchRestorer';
import { ImportReport, ImportResult } from './NoteImporter';

export interface BackupObjectImporter {
  importFromData(data: Uint8Array): Promise<ImportReport>;
}

export interface ImportedNoteRemover {
  removeImportedNote(noteId: string): Promise<boolean>;
}

export enum BackupBatchApplyStatus {
  APPLIED = 'applied',
  ROLLED_BACK = 'rolled_back',
  ROLLBACK_INCOMPLETE = 'rollback_incomplete',
}

export interface BackupBatchApplyResult {
  status: BackupBatchApplyStatus;
  restored: number;
  degraded: number;
  failedSourceNoteId: string | null;
  rolledBack: number;
  unresolvedRollbackCount: number;
  rollbackFailedNoteIds: string[];
}

/**
 * Applies the already verified objects as one application-level unit. Each note importer owns its
 * internal database transactions; a later hard failure is compensated by deleting every note that
 * this attempt created, in reverse order.
 */
export class BackupBatchApplier {
  private importer: BackupObjectImporter;
  private remover: ImportedNoteRemover;

  constructor(importer: BackupObjectImporter, remover: ImportedNoteRemover) {
    this.importer = importer;
    this.remover = remover;
  }

  async apply(objects: VerifiedBackupObject[]): Promise<BackupBatchApplyResult> {
    const createdNoteIds: string[] = [];
    let restored: number = 0;
    let degraded: number = 0;
    for (let index: number = 0; index < objects.length; index++) {
      const object: VerifiedBackupObject = objects[index];
      let report: ImportReport;
      try {
        report = await this.importer.importFromData(object.data);
      } catch (error) {
        console.error(`backup batch import threw for ${object.entry.noteId}: ${JSON.stringify(error)}`);
        // An unexpected throw does not carry the importer's residual note identity contract.
        return await this.rollback(createdNoteIds, object.entry.noteId, true);
      }
      const committed: boolean = report.result === ImportResult.SUCCESS ||
        report.result === ImportResult.PARTIAL;
      if (!committed) {
        this.registerResidual(createdNoteIds, report.noteId);
        return await this.rollback(createdNoteIds, object.entry.noteId, false);
      }
      if (report.noteId === null || report.noteId.length === 0 ||
        createdNoteIds.indexOf(report.noteId) >= 0) {
        console.error(`backup batch importer returned an invalid committed note identity for ` +
          `${object.entry.noteId}`);
        // A committed import without a fresh identity cannot be proven absent after compensation.
        return await this.rollback(createdNoteIds, object.entry.noteId, true);
      }
      createdNoteIds.push(report.noteId);
      restored++;
      if (report.result === ImportResult.PARTIAL) {
        degraded++;
      }
    }
    return {
      status: BackupBatchApplyStatus.APPLIED,
      restored: restored,
      degraded: degraded,
      failedSourceNoteId: null,
      rolledBack: 0,
      unresolvedRollbackCount: 0,
      rollbackFailedNoteIds: [],
    };
  }

  private registerResidual(createdNoteIds: string[], noteId: string | null): void {
    if (noteId !== null && noteId.length > 0 && createdNoteIds.indexOf(noteId) < 0) {
      createdNoteIds.push(noteId);
    }
  }

  private async rollback(createdNoteIds: string[], failedSourceNoteId: string,
    untrackedCommittedNote: boolean):
    Promise<BackupBatchApplyResult> {
    const rollbackFailedNoteIds: string[] = [];
    let rolledBack: number = 0;
    for (let index: number = createdNoteIds.length - 1; index >= 0; index--) {
      const noteId: string = createdNoteIds[index];
      try {
        if (await this.remover.removeImportedNote(noteId)) {
          rolledBack++;
        } else {
          rollbackFailedNoteIds.push(noteId);
        }
      } catch (error) {
        rollbackFailedNoteIds.push(noteId);
        console.error(`backup batch rollback failed for ${noteId}: ${JSON.stringify(error)}`);
      }
    }
    return {
      status: rollbackFailedNoteIds.length === 0 && !untrackedCommittedNote ?
        BackupBatchApplyStatus.ROLLED_BACK :
        BackupBatchApplyStatus.ROLLBACK_INCOMPLETE,
      restored: 0,
      degraded: 0,
      failedSourceNoteId: failedSourceNoteId,
      rolledBack: rolledBack,
      unresolvedRollbackCount: rollbackFailedNoteIds.length + (untrackedCommittedNote ? 1 : 0),
      rollbackFailedNoteIds: rollbackFailedNoteIds,
    };
  }
}
