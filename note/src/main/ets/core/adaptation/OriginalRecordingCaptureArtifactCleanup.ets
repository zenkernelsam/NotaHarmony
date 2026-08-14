import { fileIo } from '@kit.CoreFileKit';

const MICROPHONE_CAPTURE_NAME: RegExp = /^recording_\d+_\d+\.m4a$/;
const INTERNAL_AUDIO_CAPTURE_NAME: RegExp = /^internal_recording_\d+_\d+\.m4a$/;

export interface OriginalRecordingCaptureArtifactCleanupReport {
  scanned: number;
  removed: number;
  skipped: number;
  failed: number;
}

// Original 1.0.3 clears temp_recordings and AudioCaptures when the recording owner starts
// (gv2 case 13). Harmony records into Context.tempDir instead, so the first database
// initialization is the process boundary for reclaiming only our interrupted capture files.
export function cleanupInterruptedOriginalRecordingCaptures(tempRoot: string):
  OriginalRecordingCaptureArtifactCleanupReport {
  const report: OriginalRecordingCaptureArtifactCleanupReport = {
    scanned: 0, removed: 0, skipped: 0, failed: 0,
  };
  const normalizedRoot: string = normalizePath(tempRoot);
  if (normalizedRoot.length === 0) {
    report.failed++;
    console.error('Original recording capture cleanup refused an empty temp root');
    return report;
  }
  cleanupCaptureDirectory(normalizedRoot, report);
  return report;
}

function cleanupCaptureDirectory(directory: string,
  report: OriginalRecordingCaptureArtifactCleanupReport): void {
  try {
    if (!fileIo.accessSync(directory)) {
      return;
    }
    if (!fileIo.statSync(directory).isDirectory()) {
      report.failed++;
      console.error(`Original recording capture path is not a directory: ${directory}`);
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
      if (!MICROPHONE_CAPTURE_NAME.test(name) && !INTERNAL_AUDIO_CAPTURE_NAME.test(name)) {
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
        console.error(`Original recording capture cleanup failed: path=${candidate}, ` +
          `error=${JSON.stringify(error)}`);
      }
    }
  } catch (error) {
    report.failed++;
    console.error(`Original recording capture directory cleanup failed: path=${directory}, ` +
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
