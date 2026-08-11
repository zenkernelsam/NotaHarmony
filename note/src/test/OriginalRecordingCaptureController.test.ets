import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureClock,
  OriginalRecordingCaptureController, OriginalRecordingCaptureErrorListener,
  OriginalRecordingCaptureResult, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureState, OriginalRecordingCaptureStop,
} from '../main/ets/core/adaptation/OriginalRecordingCaptureController';
import {
  ORIGINAL_RECORDING_AUDIO_BITRATE, ORIGINAL_RECORDING_AUDIO_CHANNELS,
  ORIGINAL_RECORDING_AUDIO_MIME_TYPE, ORIGINAL_RECORDING_AUDIO_SAMPLE_RATE,
  ORIGINAL_RECORDING_AUDIO_SOURCE_TYPE,
  originalRecordingCaptureProfile,
} from '../main/ets/core/adaptation/OriginalRecordingMicrophoneBackend';

class CaptureTestClock implements OriginalRecordingCaptureClock {
  wall: number = 100000;
  uptime: number = 1000;

  wallTimeMs(): number {
    return this.wall;
  }

  uptimeMs(): number {
    return this.uptime;
  }
}

class CaptureTestBackend implements OriginalRecordingCaptureBackend {
  listener: OriginalRecordingCaptureErrorListener | null = null;
  calls: string[] = [];
  failStart: boolean = false;
  mediaDurationMs: number | null = null;

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.listener = listener;
  }

  async start(): Promise<OriginalRecordingCaptureStart> {
    this.calls.push('start');
    if (this.failStart) {
      throw new Error('start failed');
    }
    return { temporaryPath: '/tmp/recording.m4a', mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE };
  }

  async pause(): Promise<void> {
    this.calls.push('pause');
  }

  async resume(): Promise<void> {
    this.calls.push('resume');
  }

  async stop(): Promise<OriginalRecordingCaptureStop> {
    this.calls.push('stop');
    return { temporaryPath: '/tmp/recording.m4a', mimeType: ORIGINAL_RECORDING_AUDIO_MIME_TYPE,
      fileSize: 4096, mediaDurationMs: this.mediaDurationMs };
  }

  async abort(): Promise<void> {
    this.calls.push('abort');
  }

  emitError(): void {
    if (this.listener !== null) {
      this.listener(new Error('recorder failed'));
    }
  }
}

export default function originalRecordingCaptureControllerTest() {
  describe('OriginalRecordingCaptureController', () => {
    it('matches the original microphone AAC recording profile', 0, () => {
      const profile = originalRecordingCaptureProfile();
      expect(profile.audioSampleRate).assertEqual(ORIGINAL_RECORDING_AUDIO_SAMPLE_RATE);
      expect(profile.audioSampleRate).assertEqual(44100);
      expect(profile.audioChannels).assertEqual(ORIGINAL_RECORDING_AUDIO_CHANNELS);
      expect(profile.audioChannels).assertEqual(1);
      expect(profile.audioBitrate).assertEqual(ORIGINAL_RECORDING_AUDIO_BITRATE);
      expect(profile.audioBitrate).assertEqual(96000);
      expect(ORIGINAL_RECORDING_AUDIO_MIME_TYPE).assertEqual('audio/mp4');
      expect(ORIGINAL_RECORDING_AUDIO_SOURCE_TYPE).assertEqual(2);
    });

    it('excludes paused uptime and prefers media duration after stop', 0, async () => {
      const backend: CaptureTestBackend = new CaptureTestBackend();
      const clock: CaptureTestClock = new CaptureTestClock();
      const controller: OriginalRecordingCaptureController =
        new OriginalRecordingCaptureController(backend, clock);
      expect(await controller.start()).assertTrue();
      clock.uptime = 2000;
      expect(await controller.pause()).assertTrue();
      clock.uptime = 7000;
      expect(controller.getSnapshot().elapsedMs).assertEqual(1000);
      expect(await controller.resume()).assertTrue();
      clock.uptime = 8000;
      backend.mediaDurationMs = 1750;
      const result: OriginalRecordingCaptureResult | null = await controller.stop();
      expect(result?.durationMs).assertEqual(1750);
      expect(result?.startTime).assertEqual(100000);
      expect(result?.endTime).assertEqual(101750);
      expect(controller.getSnapshot().state).assertEqual(OriginalRecordingCaptureState.IDLE);
      expect(backend.calls.join(',')).assertEqual('start,pause,resume,stop');
    });

    it('falls back to monotonic elapsed time and cleans up start failures', 0, async () => {
      const backend: CaptureTestBackend = new CaptureTestBackend();
      const clock: CaptureTestClock = new CaptureTestClock();
      const controller: OriginalRecordingCaptureController =
        new OriginalRecordingCaptureController(backend, clock);
      expect(await controller.start()).assertTrue();
      clock.uptime = 3500;
      const result: OriginalRecordingCaptureResult | null = await controller.stop();
      expect(result?.durationMs).assertEqual(2500);

      backend.failStart = true;
      expect(await controller.start()).assertFalse();
      expect(controller.getSnapshot().state).assertEqual(OriginalRecordingCaptureState.FAILED);
      expect(backend.calls[backend.calls.length - 1]).assertEqual('abort');
      expect(await controller.pause()).assertFalse();
      await controller.release();
      expect(controller.getSnapshot().state).assertEqual(OriginalRecordingCaptureState.RELEASED);
      expect(await controller.start()).assertFalse();
    });

    it('aborts and publishes failure after an asynchronous recorder error', 0, async () => {
      const backend: CaptureTestBackend = new CaptureTestBackend();
      const controller: OriginalRecordingCaptureController =
        new OriginalRecordingCaptureController(backend, new CaptureTestClock());
      expect(await controller.start()).assertTrue();
      backend.emitError();
      await Promise.resolve();
      await Promise.resolve();
      expect(controller.getSnapshot().state).assertEqual(OriginalRecordingCaptureState.FAILED);
      expect(controller.getSnapshot().temporaryPath).assertNull();
      expect(backend.calls.join(',')).assertEqual('start,abort');
    });
  });
}
