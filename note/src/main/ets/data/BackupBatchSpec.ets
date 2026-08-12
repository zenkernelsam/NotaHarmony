export const BACKUP_BATCH_FORMAT: string = 'nota.backup-batch';
export const BACKUP_BATCH_VERSION: number = 1;
export const BACKUP_MANIFEST_SUFFIX: string = '.manifest.json';
export const BACKUP_MAX_ENTRY_COUNT: number = 10000;
export const BACKUP_MAX_TOTAL_BYTES: number = 1024 * 1024 * 1024;

export interface BackupBatchEntry {
  noteId: string;
  fileName: string;
  size: number;
  sha256: string;
  updatedAt: number;
  revision: string;
}

export interface BackupBatchManifest {
  format: string;
  version: number;
  batchId: string;
  createdAt: number;
  entries: BackupBatchEntry[];
}

export interface BackupSourcePackage {
  noteId: string;
  updatedAt: number;
  revision: string;
  data: Uint8Array;
}

export function isValidBackupBatchId(batchId: string): boolean {
  return /^[a-z0-9-]{8,80}$/.test(batchId);
}

export function backupManifestFileName(batchId: string): string {
  if (!isValidBackupBatchId(batchId)) {
    throw new Error('invalid backup batch id');
  }
  return `batch-${batchId}${BACKUP_MANIFEST_SUFFIX}`;
}

export function serializeBackupBatch(manifest: BackupBatchManifest): string {
  return JSON.stringify(manifest);
}

export function parseBackupBatch(json: string): BackupBatchManifest | null {
  try {
    const parsed = JSON.parse(json) as BackupBatchManifest;
    if (parsed === null || typeof parsed !== 'object' || parsed.format !== BACKUP_BATCH_FORMAT ||
      parsed.version !== BACKUP_BATCH_VERSION || !isValidBackupBatchId(parsed.batchId) ||
      !Number.isFinite(parsed.createdAt) || parsed.createdAt <= 0 || !Array.isArray(parsed.entries) ||
      parsed.entries.length === 0 || parsed.entries.length > BACKUP_MAX_ENTRY_COUNT) {
      return null;
    }
    const noteIds: Set<string> = new Set<string>();
    const fileNames: Set<string> = new Set<string>();
    let totalBytes: number = 0;
    for (let i: number = 0; i < parsed.entries.length; i++) {
      const entry: BackupBatchEntry = parsed.entries[i];
      if (entry === null || typeof entry !== 'object' || typeof entry.noteId !== 'string' ||
        entry.noteId.length === 0 || typeof entry.fileName !== 'string' ||
        !isSafeBackupFileName(entry.fileName) || !Number.isSafeInteger(entry.size) || entry.size <= 0 ||
        typeof entry.sha256 !== 'string' || !/^[0-9a-f]{64}$/.test(entry.sha256) ||
        !Number.isFinite(entry.updatedAt) || entry.updatedAt <= 0 ||
        typeof entry.revision !== 'string' || entry.revision.length === 0 ||
        noteIds.has(entry.noteId) || fileNames.has(entry.fileName)) {
        return null;
      }
      if (totalBytes > BACKUP_MAX_TOTAL_BYTES - entry.size) {
        return null;
      }
      totalBytes += entry.size;
      noteIds.add(entry.noteId);
      fileNames.add(entry.fileName);
    }
    return parsed;
  } catch (_error) {
    return null;
  }
}

function isSafeBackupFileName(fileName: string): boolean {
  return fileName.endsWith('.note') && fileName.indexOf('/') < 0 && fileName.indexOf('\\') < 0 &&
    fileName !== '.note' && fileName.length <= 180;
}
