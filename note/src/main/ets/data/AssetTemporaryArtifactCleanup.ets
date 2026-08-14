import { fileIo } from '@kit.CoreFileKit';

const PENDING_DIRECTORY: string = 'assets/pending';
const TRASH_DIRECTORY: string = 'assets/trash';
const PENDING_ASSET_NAME: RegExp = /^pending_asset_\d+_\d+\.tmp$/;
const PENDING_RECORDING_NAME: RegExp = /^pending_recording_\d+_\d+\.tmp$/;
const TRASH_ASSET_NAME: RegExp = /^deleted_asset_\d+_\d+_\d+\.tmp$/;

export interface AssetTemporaryArtifactCleanupReport {
  scanned: number;
  removed: number;
  skipped: number;
  failed: number;
}

// Original 1.0.3 removes private interrupted-work files when the owning managers start
// (gv2 cases 2 and 13). These Harmony directories contain only pre-publication or detached
// artifacts, so the first database initialization is the corresponding safe process boundary.
export function cleanupInterruptedAssetArtifacts(filesRoot: string):
  AssetTemporaryArtifactCleanupReport {
  const report: AssetTemporaryArtifactCleanupReport = {
    scanned: 0, removed: 0, skipped: 0, failed: 0,
  };
  const normalizedRoot: string = normalizePath(filesRoot);
  if (normalizedRoot.length === 0) {
    report.failed++;
    console.error('Asset temporary artifact cleanup refused an empty files root');
    return report;
  }
  cleanupDirectory(joinPath(normalizedRoot, PENDING_DIRECTORY), false, report);
  cleanupDirectory(joinPath(normalizedRoot, TRASH_DIRECTORY), true, report);
  return report;
}

function cleanupDirectory(directory: string, trash: boolean,
  report: AssetTemporaryArtifactCleanupReport): void {
  try {
    if (!fileIo.accessSync(directory)) {
      return;
    }
    if (!fileIo.statSync(directory).isDirectory()) {
      report.failed++;
      console.error(`Asset temporary artifact path is not a directory: ${directory}`);
      return;
    }
    const children: string[] = fileIo.listFileSync(directory, { recursion: false });
    for (const child of children) {
      report.scanned++;
      const candidate: string | null = directChildPath(directory, child);
      if (candidate === null) {
        report.skipped++;
        continue;
      }
      const name: string = baseName(candidate);
      const expected: boolean = trash ? TRASH_ASSET_NAME.test(name) :
        PENDING_ASSET_NAME.test(name) || PENDING_RECORDING_NAME.test(name);
      if (!expected) {
        report.skipped++;
        continue;
      }
      try {
        if (!fileIo.statSync(candidate).isFile()) {
          report.skipped++;
          continue;
        }
        fileIo.unlinkSync(candidate);
        report.removed++;
      } catch (error) {
        report.failed++;
        console.error(`Asset temporary artifact cleanup failed: path=${candidate}, ` +
          `error=${JSON.stringify(error)}`);
      }
    }
  } catch (error) {
    report.failed++;
    console.error(`Asset temporary artifact directory cleanup failed: path=${directory}, ` +
      `error=${JSON.stringify(error)}`);
  }
}

function directChildPath(directory: string, listed: string): string | null {
  const normalizedDirectory: string = normalizePath(directory);
  const normalizedListed: string = normalizePath(listed);
  let candidate: string;
  if (normalizedListed.startsWith(normalizedDirectory + '/')) {
    candidate = normalizedListed;
  } else if (normalizedListed.indexOf('/') < 0) {
    candidate = normalizedDirectory + '/' + normalizedListed;
  } else {
    return null;
  }
  const relative: string = candidate.substring(normalizedDirectory.length + 1);
  if (relative.length === 0 || relative.indexOf('/') >= 0 || relative === '.' || relative === '..') {
    return null;
  }
  return candidate;
}

function baseName(path: string): string {
  const normalized: string = normalizePath(path);
  const separator: number = normalized.lastIndexOf('/');
  return separator < 0 ? normalized : normalized.substring(separator + 1);
}

function joinPath(root: string, relative: string): string {
  return normalizePath(root).replace(/\/+$/, '') + '/' + normalizePath(relative).replace(/^\/+/, '');
}

function normalizePath(path: string): string {
  return path.replace(/\\/g, '/').replace(/\/+$/, '');
}
