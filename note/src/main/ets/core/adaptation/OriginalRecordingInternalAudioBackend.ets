import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import notaRecording from 'libnota_recording.so';
import {
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureErrorListener,
  OriginalRecordingCaptureInterruptionListener, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureStop,
} from './OriginalRecordingCaptureController';
import { ORIGINAL_RECORDING_AUDIO_MIME_TYPE } from './OriginalRecordingMicrophoneBackend';

const NATIVE_EVENT_STATE: number = 1;
const NATIVE_EVENT_ERROR: number = 2;
const SCREEN_CAPTURE_STARTED: number = 0;
const SCREEN_CAPTURE_CANCELED: number = 1;
const SCREEN_CAPTURE_STOPPED_BY_USER: number = 2;
const SCREEN_CAPTURE_INTERRUPTED_BY_OTHER: number = 3;
const SCREEN_CAPTURE_STOPPED_BY_CALL: number = 4;
const SCREEN_CAPTURE_MIC_UNAVAILABLE: number = 5;
const SCREEN_CAPTURE_STOPPED_BY_USER_SWITCHES: number = 10;

export class OriginalRecordingInternalAudioBackend implements OriginalRecordingCaptureBackend {
  private temporaryDirectory: string;
  private outputFile: fileIo.File | null = null;
  private outputPath: string = '';
  private errorListener: OriginalRecordingCaptureErrorListener | null = null;
  private interruptionListener: OriginalRecordingCaptureInterruptionListener | null = null;
  private startResolve: (() => void) | null = null;
  private startReject: ((error: Error) => void) | null = null;
  private started: boolean = false;
  private sequence: number = 0;

  constructor(temporaryDirectory: string) {
    if (temporaryDirectory.length === 0) {
      throw new Error('internal recording temporary directory is empty');
    }
    this.temporaryDirectory = temporaryDirectory;
  }

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.errorListener = listener;
  }

  setInterruptionListener(listener: OriginalRecordingCaptureInterruptionListener | null): void {
    this.interruptionListener = listener;
  }

  supportsPause(): boolean {
    return false;
  }

  async start(): Promise<OriginalRecordingCaptureStart> {
    if (this.outputFile !== null || this.startResolve !== null || this.started) {
      throw new Error('internal recording backend is already active');
    }
    if (notaRecording.isCaptureActive()) {
      throw new Error('another internal audio capture is still active');
    }
    this.sequence++;
    this.outputPath = `${this.temporaryDirectory}/internal_recording_${Date.now()}_${this.sequence}.m4a`;
    try {
      this.outputFile = fileIo.openSync(this.outputPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      notaRecording.setEventCallback((kind: number, code: number): void => {
        this.onNativeEvent(kind, code);
      });
      const started: Promise<void> = new Promise<void>((resolve: () => void,
        reject: (error: Error) => void): void => {
        this.startResolve = resolve;
        this.startReject = reject;
      });
      const result: number = notaRecording.startCapture(`fd://${this.outputFile.fd}`);
      if (result !== 0) {
        this.rejectStart(new Error(`internal audio native start failed (${result})`));
      }
      await started;
      this.started = true;
      return { temporaryPath: this.outputPath, mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE };
    } catch (error) {
      await this.dispose(true);
      throw new Error(`start internal recording failed: ${JSON.stringify(error)}`);
    }
  }

  async pause(): Promise<void> {
    throw new Error('pause is not supported for internal audio recording');
  }

  async resume(): Promise<void> {
    throw new Error('resume is not supported for internal audio recording');
  }

  async stop(): Promise<OriginalRecordingCaptureStop> {
    const file: fileIo.File | null = this.outputFile;
    if (!this.started || file === null) {
      throw new Error('internal recording backend cannot stop in its current state');
    }
    const completedPath: string = this.outputPath;
    try {
      const result: number = notaRecording.stopCapture();
      if (result !== 0) {
        throw new Error(`internal audio native stop failed (${result})`);
      }
      this.started = false;
      notaRecording.setEventCallback(null);
      const stat = fileIo.statSync(file.fd);
      if (!stat.isFile() || !Number.isSafeInteger(stat.size) || stat.size <= 0) {
        throw new Error('internal recording backend produced an empty or invalid file');
      }
      const mediaDurationMs: number | null = await this.extractMediaDuration(file, stat.size);
      fileIo.closeSync(file);
      this.outputFile = null;
      this.outputPath = '';
      return { temporaryPath: completedPath, mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE,
        fileSize: stat.size, mediaDurationMs: mediaDurationMs };
    } catch (error) {
      await this.dispose(true);
      try {
        fileIo.unlinkSync(completedPath);
      } catch (_deleteError) {
      }
      throw new Error(`stop internal recording failed: ${JSON.stringify(error)}`);
    }
  }

  async abort(): Promise<void> {
    await this.dispose(true);
  }

  private onNativeEvent(kind: number, code: number): void {
    if (kind === NATIVE_EVENT_ERROR) {
      const error: Error = new Error(`internal audio native error (${code})`);
      if (this.startReject !== null) {
        this.rejectStart(error);
      } else if (this.errorListener !== null) {
        this.errorListener(error);
      }
      return;
    }
    if (kind !== NATIVE_EVENT_STATE) {
      return;
    }
    if (code === SCREEN_CAPTURE_STARTED) {
      const resolve: (() => void) | null = this.startResolve;
      this.startResolve = null;
      this.startReject = null;
      this.started = true;
      if (resolve !== null) {
        resolve();
      }
      return;
    }
    if (code === SCREEN_CAPTURE_CANCELED || code === SCREEN_CAPTURE_MIC_UNAVAILABLE) {
      this.rejectStart(new Error(`internal audio authorization failed (${code})`));
      return;
    }
    if (code === SCREEN_CAPTURE_STOPPED_BY_USER || code === SCREEN_CAPTURE_INTERRUPTED_BY_OTHER ||
      code === SCREEN_CAPTURE_STOPPED_BY_CALL || code === SCREEN_CAPTURE_STOPPED_BY_USER_SWITCHES) {
      if (this.startReject !== null) {
        this.rejectStart(new Error(`internal audio stopped while starting (${code})`));
      } else if (this.started && this.interruptionListener !== null) {
        this.interruptionListener();
      }
    }
  }

  private rejectStart(error: Error): void {
    const reject: ((error: Error) => void) | null = this.startReject;
    this.startResolve = null;
    this.startReject = null;
    if (reject !== null) {
      reject(error);
    }
  }

  private async dispose(deleteOutput: boolean): Promise<void> {
    const file: fileIo.File | null = this.outputFile;
    const path: string = this.outputPath;
    this.outputFile = null;
    this.outputPath = '';
    this.started = false;
    this.rejectStart(new Error('internal audio capture was aborted'));
    try {
      notaRecording.abortCapture();
    } catch (_abortError) {
    }
    try {
      notaRecording.setEventCallback(null);
    } catch (_callbackError) {
    }
    if (file !== null) {
      try {
        fileIo.closeSync(file);
      } catch (_closeError) {
      }
    }
    if (deleteOutput && path.length > 0) {
      try {
        fileIo.unlinkSync(path);
      } catch (_deleteError) {
      }
    }
  }

  private async extractMediaDuration(file: fileIo.File, fileSize: number): Promise<number | null> {
    let extractor: media.AVMetadataExtractor | null = null;
    try {
      extractor = await media.createAVMetadataExtractor();
      extractor.fdSrc = { fd: file.fd, offset: 0, length: fileSize };
      const metadata: media.AVMetadata = await extractor.fetchMetadata();
      const raw: string | undefined = metadata.duration;
      if (raw === undefined || !/^[0-9]+$/.test(raw)) {
        return null;
      }
      const duration: number = Number(raw);
      return Number.isSafeInteger(duration) && duration >= 0 ? duration : null;
    } catch (_error) {
      return null;
    } finally {
      if (extractor !== null) {
        try {
          await extractor.release();
        } catch (_releaseError) {
        }
      }
    }
  }
}
