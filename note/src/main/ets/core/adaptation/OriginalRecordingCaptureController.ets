import { AsyncMutex } from '../../data/AsyncMutex';

export enum OriginalRecordingCaptureState {
  IDLE = 0,
  STARTING = 1,
  RECORDING = 2,
  PAUSING = 3,
  PAUSED = 4,
  RESUMING = 5,
  STOPPING = 6,
  FAILED = 7,
  RELEASED = 8,
}

export interface OriginalRecordingCaptureSnapshot {
  state: OriginalRecordingCaptureState;
  temporaryPath: string | null;
  elapsedMs: number;
  error: string | null;
}

export interface OriginalRecordingCaptureStart {
  temporaryPath: string;
  mimeType: string;
}

export interface OriginalRecordingCaptureStop extends OriginalRecordingCaptureStart {
  fileSize: number;
  mediaDurationMs: number | null;
}

export interface OriginalRecordingCaptureResult extends OriginalRecordingCaptureStop {
  startTime: number;
  endTime: number;
  durationMs: number;
}

export type OriginalRecordingCaptureErrorListener = (error: Object) => void;

export interface OriginalRecordingCaptureBackend {
  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void;
  start(): Promise<OriginalRecordingCaptureStart>;
  pause(): Promise<void>;
  resume(): Promise<void>;
  stop(): Promise<OriginalRecordingCaptureStop>;
  abort(): Promise<void>;
}

export interface OriginalRecordingCaptureClock {
  wallTimeMs(): number;
  uptimeMs(): number;
}

export type OriginalRecordingCaptureListener =
  (snapshot: OriginalRecordingCaptureSnapshot) => void;

export class OriginalRecordingCaptureController {
  private backend: OriginalRecordingCaptureBackend;
  private clock: OriginalRecordingCaptureClock;
  private mutex: AsyncMutex = new AsyncMutex();
  private listener: OriginalRecordingCaptureListener | null = null;
  private snapshot: OriginalRecordingCaptureSnapshot = emptySnapshot(
    OriginalRecordingCaptureState.IDLE);
  private startWallTime: number = 0;
  private startUptime: number = 0;
  private pausedAtUptime: number = 0;
  private accumulatedPauseMs: number = 0;
  private mimeType: string = '';
  private permanentlyReleased: boolean = false;

  constructor(backend: OriginalRecordingCaptureBackend, clock: OriginalRecordingCaptureClock) {
    this.backend = backend;
    this.clock = clock;
    this.backend.setErrorListener((error: Object): void => this.handleBackendError(error));
  }

  setListener(listener: OriginalRecordingCaptureListener | null): void {
    this.listener = listener;
    if (listener !== null) {
      listener(this.getSnapshot());
    }
  }

  getSnapshot(): OriginalRecordingCaptureSnapshot {
    return { state: this.snapshot.state, temporaryPath: this.snapshot.temporaryPath,
      elapsedMs: this.currentElapsedMs(), error: this.snapshot.error };
  }

  // Original vcj.b exposes the recorder clock only while capture is active and not paused.
  getCurrentAudioTime(): string | null {
    const state: OriginalRecordingCaptureState = this.snapshot.state;
    if (state !== OriginalRecordingCaptureState.RECORDING &&
      state !== OriginalRecordingCaptureState.PAUSING &&
      state !== OriginalRecordingCaptureState.STOPPING) {
      return null;
    }
    // STOPPING can originate from PAUSED; the original paused flag still suppresses its clock.
    if (this.pausedAtUptime > 0) {
      return null;
    }
    const value: number = this.startWallTime + this.currentElapsedMs();
    return Number.isSafeInteger(value) && value > 0 ? value.toString() : null;
  }

  async start(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.permanentlyReleased || (this.snapshot.state !== OriginalRecordingCaptureState.IDLE &&
        this.snapshot.state !== OriginalRecordingCaptureState.FAILED)) {
        return false;
      }
      this.publish(emptySnapshot(OriginalRecordingCaptureState.STARTING));
      try {
        const started: OriginalRecordingCaptureStart = await this.backend.start();
        validateCaptureStart(started);
        this.startWallTime = validClockValue(this.clock.wallTimeMs(), 'wall clock');
        this.startUptime = validClockValue(this.clock.uptimeMs(), 'uptime clock');
        this.pausedAtUptime = 0;
        this.accumulatedPauseMs = 0;
        this.mimeType = started.mimeType;
        this.publish({ state: OriginalRecordingCaptureState.RECORDING,
          temporaryPath: started.temporaryPath, elapsedMs: 0, error: null });
        return true;
      } catch (error) {
        await this.abortBackend();
        this.resetTiming();
        this.publishFailure(error);
        return false;
      }
    });
  }

  async pause(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.permanentlyReleased ||
        this.snapshot.state !== OriginalRecordingCaptureState.RECORDING) {
        return false;
      }
      this.publishState(OriginalRecordingCaptureState.PAUSING);
      try {
        await this.backend.pause();
        this.pausedAtUptime = validClockValue(this.clock.uptimeMs(), 'uptime clock');
        this.publishState(OriginalRecordingCaptureState.PAUSED);
        return true;
      } catch (_error) {
        this.publishState(OriginalRecordingCaptureState.RECORDING);
        return false;
      }
    });
  }

  async resume(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.permanentlyReleased ||
        this.snapshot.state !== OriginalRecordingCaptureState.PAUSED) {
        return false;
      }
      this.publishState(OriginalRecordingCaptureState.RESUMING);
      try {
        await this.backend.resume();
        const now: number = validClockValue(this.clock.uptimeMs(), 'uptime clock');
        this.accumulatedPauseMs += Math.max(0, now - this.pausedAtUptime);
        this.pausedAtUptime = 0;
        this.publishState(OriginalRecordingCaptureState.RECORDING);
        return true;
      } catch (_error) {
        this.publishState(OriginalRecordingCaptureState.PAUSED);
        return false;
      }
    });
  }

  async stop(): Promise<OriginalRecordingCaptureResult | null> {
    return await this.mutex.runExclusive(async (): Promise<OriginalRecordingCaptureResult | null> => {
      if (this.permanentlyReleased ||
        (this.snapshot.state !== OriginalRecordingCaptureState.RECORDING &&
          this.snapshot.state !== OriginalRecordingCaptureState.PAUSED)) {
        return null;
      }
      this.publishState(OriginalRecordingCaptureState.STOPPING);
      try {
        const stopped: OriginalRecordingCaptureStop = await this.backend.stop();
        validateCaptureStop(stopped, this.mimeType);
        const fallbackDuration: number = this.currentElapsedMs();
        const mediaDuration: number | null = validMediaDuration(stopped.mediaDurationMs);
        const duration: number = mediaDuration === null ? fallbackDuration : mediaDuration;
        const result: OriginalRecordingCaptureResult = {
          temporaryPath: stopped.temporaryPath, mimeType: stopped.mimeType,
          fileSize: stopped.fileSize, mediaDurationMs: stopped.mediaDurationMs,
          startTime: this.startWallTime, endTime: this.startWallTime + duration,
          durationMs: duration,
        };
        this.resetTiming();
        this.publish(emptySnapshot(OriginalRecordingCaptureState.IDLE));
        return result;
      } catch (error) {
        await this.abortBackend();
        this.resetTiming();
        this.publishFailure(error);
        return null;
      }
    });
  }

  async abort(): Promise<void> {
    await this.mutex.runExclusive(async (): Promise<void> => {
      if (this.permanentlyReleased) {
        return;
      }
      await this.abortBackend();
      this.resetTiming();
      this.publish(emptySnapshot(OriginalRecordingCaptureState.IDLE));
    });
  }

  async release(): Promise<void> {
    await this.mutex.runExclusive(async (): Promise<void> => {
      if (this.permanentlyReleased) {
        return;
      }
      this.permanentlyReleased = true;
      this.backend.setErrorListener(null);
      await this.abortBackend();
      this.resetTiming();
      this.publish(emptySnapshot(OriginalRecordingCaptureState.RELEASED));
      this.listener = null;
    });
  }

  private handleBackendError(error: Object): void {
    this.mutex.runExclusive(async (): Promise<void> => {
      if (this.permanentlyReleased || this.snapshot.state === OriginalRecordingCaptureState.IDLE ||
        this.snapshot.state === OriginalRecordingCaptureState.FAILED ||
        this.snapshot.state === OriginalRecordingCaptureState.RELEASED) {
        return;
      }
      await this.abortBackend();
      this.resetTiming();
      this.publishFailure(error);
    }).catch((): void => {});
  }

  private currentElapsedMs(): number {
    if (this.startUptime <= 0) {
      return this.snapshot.elapsedMs;
    }
    const now: number = this.clock.uptimeMs();
    if (!Number.isSafeInteger(now) || now < this.startUptime) {
      return this.snapshot.elapsedMs;
    }
    let paused: number = this.accumulatedPauseMs;
    if (this.pausedAtUptime > 0) {
      paused += Math.max(0, now - this.pausedAtUptime);
    }
    return Math.max(0, now - this.startUptime - paused);
  }

  private publishState(state: OriginalRecordingCaptureState): void {
    this.publish({ state: state, temporaryPath: this.snapshot.temporaryPath,
      elapsedMs: this.currentElapsedMs(), error: null });
  }

  private publishFailure(error: Object): void {
    this.publish({ state: OriginalRecordingCaptureState.FAILED, temporaryPath: null,
      elapsedMs: 0, error: JSON.stringify(error) });
  }

  private publish(snapshot: OriginalRecordingCaptureSnapshot): void {
    this.snapshot = snapshot;
    if (this.listener !== null) {
      this.listener(this.getSnapshot());
    }
  }

  private async abortBackend(): Promise<void> {
    try {
      await this.backend.abort();
    } catch (_error) {
    }
  }

  private resetTiming(): void {
    this.startWallTime = 0;
    this.startUptime = 0;
    this.pausedAtUptime = 0;
    this.accumulatedPauseMs = 0;
    this.mimeType = '';
  }
}

function validateCaptureStart(started: OriginalRecordingCaptureStart): void {
  if (started.temporaryPath.length === 0 || started.mimeType.length === 0) {
    throw new Error('recording backend returned incomplete start metadata');
  }
}

function validateCaptureStop(stopped: OriginalRecordingCaptureStop, mimeType: string): void {
  validateCaptureStart(stopped);
  if (stopped.mimeType !== mimeType || !Number.isSafeInteger(stopped.fileSize) ||
    stopped.fileSize <= 0 ||
    (stopped.mediaDurationMs !== null && validMediaDuration(stopped.mediaDurationMs) === null)) {
    throw new Error('recording backend returned invalid stop metadata');
  }
}

function validMediaDuration(value: number | null): number | null {
  return value !== null && Number.isSafeInteger(value) && value >= 0 ? value : null;
}

function validClockValue(value: number, name: string): number {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new Error(`${name} is invalid`);
  }
  return value;
}

function emptySnapshot(state: OriginalRecordingCaptureState): OriginalRecordingCaptureSnapshot {
  return { state: state, temporaryPath: null, elapsedMs: 0, error: null };
}
