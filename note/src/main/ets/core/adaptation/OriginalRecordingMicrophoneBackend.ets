import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import {
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureClock,
  OriginalRecordingCaptureErrorListener, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureStop,
} from './OriginalRecordingCaptureController';

export const ORIGINAL_RECORDING_AUDIO_SAMPLE_RATE: number = 44100;
export const ORIGINAL_RECORDING_AUDIO_CHANNELS: number = 1;
export const ORIGINAL_RECORDING_AUDIO_BITRATE: number = 96000;
export const ORIGINAL_RECORDING_AUDIO_MIME_TYPE: string = 'audio/mp4';
export const ORIGINAL_RECORDING_AUDIO_SOURCE_TYPE: media.AudioSourceType =
  media.AudioSourceType.AUDIO_SOURCE_TYPE_VOICE_RECOGNITION;

export function originalRecordingCaptureProfile(): media.AVRecorderProfile {
  return {
    audioBitrate: ORIGINAL_RECORDING_AUDIO_BITRATE,
    audioChannels: ORIGINAL_RECORDING_AUDIO_CHANNELS,
    audioCodec: media.CodecMimeType.AUDIO_AAC,
    audioSampleRate: ORIGINAL_RECORDING_AUDIO_SAMPLE_RATE,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
  };
}

export class HarmonyOriginalRecordingCaptureClock implements OriginalRecordingCaptureClock {
  wallTimeMs(): number {
    return Date.now();
  }

  uptimeMs(): number {
    return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP, false);
  }
}

export class OriginalRecordingMicrophoneBackend implements OriginalRecordingCaptureBackend {
  private temporaryDirectory: string;
  private recorder: media.AVRecorder | null = null;
  private outputFile: fileIo.File | null = null;
  private outputPath: string = '';
  private errorListener: OriginalRecordingCaptureErrorListener | null = null;
  private recorderErrorHandler: ((error: BusinessError) => void) | null = null;
  private sequence: number = 0;

  constructor(temporaryDirectory: string) {
    if (temporaryDirectory.length === 0) {
      throw new Error('recording temporary directory is empty');
    }
    this.temporaryDirectory = temporaryDirectory;
  }

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.errorListener = listener;
  }

  async start(): Promise<OriginalRecordingCaptureStart> {
    if (this.recorder !== null || this.outputFile !== null) {
      throw new Error('recording backend is already active');
    }
    this.sequence++;
    this.outputPath = `${this.temporaryDirectory}/recording_${Date.now()}_${this.sequence}.m4a`;
    try {
      this.outputFile = fileIo.openSync(this.outputPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      const recorder: media.AVRecorder = await media.createAVRecorder();
      this.recorder = recorder;
      this.recorderErrorHandler = (error: BusinessError): void => {
        if (recorder === this.recorder && this.errorListener !== null) {
          this.errorListener(error);
        }
      };
      recorder.on('error', this.recorderErrorHandler);
      const config: media.AVRecorderConfig = {
        audioSourceType: ORIGINAL_RECORDING_AUDIO_SOURCE_TYPE,
        profile: originalRecordingCaptureProfile(),
        url: `fd://${this.outputFile.fd}`,
      };
      await recorder.prepare(config);
      await recorder.start();
      return { temporaryPath: this.outputPath, mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE };
    } catch (error) {
      await this.dispose(true, true);
      throw new Error(`start original recording failed: ${JSON.stringify(error)}`);
    }
  }

  async pause(): Promise<void> {
    const recorder: media.AVRecorder | null = this.recorder;
    if (recorder === null || recorder.state !== 'started') {
      throw new Error('recording backend cannot pause in its current state');
    }
    await recorder.pause();
  }

  async resume(): Promise<void> {
    const recorder: media.AVRecorder | null = this.recorder;
    if (recorder === null || recorder.state !== 'paused') {
      throw new Error('recording backend cannot resume in its current state');
    }
    await recorder.resume();
  }

  async stop(): Promise<OriginalRecordingCaptureStop> {
    const recorder: media.AVRecorder | null = this.recorder;
    if (recorder === null || (recorder.state !== 'started' && recorder.state !== 'paused')) {
      throw new Error('recording backend cannot stop in its current state');
    }
    const completedPath: string = this.outputPath;
    try {
      await recorder.stop();
      await this.releaseRecorder(recorder);
      const file: fileIo.File | null = this.outputFile;
      if (file === null) {
        throw new Error('recording output file disappeared before validation');
      }
      const stat = fileIo.statSync(file.fd);
      if (!stat.isFile() || !Number.isSafeInteger(stat.size) || stat.size <= 0) {
        throw new Error('recording backend produced an empty or invalid file');
      }
      const mediaDurationMs: number | null = await this.extractMediaDuration(file, stat.size);
      fileIo.closeSync(file);
      this.outputFile = null;
      this.outputPath = '';
      return { temporaryPath: completedPath, mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE,
        fileSize: stat.size, mediaDurationMs: mediaDurationMs };
    } catch (error) {
      await this.dispose(true, true);
      try {
        fileIo.unlinkSync(completedPath);
      } catch (_deleteError) {
      }
      throw new Error(`stop original recording failed: ${JSON.stringify(error)}`);
    }
  }

  async abort(): Promise<void> {
    await this.dispose(true, true);
  }

  private async dispose(stopIfActive: boolean, deleteOutput: boolean): Promise<void> {
    const recorder: media.AVRecorder | null = this.recorder;
    const file: fileIo.File | null = this.outputFile;
    const path: string = this.outputPath;
    this.recorder = null;
    this.outputFile = null;
    this.outputPath = '';
    if (recorder !== null) {
      if (stopIfActive && (recorder.state === 'started' || recorder.state === 'paused')) {
        try {
          await recorder.stop();
        } catch (_stopError) {
        }
      }
      await this.releaseRecorder(recorder);
    }
    this.recorderErrorHandler = null;
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

  private async releaseRecorder(recorder: media.AVRecorder): Promise<void> {
    if (this.recorderErrorHandler !== null) {
      try {
        recorder.off('error', this.recorderErrorHandler);
      } catch (_offError) {
      }
    }
    this.recorderErrorHandler = null;
    if (recorder.state !== 'released') {
      try {
        await recorder.release();
      } catch (_releaseError) {
      }
    }
    if (this.recorder === recorder) {
      this.recorder = null;
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
