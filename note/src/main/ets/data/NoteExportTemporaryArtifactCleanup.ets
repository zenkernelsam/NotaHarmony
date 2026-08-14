import { fileIo } from '@kit.CoreFileKit';

const NOTE_EXPORT_ARTIFACT_NAME: RegExp = /^export_\d+\.note$/;

export interface NoteExportTemporaryArtifactCleanupReport {
  scanned: number;
  removed: number;
  skipped: number;
  failed: number;
}

// Original 1.0.3 owns private export/cache artifacts and sweeps them after interruption
// (g64 + ExportSweepWorker, and gv2 case 2). Harmony export picker staging lives directly
// in Context.tempDir and has no valid consumer after this process dies, so the first database
// initialization reclaims only files produced by NoteExporter.exportToFile().
export function cleanupInterruptedNoteExports(tempRoot: string):
  NoteExportTemporaryArtifactCleanupReport {
  const report: NoteExportTemporaryArtifactCleanupReport = {
    scanned: 0, removed: 0, skipped: 0, failed: 0,
  };
  const normalizedRoot: string = normalizePath(tempRoot);
  if (normalizedRoot.length === 0) {
    report.failed++;
    console.error('Note export temporary artifact cleanup refused an empty temp root');
    return report;
  }
  cleanupExportDirectory(normalizedRoot, report);
  return report;
}

function cleanupExportDirectory(directory: string,
  report: NoteExportTemporaryArtifactCleanupReport): void {
  try {
    if (!fileIo.accessSync(directory)) {
      return;
    }
    if (!fileIo.statSync(directory).isDirectory()) {
      report.failed++;
      console.error(`Note export temporary artifact path is not a directory: ${directory}`);
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
      if (!NOTE_EXPORT_ARTIFACT_NAME.test(name)) {
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
        console.error(`Note export temporary artifact cleanup failed: path=${candidate}, ` +
          `error=${JSON.stringify(error)}`);
      }
    }
  } catch (error) {
    report.failed++;
    console.error(`Note export temporary artifact directory cleanup failed: path=${directory}, ` +
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

function normalizePath(path: string): string {
  return path.replace(/\\/g, '/').replace(/\/+$/, '');
}
