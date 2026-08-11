import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureClock,
  OriginalRecordingCaptureController, OriginalRecordingCaptureErrorListener,
  OriginalRecordingCaptureResult, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureStop,
} from '../main/ets/core/adaptation/OriginalRecordingCaptureController';
import {
  OriginalRecordingAudioFocusGateway, OriginalRecordingPermissionGateway,
  OriginalRecordingSessionController, OriginalRecordingSessionFailure,
} from '../main/ets/core/adaptation/OriginalRecordingSessionController';

class SessionTestClock implements OriginalRecordingCaptureClock {
  wall: number = 100000;
  uptime: number = 1000;

  wallTimeMs(): number { return this.wall; }
  uptimeMs(): number { return this.uptime; }
}

class SessionTestBackend implements OriginalRecordingCaptureBackend {
  calls: string[] = [];
  listener: OriginalRecordingCaptureErrorListener | null = null;
  failStart: boolean = false;

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.listener = listener;
  }
  async start(): Promise<OriginalRecordingCaptureStart> {
    this.calls.push('capture-start');
    if (this.failStart) {
      throw new Error('capture start failed');
    }
    return { temporaryPath: '/tmp/session.m4a', mimeType: 'audio/mp4' };
  }
  async pause(): Promise<void> { this.calls.push('capture-pause'); }
  async resume(): Promise<void> { this.calls.push('capture-resume'); }
  async stop(): Promise<OriginalRecordingCaptureStop> {
    this.calls.push('capture-stop');
    return { temporaryPath: '/tmp/session.m4a', mimeType: 'audio/mp4',
      fileSize: 128, mediaDurationMs: 2500 };
  }
  async abort(): Promise<void> { this.calls.push('capture-abort'); }
  failActive(): void {
    const listener: OriginalRecordingCaptureErrorListener | null = this.listener;
    if (listener !== null) {
      listener(new Error('active capture failed'));
    }
  }
}

class SessionTestPermission implements OriginalRecordingPermissionGateway {
  granted: boolean = true;
  calls: string[];
  constructor(calls: string[]) { this.calls = calls; }
  async requestMicrophonePermission(): Promise<boolean> {
    this.calls.push('permission');
    return this.granted;
  }
}

class SessionTestFocus implements OriginalRecordingAudioFocusGateway {
  calls: string[];
  interrupted: (() => void) | null = null;
  constructor(calls: string[]) { this.calls = calls; }
  async activate(onInterrupted: () => void): Promise<void> {
    this.calls.push('focus-on');
    this.interrupted = onInterrupted;
  }
  async deactivate(): Promise<void> {
    this.calls.push('focus-off');
    this.interrupted = null;
  }
  interrupt(): void {
    const callback = this.interrupted;
    this.interrupted = null;
    if (callback !== null) { callback(); }
  }
}

function createSession(calls: string[], permission: SessionTestPermission,
  focus: SessionTestFocus, backend: SessionTestBackend,
  persist: (capture: OriginalRecordingCaptureResult) => Promise<void>): OriginalRecordingSessionController {
  return new OriginalRecordingSessionController(
    new OriginalRecordingCaptureController(backend, new SessionTestClock()), permission, focus,
    persist, async (): Promise<void> => { calls.push('before-start'); });
}

export default function originalRecordingSessionControllerTest() {
  describe('OriginalRecordingSessionController', () => {
    it('denies without touching playback focus or recorder', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      permission.granted = false;
      const backend = new SessionTestBackend();
      const session = createSession(calls, permission, new SessionTestFocus(calls), backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => {});
      expect(await session.start()).assertFalse();
      expect(calls.join(',')).assertEqual('permission');
      expect(backend.calls.length).assertEqual(0);
      expect(session.getSnapshot().failure).assertEqual(
        OriginalRecordingSessionFailure.PERMISSION_DENIED);
    });

    it('orders permission playback focus capture and atomic save', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      const session = createSession(calls, permission, focus, backend,
        async (capture: OriginalRecordingCaptureResult): Promise<void> => {
          calls.push(`persist-${capture.durationMs}`);
        });
      expect(await session.start()).assertTrue();
      expect(await session.pause()).assertTrue();
      expect(await session.resume()).assertTrue();
      expect(await session.stop()).assertTrue();
      expect(calls.join(',')).assertEqual(
        'permission,before-start,focus-on,focus-off,persist-2500');
      expect(backend.calls.join(',')).assertEqual(
        'capture-start,capture-pause,capture-resume,capture-stop');
      expect(session.getSnapshot().failure).assertEqual(OriginalRecordingSessionFailure.NONE);
    });

    it('stops and saves when original audio focus is interrupted', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      const session = createSession(calls, permission, focus, backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => { calls.push('persist'); });
      expect(await session.start()).assertTrue();
      focus.interrupt();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();
      expect(backend.calls[backend.calls.length - 1]).assertEqual('capture-stop');
      expect(calls[calls.length - 1]).assertEqual('persist');
    });

    it('queues close-time stop behind an in-flight start', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      const session = createSession(calls, permission, focus, backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => { calls.push('persist'); });
      const starting: Promise<boolean> = session.start();
      const stopping: Promise<boolean> = session.stop();
      expect(await starting).assertTrue();
      expect(await stopping).assertTrue();
      expect(backend.calls.join(',')).assertEqual('capture-start,capture-stop');
      expect(calls[calls.length - 1]).assertEqual('persist');
    });

    it('reports a capture start failure only once', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      backend.failStart = true;
      const session = createSession(calls, permission, focus, backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => {});
      expect(await session.start()).assertFalse();
      expect(session.getSnapshot().failure).assertEqual(OriginalRecordingSessionFailure.START_FAILED);
      expect(session.getSnapshot().failureSequence).assertEqual(1);
    });

    it('classifies an active recorder failure as save failure', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      const session = createSession(calls, permission, focus, backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => {});
      expect(await session.start()).assertTrue();
      backend.failActive();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();
      expect(session.getSnapshot().failure).assertEqual(OriginalRecordingSessionFailure.SAVE_FAILED);
      expect(session.getSnapshot().failureSequence).assertEqual(1);
    });

    it('reports save failure and finish releases after saving an active capture', 0, async () => {
      const calls: string[] = [];
      const permission = new SessionTestPermission(calls);
      const focus = new SessionTestFocus(calls);
      const backend = new SessionTestBackend();
      let fail: boolean = true;
      const session = createSession(calls, permission, focus, backend,
        async (_capture: OriginalRecordingCaptureResult): Promise<void> => {
          if (fail) { throw new Error('persist failed'); }
          calls.push('persist');
        });
      expect(await session.start()).assertTrue();
      expect(await session.stop()).assertFalse();
      expect(session.getSnapshot().failure).assertEqual(OriginalRecordingSessionFailure.SAVE_FAILED);
      fail = false;
      expect(await session.start()).assertTrue();
      expect(await session.finishAndRelease()).assertTrue();
      expect(backend.calls[backend.calls.length - 2]).assertEqual('capture-stop');
      expect(backend.calls[backend.calls.length - 1]).assertEqual('capture-abort');
      expect(calls[calls.length - 1]).assertEqual('persist');
    });
  });
}
