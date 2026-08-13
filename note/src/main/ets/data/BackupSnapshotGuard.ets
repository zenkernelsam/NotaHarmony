export interface BackupSnapshotEntry {
  noteId: string;
  title: string;
  createdAt: number;
  updatedAt: number;
  revision: string;
}

export class BackupPreparationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BackupPreparationError';
  }
}

export class BackupSnapshotChangedError extends BackupPreparationError {
  constructor(message: string) {
    super(message);
    this.name = 'BackupSnapshotChangedError';
  }
}

/**
 * The export loop is intentionally long-running and cannot hold one database read transaction
 * while ZIP files are built. Its final gate compares the exported set with one atomic library
 * snapshot so an early note cannot change while later notes are still being serialized.
 */
export function assertStableBackupSnapshot(expected: BackupSnapshotEntry[],
  current: BackupSnapshotEntry[]): void {
  const expectedById: Map<string, BackupSnapshotEntry> = snapshotById(expected, 'exported');
  const currentById: Map<string, BackupSnapshotEntry> = snapshotById(current, 'current');
  if (expectedById.size !== currentById.size) {
    throw new BackupSnapshotChangedError('the note collection changed during backup export');
  }
  expectedById.forEach((source: BackupSnapshotEntry, noteId: string): void => {
    const live: BackupSnapshotEntry | undefined = currentById.get(noteId);
    if (live === undefined || source.title !== live.title || source.createdAt !== live.createdAt ||
      source.updatedAt !== live.updatedAt || source.revision !== live.revision) {
      throw new BackupSnapshotChangedError(`note ${noteId} changed during backup export`);
    }
  });
}

function snapshotById(entries: BackupSnapshotEntry[], label: string): Map<string, BackupSnapshotEntry> {
  const result: Map<string, BackupSnapshotEntry> = new Map<string, BackupSnapshotEntry>();
  for (const entry of entries) {
    if (entry.noteId.length === 0 || typeof entry.title !== 'string' ||
      !Number.isSafeInteger(entry.createdAt) || entry.createdAt < 0 ||
      !Number.isSafeInteger(entry.updatedAt) || entry.updatedAt <= 0 ||
      entry.revision.length === 0 || result.has(entry.noteId)) {
      throw new BackupSnapshotChangedError(`${label} backup snapshot is invalid`);
    }
    result.set(entry.noteId, entry);
  }
  return result;
}
