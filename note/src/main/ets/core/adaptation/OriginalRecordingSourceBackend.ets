import {
  OriginalRecordingAudioSource, OriginalRecordingAudioSourceSelector,
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureErrorListener,
  OriginalRecordingCaptureInterruptionListener, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureStop,
} from './OriginalRecordingCaptureController';

export class OriginalRecordingSourceBackend implements OriginalRecordingCaptureBackend,
  OriginalRecordingAudioSourceSelector {
  private microphone: OriginalRecordingCaptureBackend;
  private internalAudio: OriginalRecordingCaptureBackend;
  private source: OriginalRecordingAudioSource = OriginalRecordingAudioSource.MICROPHONE;
  private active: OriginalRecordingCaptureBackend | null = null;

  constructor(microphone: OriginalRecordingCaptureBackend,
    internalAudio: OriginalRecordingCaptureBackend) {
    this.microphone = microphone;
    this.internalAudio = internalAudio;
  }

  selectSource(source: OriginalRecordingAudioSource): boolean {
    if (this.active !== null || (source !== OriginalRecordingAudioSource.MICROPHONE &&
      source !== OriginalRecordingAudioSource.DEVICE_ONLY)) {
      return false;
    }
    this.source = source;
    return true;
  }

  getSource(): OriginalRecordingAudioSource {
    return this.source;
  }

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.microphone.setErrorListener(listener);
    this.internalAudio.setErrorListener(listener);
  }

  setInterruptionListener(listener: OriginalRecordingCaptureInterruptionListener | null): void {
    this.microphone.setInterruptionListener(listener);
    this.internalAudio.setInterruptionListener(listener);
  }

  supportsPause(): boolean {
    return this.selectedBackend().supportsPause();
  }

  async start(): Promise<OriginalRecordingCaptureStart> {
    if (this.active !== null) {
      throw new Error('recording source backend is already active');
    }
    const selected: OriginalRecordingCaptureBackend = this.selectedBackend();
    this.active = selected;
    return await selected.start();
  }

  async pause(): Promise<void> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    if (!active.supportsPause()) {
      throw new Error('selected recording source does not support pause');
    }
    await active.pause();
  }

  async resume(): Promise<void> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    if (!active.supportsPause()) {
      throw new Error('selected recording source does not support resume');
    }
    await active.resume();
  }

  async stop(): Promise<OriginalRecordingCaptureStop> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    try {
      return await active.stop();
    } finally {
      this.active = null;
    }
  }

  async abort(): Promise<void> {
    const active: OriginalRecordingCaptureBackend | null = this.active;
    this.active = null;
    if (active !== null) {
      await active.abort();
    }
  }

  private selectedBackend(): OriginalRecordingCaptureBackend {
    return this.source === OriginalRecordingAudioSource.DEVICE_ONLY ?
      this.internalAudio : this.microphone;
  }

  private requireActive(): OriginalRecordingCaptureBackend {
    if (this.active === null) {
      throw new Error('recording source backend is not active');
    }
    return this.active;
  }
}
