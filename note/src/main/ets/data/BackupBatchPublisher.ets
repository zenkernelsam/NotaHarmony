import { util } from '@kit.ArkTS';
import {
  BACKUP_BATCH_FORMAT, BACKUP_BATCH_VERSION, BACKUP_MAX_ENTRY_COUNT, BACKUP_MAX_TOTAL_BYTES,
  BackupBatchEntry, BackupBatchManifest, isValidBackupBatchId,
  BackupSourcePackage, serializeBackupBatch,
} from './BackupBatchSpec';
import { sha256Hex } from './BackupHash';

export interface BackupBatchTransport {
  ensureBackupDir(): Promise<boolean>;
  ensureBackupBatchDir(batchId: string): Promise<boolean>;
  backupBatchObjectUrl(batchId: string, fileName: string): string;
  backupBatchManifestUrl(batchId: string): string;
  upload(remotePath: string, data: Uint8Array): Promise<boolean>;
  download(remotePath: string): Promise<Uint8Array | null>;
}

export interface BackupBatchHasher {
  hash(data: Uint8Array): Promise<string>;
}

export enum BackupPublishStage {
  COMPLETE = 0,
  DIRECTORY = 1,
  OBJECT_UPLOAD = 2,
  OBJECT_VERIFY = 3,
  MANIFEST_PUBLISH = 4,
  MANIFEST_VERIFY = 5,
}

export interface BackupPublishResult {
  success: boolean;
  stage: BackupPublishStage;
  verified: number;
  total: number;
  manifest: BackupBatchManifest | null;
}

export class CryptoBackupBatchHasher implements BackupBatchHasher {
  async hash(data: Uint8Array): Promise<string> {
    return sha256Hex(data);
  }
}

export class BackupBatchPublisher {
  private transport: BackupBatchTransport;
  private hasher: BackupBatchHasher;

  constructor(transport: BackupBatchTransport, hasher: BackupBatchHasher) {
    this.transport = transport;
    this.hasher = hasher;
  }

  async publish(packages: BackupSourcePackage[], batchId: string,
    completedAt: number): Promise<BackupPublishResult> {
    const total: number = packages.length;
    if (!isValidBackupBatchId(batchId) || !Number.isFinite(completedAt) || completedAt <= 0 ||
      total === 0 || total > BACKUP_MAX_ENTRY_COUNT) {
      return this.failed(BackupPublishStage.OBJECT_UPLOAD, 0, total);
    }
    let totalBytes: number = 0;
    const noteIds: Set<string> = new Set<string>();
    const fileNames: Set<string> = new Set<string>();
    for (const source of packages) {
      if (source.noteId.length === 0 || source.revision.length === 0 ||
        !Number.isFinite(source.updatedAt) || source.updatedAt <= 0 || source.data.length <= 0 ||
        totalBytes > BACKUP_MAX_TOTAL_BYTES - source.data.length) {
        return this.failed(BackupPublishStage.OBJECT_UPLOAD, 0, total);
      }
      const fileName: string = `${noteIds.size}-${safeObjectId(source.noteId)}.note`;
      if (noteIds.has(source.noteId) || fileNames.has(fileName)) {
        return this.failed(BackupPublishStage.OBJECT_UPLOAD, 0, total);
      }
      noteIds.add(source.noteId);
      fileNames.add(fileName);
      totalBytes += source.data.length;
    }
    if (!await this.transport.ensureBackupDir() ||
      !await this.transport.ensureBackupBatchDir(batchId)) {
      return this.failed(BackupPublishStage.DIRECTORY, 0, total);
    }
    const entries: BackupBatchEntry[] = [];
    for (let i: number = 0; i < packages.length; i++) {
      const source: BackupSourcePackage = packages[i];
      const fileName: string = `${i}-${safeObjectId(source.noteId)}.note`;
      const hash: string = await this.hasher.hash(source.data);
      const objectUrl: string = this.transport.backupBatchObjectUrl(batchId, fileName);
      if (!await this.transport.upload(objectUrl, source.data)) {
        return this.failed(BackupPublishStage.OBJECT_UPLOAD, entries.length, total);
      }
      const uploaded: Uint8Array | null = await this.transport.download(objectUrl);
      if (uploaded === null || uploaded.length !== source.data.length ||
        await this.hasher.hash(uploaded) !== hash) {
        return this.failed(BackupPublishStage.OBJECT_VERIFY, entries.length, total);
      }
      entries.push({ noteId: source.noteId, fileName: fileName, size: source.data.length,
        sha256: hash, updatedAt: source.updatedAt, revision: source.revision });
    }
    const manifest: BackupBatchManifest = {
      format: BACKUP_BATCH_FORMAT,
      version: BACKUP_BATCH_VERSION,
      batchId: batchId,
      createdAt: completedAt,
      entries: entries,
    };
    const manifestData: Uint8Array = new util.TextEncoder().encodeInto(serializeBackupBatch(manifest));
    const manifestUrl: string = this.transport.backupBatchManifestUrl(batchId);
    if (!await this.transport.upload(manifestUrl, manifestData)) {
      return this.failed(BackupPublishStage.MANIFEST_PUBLISH, entries.length, total);
    }
    const published: Uint8Array | null = await this.transport.download(manifestUrl);
    if (published === null || published.length !== manifestData.length ||
      await this.hasher.hash(published) !== await this.hasher.hash(manifestData)) {
      return this.failed(BackupPublishStage.MANIFEST_VERIFY, entries.length, total);
    }
    return { success: true, stage: BackupPublishStage.COMPLETE, verified: entries.length,
      total: total, manifest: manifest };
  }

  private failed(stage: BackupPublishStage, verified: number, total: number): BackupPublishResult {
    return { success: false, stage: stage, verified: verified, total: total, manifest: null };
  }
}

function safeObjectId(noteId: string): string {
  const safe: string = noteId.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 96);
  return safe.length > 0 ? safe : 'note';
}
