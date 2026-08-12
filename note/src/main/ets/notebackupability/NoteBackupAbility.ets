import { BackupExtensionAbility, BundleVersion, fileIo } from '@kit.CoreFileKit';
import { bundleManager } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

const MANIFEST = 'nota-backup-manifest.json';
const SNAPSHOT = 'nota-snapshot';
const STAGING = 'nota-snapshot.staging';
const RESTORE_ROLLBACK = 'nota-restore.rollback';
const PREVIOUS = 'nota-snapshot.previous';
const MAX_FILES = 10000;
const MAX_BYTES = 256 * 1024 * 1024;
const MAX_VERSION_CODE = 2147483647;
const MAX_VERSION_NAME_BYTES = 127;
const ROOTS: string[] = ['filesDir', 'databaseDir'];

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

/** System backup bridge. The snapshot is deliberately independent of picker/UIAbility APIs. */
export default class NoteBackupAbility extends BackupExtensionAbility {
  private state: BackupState = { operation: 'idle', phase: 'idle', processed: 0, total: 0 };
  private operationChain: Promise<void> = Promise.resolve();

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
    this.state = { operation: 'idle', phase: `released:${scenario}`, processed: 0, total: 0 };
    await Promise.resolve();
  }

  private async createSnapshot(): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const staging: string = this.join(backupDir, STAGING);
    const snapshot: string = this.join(backupDir, SNAPSHOT);
    const previous: string = this.join(backupDir, PREVIOUS);
    this.state = { operation: 'backup', phase: 'collecting', processed: 0, total: 0 };
    try {
      const currentVersion: BundleVersion = this.currentBundleVersion();
      this.removeTreeInside(backupDir, STAGING);
      fileIo.mkdirSync(staging, true);
      const entries: BackupEntry[] = [];
      let totalBytes: number = 0;
      for (const rootName of ROOTS) {
        const rootPath: string = this.rootPath(rootName);
        if (!this.isDirectory(rootPath)) {
          continue;
        }
        this.collect(rootPath, rootPath, rootName, entries);
        for (const entry of entries) {
          if (entry.root === rootName) {
            totalBytes += entry.size;
          }
        }
        if (entries.length > MAX_FILES || totalBytes > MAX_BYTES) {
          throw new Error('backup budget exceeded');
        }
      }
      this.state.total = entries.length;
      for (const entry of entries) {
        const source: string = this.join(this.rootPath(entry.root), entry.relativePath);
        const destination: string = this.join(this.join(staging, entry.root), entry.relativePath);
        this.ensureParent(destination);
        fileIo.copyFileSync(source, destination);
        this.state.processed++;
      }
      const manifest: BackupManifest = {
        schema: 1,
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
      this.state.error = String(e);
      throw e;
    }
  }

  private async restoreSnapshot(bundleVersion: BundleVersion): Promise<void> {
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
      this.state.phase = 'restoring';
      const rollbackRoot: string = this.join(backupDir, RESTORE_ROLLBACK);
      const replaced: Array<{ destination: string; rollback: string; existed: boolean }> = [];
      try {
        this.removeTreeInside(backupDir, RESTORE_ROLLBACK);
        fileIo.mkdirSync(rollbackRoot, true);
        for (const entry of manifest.entries) {
          const source: string = this.join(this.join(snapshot, entry.root), entry.relativePath);
          const destination: string = this.join(this.rootPath(entry.root), entry.relativePath);
          const rollback: string = this.join(this.join(rollbackRoot, entry.root), entry.relativePath);
          const existed: boolean = this.isFile(destination);
          if (existed) {
            this.ensureParent(rollback);
            fileIo.renameSync(destination, rollback);
          }
          // Register before copying so a partially created new file is removed on failure.
          replaced.push({ destination: destination, rollback: rollback, existed: existed });
          this.ensureParent(destination);
          fileIo.copyFileSync(source, destination);
          this.state.processed++;
        }
        this.removeTreeInside(backupDir, RESTORE_ROLLBACK);
      } catch (e) {
        for (let index: number = replaced.length - 1; index >= 0; index--) {
          const item = replaced[index];
          try {
            if (this.isFile(item.destination)) {
              fileIo.unlinkSync(item.destination);
            }
            if (item.existed && this.isFile(item.rollback)) {
              this.ensureParent(item.destination);
              fileIo.renameSync(item.rollback, item.destination);
            }
          } catch (_rollbackError) {
            // Preserve the original restore failure; device fault injection reports rollback loss.
          }
        }
        try { this.removeTreeInside(backupDir, RESTORE_ROLLBACK); } catch (_cleanupError) { }
        throw new Error(`backup restore apply failed: ${JSON.stringify(e)}`);
      }
      this.state.phase = `complete:${bundleVersion.name}`;
    } catch (e) {
      this.state.phase = 'failed';
      this.state.error = String(e);
      throw e;
    }
  }

  private collect(rootPath: string, current: string, rootName: string, entries: BackupEntry[]): void {
    const children: string[] = fileIo.listFileSync(current, { recursion: false });
    for (const item of children) {
      const child: string = item.indexOf('/') >= 0 || item.indexOf('\\') >= 0 ? item : this.join(current, item);
      const relative: string = child.substring(rootPath.length + 1);
      this.assertRelative(relative);
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
    if (manifest.schema !== 1 || !Number.isSafeInteger(manifest.createdAt) || manifest.createdAt <= 0 ||
      typeof manifest.bundleVersion !== 'string' || !this.isValidVersionName(manifest.bundleVersion) ||
      (manifest.bundleVersionCode !== undefined && !this.isValidVersionCode(manifest.bundleVersionCode)) ||
      !Array.isArray(manifest.entries) || manifest.entries.length > MAX_FILES) {
      throw new Error('invalid backup manifest');
    }
    let bytes: number = 0;
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
      bytes += entry.size;
      if (bytes > MAX_BYTES) {
        throw new Error('backup manifest exceeds budget');
      }
    }
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
    if (root === 'filesDir') {
      return this.context.filesDir;
    }
    return this.context.databaseDir;
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

  private resultJson(success: boolean, operation: string, input: string, error?: Object): string {
    return JSON.stringify({ success: success, operation: operation, input: input, process: this.state, error: error === undefined ? '' : String(error) });
  }
}
