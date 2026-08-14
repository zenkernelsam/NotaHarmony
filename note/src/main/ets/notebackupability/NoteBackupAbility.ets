import { BackupExtensionAbility, BundleVersion, fileIo } from '@kit.CoreFileKit';
import { bundleManager } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { assetMutationMutex } from '../data/AssetRepositoryImpl';
import { DB_NAME } from '../data/DatabaseHelper';
import { databaseWriteMutex } from '../data/DatabaseWriteMutex';

const MANIFEST = 'nota-backup-manifest.json';
const SNAPSHOT = 'nota-snapshot';
const STAGING = 'nota-snapshot.staging';
const RESTORE_ROLLBACK = 'nota-restore.rollback';
const PREVIOUS = 'nota-snapshot.previous';
const LEGACY_MANIFEST_SCHEMA = 1;
const CURRENT_MANIFEST_SCHEMA = 2;
const FILES_ROOT = 'filesDir';
const DATABASE_ROOT = 'databaseDir';
const DATABASE_CAPTURE_BEFORE = 'nota-system-backup-before.db';
const DATABASE_CAPTURE_AFTER = 'nota-system-backup-after.db';
const DATABASE_RESTORE_SOURCE = 'nota-system-restore-source.db';
const DATABASE_RESTORE_ROLLBACK = 'nota-system-restore-rollback.db';
const MAX_FILES = 10000;
const MAX_BYTES = 256 * 1024 * 1024;
const MAX_VERSION_CODE = 2147483647;
const MAX_VERSION_NAME_BYTES = 127;
const COPY_BUFFER_SIZE = 64 * 1024;
const ROOTS: string[] = [FILES_ROOT, DATABASE_ROOT];
const EXCLUDED_FILES_PREFIXES: string[] = ['assets/pending', 'assets/trash', 'glmath'];

interface BackupEntry {
  root: string;
  relativePath: string;
  size: number;
}

interface BackupManifest {
  schema: number;
  createdAt: number;
  bundleVersion: string;
  bundleVersionCode?: number;
  entries: BackupEntry[];
}

interface BackupState {
  operation: string;
  phase: string;
  processed: number;
  total: number;
  error?: string;
}

interface RestoreReplacement {
  destination: string;
  rollback: string;
  existed: boolean;
}

/** System backup bridge. The snapshot is deliberately independent of picker/UIAbility APIs. */
export default class NoteBackupAbility extends BackupExtensionAbility {
  private state: BackupState = { operation: 'idle', phase: 'idle', processed: 0, total: 0 };
  private operationChain: Promise<void> = Promise.resolve();
  private databaseStore: relationalStore.RdbStore | null = null;

  async onBackup(): Promise<void> {
    await this.enqueueOperation(async (): Promise<void> => this.createSnapshot());
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    await this.enqueueOperation(async (): Promise<void> => this.restoreSnapshot(bundleVersion));
  }

  async onBackupEx(backupInfo: string): Promise<string> {
    try {
      await this.enqueueOperation(async (): Promise<void> => this.createSnapshot());
      return this.resultJson(true, 'backup', backupInfo);
    } catch (e) {
      return this.resultJson(false, 'backup', backupInfo, e);
    }
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    try {
      await this.enqueueOperation(async (): Promise<void> => this.restoreSnapshot(bundleVersion));
      return this.resultJson(true, 'restore', restoreInfo);
    } catch (e) {
      return this.resultJson(false, 'restore', restoreInfo, e);
    }
  }

  onProcess(): string {
    return JSON.stringify(this.state);
  }

  private enqueueOperation(operation: () => Promise<void>): Promise<void> {
    const next: Promise<void> = this.operationChain.then(operation);
    this.operationChain = next.catch((_error: Object): void => {
    });
    return next;
  }

  async onRelease(scenario: number): Promise<void> {
    await this.enqueueOperation(async (): Promise<void> => {
      const store: relationalStore.RdbStore | null = this.databaseStore;
      this.databaseStore = null;
      if (store !== null) {
        try {
          await store.close();
        } catch (error) {
          console.error(`system backup database close failed: ${JSON.stringify(error)}`);
        }
      }
      this.state = { operation: 'idle', phase: `released:${scenario}`, processed: 0, total: 0 };
    });
  }

  private async createSnapshot(): Promise<void> {
    this.state = { operation: 'backup', phase: 'waiting-for-consistency-locks', processed: 0, total: 0 };
    await assetMutationMutex.runExclusive(async (): Promise<void> => {
      await databaseWriteMutex.runExclusive(async (): Promise<void> => {
        await this.createSnapshotLocked();
      });
    });
  }

  private async createSnapshotLocked(): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const staging: string = this.join(backupDir, STAGING);
    const snapshot: string = this.join(backupDir, SNAPSHOT);
    const previous: string = this.join(backupDir, PREVIOUS);
    const databaseBeforePath: string = this.databaseTemporaryPath(DATABASE_CAPTURE_BEFORE);
    const databaseAfterPath: string = this.databaseTemporaryPath(DATABASE_CAPTURE_AFTER);
    this.state = { operation: 'backup', phase: 'collecting', processed: 0, total: 0 };
    try {
      const currentVersion: BundleVersion = this.currentBundleVersion();
      this.assertRestoreWorkspaceEmpty(backupDir);
      this.removeTreeInside(backupDir, STAGING);
      fileIo.mkdirSync(staging, true);
      const entries: BackupEntry[] = [];
      let totalBytes: number = 0;
      let databaseStore: relationalStore.RdbStore | null = null;
      this.removeDatabaseTemporary(DATABASE_CAPTURE_BEFORE);
      this.removeDatabaseTemporary(DATABASE_CAPTURE_AFTER);
      if (this.isFile(this.join(this.context.databaseDir, DB_NAME))) {
        databaseStore = await this.getDatabaseStore();
        await databaseStore.backup(DATABASE_CAPTURE_BEFORE);
        if (!this.isFile(databaseBeforePath)) {
          throw new Error('RDB backup did not create the first database snapshot');
        }
      }
      const filesPath: string = this.rootPath(FILES_ROOT);
      if (this.isDirectory(filesPath)) {
        this.collect(filesPath, filesPath, FILES_ROOT, entries);
      }
      for (const entry of entries) {
        totalBytes += entry.size;
      }
      if (databaseStore !== null) {
        const databaseSize: number = fileIo.statSync(databaseBeforePath).size;
        if (!Number.isSafeInteger(databaseSize) || databaseSize <= 0) {
          throw new Error('RDB backup created an invalid database snapshot');
        }
        entries.push({ root: DATABASE_ROOT, relativePath: DB_NAME, size: databaseSize });
        totalBytes += databaseSize;
      }
      if (entries.length > MAX_FILES || totalBytes > MAX_BYTES) {
        throw new Error('backup budget exceeded');
      }
      this.state.total = entries.length;
      for (const entry of entries) {
        const source: string = entry.root === DATABASE_ROOT ? databaseBeforePath :
          this.join(this.rootPath(entry.root), entry.relativePath);
        const destination: string = this.join(this.join(staging, entry.root), entry.relativePath);
        this.ensureParent(destination);
        this.copyFileVerified(source, destination, entry.size);
        this.state.processed++;
      }
      if (databaseStore !== null) {
        await databaseStore.backup(DATABASE_CAPTURE_AFTER);
        if (!this.isFile(databaseAfterPath) || !this.filesEqual(databaseBeforePath, databaseAfterPath)) {
          throw new Error('database changed while the system backup snapshot was collected');
        }
      }
      const manifest: BackupManifest = {
        schema: CURRENT_MANIFEST_SCHEMA,
        createdAt: Date.now(),
        bundleVersion: currentVersion.name,
        bundleVersionCode: currentVersion.code,
        entries: entries,
      };
      this.writeText(this.join(staging, MANIFEST), JSON.stringify(manifest));
      this.state.phase = 'publishing';
      this.removeTreeInside(backupDir, PREVIOUS);
      const hadSnapshot: boolean = this.isDirectory(snapshot) || this.isFile(snapshot);
      if (hadSnapshot) {
        fileIo.renameSync(snapshot, previous);
      }
      try {
        fileIo.renameSync(staging, snapshot);
      } catch (e) {
        if (hadSnapshot && !this.isDirectory(snapshot) && !this.isFile(snapshot) && this.isDirectory(previous)) {
          fileIo.renameSync(previous, snapshot);
        }
        throw new Error(`backup snapshot publish failed: ${JSON.stringify(e)}`);
      }
      this.removeTreeInside(backupDir, PREVIOUS);
      this.state.phase = 'complete';
    } catch (e) {
      // A failed collection/copy must not leave an apparently usable staging tree.
      try { this.removeTreeInside(backupDir, STAGING); } catch (_cleanupError) { }
      this.state.phase = 'failed';
      this.state.error = this.errorMessage(e);
      throw new Error(this.state.error);
    } finally {
      try { this.removeDatabaseTemporary(DATABASE_CAPTURE_BEFORE); } catch (_cleanupError) { }
      try { this.removeDatabaseTemporary(DATABASE_CAPTURE_AFTER); } catch (_cleanupError) { }
    }
  }

  private async restoreSnapshot(bundleVersion: BundleVersion): Promise<void> {
    this.state = { operation: 'restore', phase: 'waiting-for-consistency-locks', processed: 0, total: 0 };
    await assetMutationMutex.runExclusive(async (): Promise<void> => {
      await databaseWriteMutex.runExclusive(async (): Promise<void> => {
        await this.restoreSnapshotLocked(bundleVersion);
      });
    });
  }

  private async restoreSnapshotLocked(bundleVersion: BundleVersion): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const snapshot: string = this.join(backupDir, SNAPSHOT);
    const manifestPath: string = this.join(snapshot, MANIFEST);
    this.state = { operation: 'restore', phase: 'reading-manifest', processed: 0, total: 0 };
    try {
      if (!this.isFile(manifestPath)) {
        throw new Error('backup manifest is missing');
      }
      const manifest: BackupManifest = JSON.parse(fileIo.readTextSync(manifestPath)) as BackupManifest;
      this.validateManifest(manifest);
      const currentVersion: BundleVersion = this.currentBundleVersion();
      this.validateRestoreVersion(manifest, bundleVersion, currentVersion);
      this.state.total = manifest.entries.length;
      // Validate every source before writing any destination file. A late mismatch must not
      // leave the application with a partially restored snapshot.
      for (const entry of manifest.entries) {
        const source: string = this.join(this.join(snapshot, entry.root), entry.relativePath);
        if (!this.isFile(source) || fileIo.statSync(source).size !== entry.size) {
          throw new Error(`backup object mismatch: ${entry.root}/${entry.relativePath}`);
        }
      }
      this.assertRestoreWorkspaceEmpty(backupDir);
      this.state.phase = 'restoring';
      if (manifest.schema === CURRENT_MANIFEST_SCHEMA) {
        await this.restoreCurrentSnapshot(snapshot, manifest.entries);
      } else {
        this.restoreLegacySnapshot(snapshot, manifest.entries);
      }
      this.state.phase = `complete:${bundleVersion.name}`;
    } catch (e) {
      this.state.phase = 'failed';
      this.state.error = this.errorMessage(e);
      throw new Error(this.state.error);
    }
  }

  private restoreLegacySnapshot(snapshot: string, entries: BackupEntry[]): void {
    const backupDir: string = this.context.backupDir;
    const rollbackRoot: string = this.join(backupDir, RESTORE_ROLLBACK);
    const replaced: RestoreReplacement[] = [];
    try {
      fileIo.mkdirSync(rollbackRoot, true);
      for (const entry of entries) {
        const source: string = this.join(this.join(snapshot, entry.root), entry.relativePath);
        const destination: string = this.join(this.rootPath(entry.root), entry.relativePath);
        this.replaceFile(source, destination,
          this.join(this.join(rollbackRoot, entry.root), entry.relativePath), entry.size, replaced);
        this.state.processed++;
      }
    } catch (e) {
      const rollbackComplete: boolean = this.rollbackFiles(replaced);
      if (rollbackComplete) {
        try { this.removeTreeInside(backupDir, RESTORE_ROLLBACK); } catch (_cleanupError) { }
      } else {
        console.error(`legacy backup restore recovery preserved at ${rollbackRoot}`);
      }
      throw new Error(`legacy backup restore apply failed: ${JSON.stringify(e)}`);
    }
    try {
      this.removeTreeInside(backupDir, RESTORE_ROLLBACK);
    } catch (cleanupError) {
      console.error(`legacy backup restore rollback cleanup failed: ${JSON.stringify(cleanupError)}`);
    }
  }

  private async restoreCurrentSnapshot(snapshot: string, entries: BackupEntry[]): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const rollbackRoot: string = this.join(backupDir, RESTORE_ROLLBACK);
    const replaced: RestoreReplacement[] = [];
    const filesEntries: BackupEntry[] = [];
    let databaseEntry: BackupEntry | null = null;
    for (const entry of entries) {
      if (entry.root === DATABASE_ROOT) {
        databaseEntry = entry;
      } else {
        filesEntries.push(entry);
      }
    }
    let databaseStore: relationalStore.RdbStore | null = null;
    let databaseRollbackReady: boolean = false;
    let databaseRestoreAttempted: boolean = false;
    let databaseRollbackComplete: boolean = true;
    try {
      fileIo.mkdirSync(rollbackRoot, true);
      if (databaseEntry !== null) {
        databaseStore = await this.getDatabaseStore();
        this.removeDatabaseTemporary(DATABASE_RESTORE_SOURCE);
        const source: string = this.join(
          this.join(snapshot, databaseEntry.root), databaseEntry.relativePath);
        this.copyFileVerified(source, this.databaseTemporaryPath(DATABASE_RESTORE_SOURCE),
          databaseEntry.size);
        await databaseStore.backup(DATABASE_RESTORE_ROLLBACK);
        if (!this.isFile(this.databaseTemporaryPath(DATABASE_RESTORE_ROLLBACK))) {
          throw new Error('RDB backup did not create the restore rollback snapshot');
        }
        databaseRollbackReady = true;
      }
      for (const entry of filesEntries) {
        const source: string = this.join(this.join(snapshot, entry.root), entry.relativePath);
        const destination: string = this.join(this.rootPath(entry.root), entry.relativePath);
        this.replaceFile(source, destination,
          this.join(this.join(rollbackRoot, entry.root), entry.relativePath), entry.size, replaced);
        this.state.processed++;
      }
      if (databaseStore !== null) {
        databaseRestoreAttempted = true;
        await databaseStore.restore(DATABASE_RESTORE_SOURCE);
        this.state.processed++;
      }
    } catch (e) {
      if (databaseRestoreAttempted && databaseRollbackReady && databaseStore !== null) {
        try {
          await databaseStore.restore(DATABASE_RESTORE_ROLLBACK);
        } catch (rollbackError) {
          databaseRollbackComplete = false;
          console.error(`system backup database rollback failed: ${JSON.stringify(rollbackError)}`);
        }
      }
      const filesRollbackComplete: boolean = this.rollbackFiles(replaced);
      if (filesRollbackComplete) {
        try { this.removeTreeInside(backupDir, RESTORE_ROLLBACK); } catch (_cleanupError) { }
      } else {
        console.error(`system backup file recovery preserved at ${rollbackRoot}`);
      }
      throw new Error(`backup restore apply failed: ${JSON.stringify(e)}`);
    } finally {
      try { this.removeDatabaseTemporary(DATABASE_RESTORE_SOURCE); } catch (_cleanupError) { }
      if (databaseRollbackComplete) {
        try { this.removeDatabaseTemporary(DATABASE_RESTORE_ROLLBACK); } catch (_cleanupError) { }
      } else {
        console.error(`system backup database recovery preserved at ${
          this.databaseTemporaryPath(DATABASE_RESTORE_ROLLBACK)}`);
      }
    }
    try {
      this.removeTreeInside(backupDir, RESTORE_ROLLBACK);
    } catch (cleanupError) {
      console.error(`system backup restore rollback cleanup failed: ${JSON.stringify(cleanupError)}`);
    }
  }

  private collect(rootPath: string, current: string, rootName: string, entries: BackupEntry[]): void {
    const children: string[] = fileIo.listFileSync(current, { recursion: false });
    for (const item of children) {
      const child: string = item.indexOf('/') >= 0 || item.indexOf('\\') >= 0 ? item : this.join(current, item);
      const relative: string = child.substring(rootPath.length + 1);
      this.assertRelative(relative);
      if (rootName === FILES_ROOT && this.isExcludedFilesPath(relative)) {
        continue;
      }
      if (this.isDirectory(child)) {
        this.collect(rootPath, child, rootName, entries);
      } else if (this.isFile(child)) {
        const size: number = fileIo.statSync(child).size;
        entries.push({ root: rootName, relativePath: relative, size: size });
      }
      if (entries.length > MAX_FILES) {
        throw new Error('backup file count exceeded');
      }
    }
  }

  private validateManifest(manifest: BackupManifest): void {
    if ((manifest.schema !== LEGACY_MANIFEST_SCHEMA && manifest.schema !== CURRENT_MANIFEST_SCHEMA) ||
      !Number.isSafeInteger(manifest.createdAt) || manifest.createdAt <= 0 ||
      typeof manifest.bundleVersion !== 'string' || !this.isValidVersionName(manifest.bundleVersion) ||
      (manifest.bundleVersionCode !== undefined && !this.isValidVersionCode(manifest.bundleVersionCode)) ||
      (manifest.schema === CURRENT_MANIFEST_SCHEMA && manifest.bundleVersionCode === undefined) ||
      !Array.isArray(manifest.entries) || manifest.entries.length > MAX_FILES) {
      throw new Error('invalid backup manifest');
    }
    let bytes: number = 0;
    let databaseEntries: number = 0;
    const seen: Set<string> = new Set<string>();
    for (const entry of manifest.entries) {
      if (ROOTS.indexOf(entry.root) < 0 || !Number.isSafeInteger(entry.size) || entry.size < 0) {
        throw new Error('invalid backup entry');
      }
      this.assertRelative(entry.relativePath);
      const identity: string = `${entry.root}:${entry.relativePath}`;
      if (seen.has(identity)) {
        throw new Error(`duplicate backup entry: ${identity}`);
      }
      seen.add(identity);
      if (manifest.schema === CURRENT_MANIFEST_SCHEMA) {
        if (entry.root === DATABASE_ROOT) {
          databaseEntries++;
          if (databaseEntries > 1 || entry.relativePath !== DB_NAME || entry.size <= 0) {
            throw new Error('invalid current database backup entry');
          }
        } else if (this.isExcludedFilesPath(entry.relativePath)) {
          throw new Error(`transient file cannot be restored: ${entry.relativePath}`);
        }
      }
      bytes += entry.size;
      if (bytes > MAX_BYTES) {
        throw new Error('backup manifest exceeds budget');
      }
    }
  }

  private async getDatabaseStore(): Promise<relationalStore.RdbStore> {
    if (this.databaseStore === null) {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.databaseStore = await relationalStore.getRdbStore(this.context, config);
    }
    return this.databaseStore;
  }

  private databaseTemporaryPath(name: string): string {
    if (name.length === 0 || name.indexOf('/') >= 0 || name.indexOf('\\') >= 0 || name.indexOf(':') >= 0) {
      throw new Error(`unsafe database temporary name: ${name}`);
    }
    return this.join(this.context.databaseDir, name);
  }

  private assertRestoreWorkspaceEmpty(backupDir: string): void {
    const rollbackRoot: string = this.join(backupDir, RESTORE_ROLLBACK);
    if (this.isDirectory(rollbackRoot) || this.isFile(rollbackRoot)) {
      throw new Error(`unresolved file restore recovery exists: ${rollbackRoot}`);
    }
    const databaseRollback: string = this.databaseTemporaryPath(DATABASE_RESTORE_ROLLBACK);
    if (this.isDirectory(databaseRollback) || this.isFile(databaseRollback)) {
      throw new Error(`unresolved database restore recovery exists: ${databaseRollback}`);
    }
  }

  private removeDatabaseTemporary(name: string): void {
    const path: string = this.databaseTemporaryPath(name);
    if (this.isDirectory(path)) {
      throw new Error(`database temporary path is a directory: ${name}`);
    }
    if (this.isFile(path)) {
      fileIo.unlinkSync(path);
    }
  }

  private isExcludedFilesPath(relativePath: string): boolean {
    const normalized: string = relativePath.replace(/\\/g, '/');
    for (const prefix of EXCLUDED_FILES_PREFIXES) {
      if (normalized === prefix || normalized.startsWith(prefix + '/')) {
        return true;
      }
    }
    return false;
  }

  private copyFileVerified(source: string, destination: string, expectedSize: number): void {
    if (!this.isFile(source) || fileIo.statSync(source).size !== expectedSize) {
      throw new Error(`backup source changed before copy: ${source}`);
    }
    fileIo.copyFileSync(source, destination);
    if (!this.isFile(destination) || fileIo.statSync(destination).size !== expectedSize ||
      !this.filesEqual(source, destination)) {
      throw new Error(`backup copy verification failed: ${destination}`);
    }
  }

  private filesEqual(leftPath: string, rightPath: string): boolean {
    if (!this.isFile(leftPath) || !this.isFile(rightPath)) {
      return false;
    }
    const size: number = fileIo.statSync(leftPath).size;
    if (size !== fileIo.statSync(rightPath).size) {
      return false;
    }
    const left: fileIo.File = fileIo.openSync(leftPath, fileIo.OpenMode.READ_ONLY);
    try {
      const right: fileIo.File = fileIo.openSync(rightPath, fileIo.OpenMode.READ_ONLY);
      try {
        let total: number = 0;
        while (total < size) {
          const requested: number = Math.min(COPY_BUFFER_SIZE, size - total);
          const leftBuffer: ArrayBuffer = new ArrayBuffer(requested);
          const rightBuffer: ArrayBuffer = new ArrayBuffer(requested);
          const leftRead: number = fileIo.readSync(left.fd, leftBuffer);
          const rightRead: number = fileIo.readSync(right.fd, rightBuffer);
          if (leftRead <= 0 || leftRead !== rightRead || leftRead > requested) {
            return false;
          }
          const leftBytes: Uint8Array = new Uint8Array(leftBuffer, 0, leftRead);
          const rightBytes: Uint8Array = new Uint8Array(rightBuffer, 0, rightRead);
          for (let index: number = 0; index < leftRead; index++) {
            if (leftBytes[index] !== rightBytes[index]) {
              return false;
            }
          }
          total += leftRead;
        }
        return total === size;
      } finally {
        fileIo.closeSync(right);
      }
    } finally {
      fileIo.closeSync(left);
    }
  }

  private replaceFile(source: string, destination: string, rollback: string, expectedSize: number,
    replaced: RestoreReplacement[]): void {
    if (this.isDirectory(destination)) {
      throw new Error(`restore destination is a directory: ${destination}`);
    }
    const existed: boolean = this.isFile(destination);
    if (existed) {
      this.ensureParent(rollback);
      fileIo.renameSync(destination, rollback);
    }
    // Register before copying so a partially created new file is removed on failure.
    const replacement: RestoreReplacement = {
      destination: destination,
      rollback: rollback,
      existed: existed,
    };
    replaced.push(replacement);
    this.ensureParent(destination);
    this.copyFileVerified(source, destination, expectedSize);
  }

  private rollbackFiles(replaced: RestoreReplacement[]): boolean {
    let complete: boolean = true;
    for (let index: number = replaced.length - 1; index >= 0; index--) {
      const item: RestoreReplacement = replaced[index];
      try {
        if (this.isDirectory(item.destination)) {
          throw new Error(`restore rollback destination became a directory: ${item.destination}`);
        }
        if (this.isFile(item.destination)) {
          fileIo.unlinkSync(item.destination);
        }
        if (item.existed) {
          if (!this.isFile(item.rollback)) {
            throw new Error(`restore rollback source is missing: ${item.rollback}`);
          }
          this.ensureParent(item.destination);
          fileIo.renameSync(item.rollback, item.destination);
          if (!this.isFile(item.destination)) {
            throw new Error(`restore rollback destination was not restored: ${item.destination}`);
          }
        }
      } catch (rollbackError) {
        complete = false;
        console.error(`system backup file rollback failed: ${JSON.stringify(rollbackError)}`);
      }
    }
    return complete;
  }

  private currentBundleVersion(): BundleVersion {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    const version: BundleVersion = { code: info.versionCode, name: info.versionName };
    this.assertBundleVersion(version, 'current bundle');
    return version;
  }

  private validateRestoreVersion(manifest: BackupManifest, source: BundleVersion, current: BundleVersion): void {
    this.assertBundleVersion(source, 'restore source');
    this.assertBundleVersion(current, 'current bundle');
    if (manifest.bundleVersion !== source.name) {
      throw new Error('backup source version name mismatch');
    }
    if (manifest.bundleVersionCode !== undefined && manifest.bundleVersionCode !== source.code) {
      throw new Error('backup source version code mismatch');
    }
    if (source.code > current.code) {
      throw new Error('backup was created by a newer app version');
    }
  }

  private assertBundleVersion(version: BundleVersion, label: string): void {
    if (!this.isValidVersionCode(version.code) || typeof version.name !== 'string' ||
      !this.isValidVersionName(version.name)) {
      throw new Error(`invalid ${label} version`);
    }
  }

  private isValidVersionCode(value: number): boolean {
    return Number.isSafeInteger(value) && value >= 0 && value <= MAX_VERSION_CODE;
  }

  private isValidVersionName(value: string): boolean {
    if (value.length === 0 || value !== value.trim() ||
      new util.TextEncoder().encodeInto(value).byteLength > MAX_VERSION_NAME_BYTES) {
      return false;
    }
    for (let index: number = 0; index < value.length; index++) {
      const code: number = value.charCodeAt(index);
      if (code <= 31 || (code >= 127 && code <= 159)) {
        return false;
      }
    }
    return true;
  }

  private rootPath(root: string): string {
    if (root === FILES_ROOT) {
      return this.context.filesDir;
    }
    if (root === DATABASE_ROOT) {
      return this.context.databaseDir;
    }
    throw new Error(`unknown backup root: ${root}`);
  }

  private assertRelative(path: string): void {
    if (path.length === 0 || path.startsWith('/') || path.startsWith('\\') || path.indexOf(':') >= 0) {
      throw new Error(`unsafe backup path: ${path}`);
    }
    const segments: string[] = path.replace(/\\/g, '/').split('/');
    for (const segment of segments) {
      if (segment.length === 0 || segment === '.' || segment === '..') {
        throw new Error(`unsafe backup path: ${path}`);
      }
    }
  }

  private join(base: string, child: string): string {
    return `${base.replace(/[\\/]$/, '')}/${child.replace(/^[\\/]+/, '')}`;
  }

  private ensureParent(path: string): void {
    const slash: number = path.lastIndexOf('/');
    if (slash > 0) {
      fileIo.mkdirSync(path.substring(0, slash), true);
    }
  }

  private isDirectory(path: string): boolean {
    try { return fileIo.statSync(path).isDirectory(); } catch (e) { return false; }
  }

  private isFile(path: string): boolean {
    try { return !fileIo.statSync(path).isDirectory(); } catch (e) { return false; }
  }

  private removeTreeInside(parent: string, child: string): void {
    const target: string = this.join(parent, child);
    if (!this.isDirectory(target)) {
      try { fileIo.unlinkSync(target); } catch (e) { /* absent */ }
      return;
    }
    for (const item of fileIo.listFileSync(target, { recursion: false })) {
      const path: string = item.indexOf('/') >= 0 ? item : this.join(target, item);
      if (this.isDirectory(path)) {
        this.removeTreeInside(target, path.substring(target.length + 1));
      } else {
        fileIo.unlinkSync(path);
      }
    }
    fileIo.rmdirSync(target);
  }

  private writeText(path: string, value: string): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    const bytes: Uint8Array = new util.TextEncoder().encodeInto(value);
    const exact: ArrayBuffer = bytes.buffer.slice(
      bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    try { fileIo.writeSync(file.fd, exact); } finally { fileIo.closeSync(file); }
  }

  private errorMessage(error: Object): string {
    return error instanceof Error ? error.message : String(error);
  }

  private resultJson(success: boolean, operation: string, input: string, error?: Object): string {
    return JSON.stringify({ success: success, operation: operation, input: input, process: this.state, error: error === undefined ? '' : String(error) });
  }
}
