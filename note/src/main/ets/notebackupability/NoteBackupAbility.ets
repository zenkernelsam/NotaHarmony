import { BackupExtensionAbility, BundleVersion, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

const MANIFEST = 'nota-backup-manifest.json';
const SNAPSHOT = 'nota-snapshot';
const STAGING = 'nota-snapshot.staging';
const MAX_FILES = 10000;
const MAX_BYTES = 256 * 1024 * 1024;
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

  async onBackup(): Promise<void> {
    await this.createSnapshot();
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    await this.restoreSnapshot(bundleVersion);
  }

  async onBackupEx(backupInfo: string): Promise<string> {
    try {
      await this.createSnapshot();
      return this.resultJson(true, 'backup', backupInfo);
    } catch (e) {
      return this.resultJson(false, 'backup', backupInfo, e);
    }
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    try {
      await this.restoreSnapshot(bundleVersion);
      return this.resultJson(true, 'restore', restoreInfo);
    } catch (e) {
      return this.resultJson(false, 'restore', restoreInfo, e);
    }
  }

  onProcess(): string {
    return JSON.stringify(this.state);
  }

  async onRelease(scenario: number): Promise<void> {
    this.state = { operation: 'idle', phase: `released:${scenario}`, processed: 0, total: 0 };
    await Promise.resolve();
  }

  private async createSnapshot(): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const staging: string = this.join(backupDir, STAGING);
    const snapshot: string = this.join(backupDir, SNAPSHOT);
    this.state = { operation: 'backup', phase: 'collecting', processed: 0, total: 0 };
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
      bundleVersion: '1.0.0',
      entries: entries,
    };
    this.writeText(this.join(staging, MANIFEST), JSON.stringify(manifest));
    this.state.phase = 'publishing';
    this.removeTreeInside(backupDir, SNAPSHOT);
    fileIo.renameSync(staging, snapshot);
    this.state.phase = 'complete';
  }

  private async restoreSnapshot(bundleVersion: BundleVersion): Promise<void> {
    const backupDir: string = this.context.backupDir;
    const snapshot: string = this.join(backupDir, SNAPSHOT);
    const manifestPath: string = this.join(snapshot, MANIFEST);
    this.state = { operation: 'restore', phase: 'reading-manifest', processed: 0, total: 0 };
    if (!this.isFile(manifestPath)) {
      throw new Error('backup manifest is missing');
    }
    const manifest: BackupManifest = JSON.parse(fileIo.readTextSync(manifestPath)) as BackupManifest;
    this.validateManifest(manifest);
    this.state.total = manifest.entries.length;
    for (const entry of manifest.entries) {
      const source: string = this.join(this.join(snapshot, entry.root), entry.relativePath);
      const destination: string = this.join(this.rootPath(entry.root), entry.relativePath);
      if (!this.isFile(source) || fileIo.statSync(source).size !== entry.size) {
        throw new Error(`backup object mismatch: ${entry.root}/${entry.relativePath}`);
      }
      this.ensureParent(destination);
      fileIo.copyFileSync(source, destination);
      this.state.processed++;
    }
    this.state.phase = `complete:${bundleVersion.name}`;
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
    if (manifest.schema !== 1 || !Array.isArray(manifest.entries) || manifest.entries.length > MAX_FILES) {
      throw new Error('invalid backup manifest');
    }
    let bytes: number = 0;
    const seen: Set<string> = new Set<string>();
    for (const entry of manifest.entries) {
      if (ROOTS.indexOf(entry.root) < 0 || !Number.isFinite(entry.size) || entry.size < 0) {
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

  private rootPath(root: string): string {
    if (root === 'filesDir') {
      return this.context.filesDir;
    }
    return this.context.databaseDir;
  }

  private assertRelative(path: string): void {
    if (path.length === 0 || path.startsWith('/') || path.startsWith('\\') || path.indexOf('..') >= 0 || path.indexOf(':') >= 0) {
      throw new Error(`unsafe backup path: ${path}`);
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
