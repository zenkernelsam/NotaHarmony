import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../../data/OriginalRecordingStore';

export interface OpenedOriginalRecordingAsset {
  state: OriginalRecordingAssetState;
  lease: OriginalRecordingAssetLease | null;
  error: string | null;
}

export class OriginalRecordingAssetLease {
  readonly descriptor: media.AVFileDescriptor;
  private file: fileIo.File | null;

  constructor(file: fileIo.File, length: number) {
    this.file = file;
    this.descriptor = { fd: file.fd, offset: 0, length: length };
  }

  close(): void {
    if (this.file === null) {
      return;
    }
    const file: fileIo.File = this.file;
    this.file = null;
    fileIo.closeSync(file);
  }
}

export class OriginalRecordingAssetLoader {
  open(recording: MaterializedOriginalRecording): OpenedOriginalRecordingAsset {
    const unavailable: OpenedOriginalRecordingAsset | null = recordingOpenPrecondition(recording);
    if (unavailable !== null) {
      return unavailable;
    }

    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(recording.localPath as string, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const sizeError: string | null = validateRecordingAssetFileSize(
        recording.assetFileSize, stat.size, stat.isFile());
      if (sizeError !== null) {
        fileIo.closeSync(file);
        file = null;
        return failed(sizeError);
      }
      const lease: OriginalRecordingAssetLease = new OriginalRecordingAssetLease(file, stat.size);
      file = null;
      return { state: OriginalRecordingAssetState.READY, lease: lease, error: null };
    } catch (error) {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (_closeError) {
        }
      }
      return failed(`recording asset cannot be opened: ${JSON.stringify(error)}`);
    }
  }
}

export function recordingOpenPrecondition(
  recording: MaterializedOriginalRecording): OpenedOriginalRecordingAsset | null {
  if (recording.assetState !== OriginalRecordingAssetState.READY) {
    return { state: recording.assetState, lease: null,
      error: recording.assetError ?? 'recording asset is unavailable' };
  }
  if (recording.localPath === null || recording.localPath.length === 0) {
    return failed('ready recording asset has no local path');
  }
  if (!Number.isSafeInteger(recording.assetFileSize) || recording.assetFileSize <= 0) {
    return failed('recording asset metadata has an invalid file size');
  }
  return null;
}

export function validateRecordingAssetFileSize(expected: number, actual: number,
  isFile: boolean): string | null {
  if (!isFile) {
    return 'recording asset path is not a regular file';
  }
  if (!Number.isSafeInteger(actual) || actual <= 0) {
    return 'recording asset file is empty or has an invalid size';
  }
  if (actual !== expected) {
    return 'recording asset file size does not match metadata';
  }
  return null;
}

function failed(error: string): OpenedOriginalRecordingAsset {
  return { state: OriginalRecordingAssetState.FAILED, lease: null, error: error };
}
