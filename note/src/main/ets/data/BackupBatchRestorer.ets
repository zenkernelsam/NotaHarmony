import { BackupBatchEntry, BackupBatchManifest, parseBackupBatch, serializeBackupBatch } from './BackupBatchSpec';
import { BackupBatchHasher, BackupBatchTransport } from './BackupBatchPublisher';

export interface VerifiedBackupObject {
  entry: BackupBatchEntry;
  data: Uint8Array;
}

export interface BackupFetchResult {
  verified: VerifiedBackupObject[];
  failedNoteIds: string[];
}

export class BackupBatchRestorer {
  private transport: BackupBatchTransport;
  private hasher: BackupBatchHasher;

  constructor(transport: BackupBatchTransport, hasher: BackupBatchHasher) {
    this.transport = transport;
    this.hasher = hasher;
  }

  async fetch(manifest: BackupBatchManifest): Promise<BackupFetchResult> {
    const verified: VerifiedBackupObject[] = [];
    const failedNoteIds: string[] = [];
    const validated: BackupBatchManifest | null = parseBackupBatch(serializeBackupBatch(manifest));
    if (validated === null) {
      throw new Error('backup manifest failed structural validation before download');
    }
    for (let i: number = 0; i < manifest.entries.length; i++) {
      const entry: BackupBatchEntry = manifest.entries[i];
      const data: Uint8Array | null = await this.transport.download(
        this.transport.backupBatchObjectUrl(manifest.batchId, entry.fileName));
      if (data === null || data.length !== entry.size ||
        await this.hasher.hash(data) !== entry.sha256) {
        failedNoteIds.push(entry.noteId);
      } else {
        verified.push({ entry: entry, data: data });
      }
    }
    return { verified: verified, failedNoteIds: failedNoteIds };
  }
}
