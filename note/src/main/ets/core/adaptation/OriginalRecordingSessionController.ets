import { AsyncMutex } from '../../data/AsyncMutex';
import {
  OriginalRecordingCaptureController, OriginalRecordingCaptureResult,
  OriginalRecordingCaptureSnapshot, OriginalRecordingCaptureState,
} from './OriginalRecordingCaptureController';

export enum OriginalRecordingSessionFailure {
  NONE = 0,
  PERMISSION_DENIED = 1,
  START_FAILED = 2,
  SAVE_FAILED = 3,
}

export interface OriginalRecordingSessionSnapshot {
  captureState: OriginalRecordingCaptureState;
  elapsedMs: number;
  preparing: boolean;
  saving: boolean;
  failure: OriginalRecordingSessionFailure;
  failureSequence: number;
}

export interface OriginalRecordingPermissionGateway {
  requestMicrophonePermission(): Promise<boolean>;
}

export interface OriginalRecordingAudioFocusGateway {
  activate(onInterrupted: () => void): Promise<void>;
  deactivate(): Promise<void>;
}

export type OriginalRecordingPersistCapture =
  (capture: OriginalRecordingCaptureResult) => Promise<void>;
export type OriginalRecordingBeforeStart = () => Promise<void>;
export type OriginalRecordingSessionListener =
  (snapshot: OriginalRecordingSessionSnapshot) => void;

export class OriginalRecordingSessionController {
  private capture: OriginalRecordingCaptureController;
  private permission: OriginalRecordingPermissionGateway;
  private focus: OriginalRecordingAudioFocusGateway;
  private persistCapture: OriginalRecordingPersistCapture;
  private beforeStart: OriginalRecordingBeforeStart;
  private mutex: AsyncMutex = new AsyncMutex();
  private listener: OriginalRecordingSessionListener | null = null;
  private captureSnapshot: OriginalRecordingCaptureSnapshot;
  private preparing: boolean = false;
  private saving: boolean = false;
  private failure: OriginalRecordingSessionFailure = OriginalRecordingSessionFailure.NONE;
  private failureSequence: number = 0;
  private focusActive: boolean = false;
  private released: boolean = false;

  constructor(capture: OriginalRecordingCaptureController,
    permission: OriginalRecordingPermissionGateway, focus: OriginalRecordingAudioFocusGateway,
    persistCapture: OriginalRecordingPersistCapture, beforeStart: OriginalRecordingBeforeStart) {
    this.capture = capture;
    this.permission = permission;
    this.focus = focus;
    this.persistCapture = persistCapture;
    this.beforeStart = beforeStart;
    this.captureSnapshot = capture.getSnapshot();
    this.capture.setListener((snapshot: OriginalRecordingCaptureSnapshot): void => {
      this.onCaptureSnapshot(snapshot);
    });
  }

  setListener(listener: OriginalRecordingSessionListener | null): void {
    this.listener = listener;
    if (listener !== null) {
      listener(this.getSnapshot());
    }
  }

  getSnapshot(): OriginalRecordingSessionSnapshot {
    const current: OriginalRecordingCaptureSnapshot = this.capture.getSnapshot();
    this.captureSnapshot = current;
    return {
      captureState: current.state, elapsedMs: current.elapsedMs,
      preparing: this.preparing, saving: this.saving,
      failure: this.failure, failureSequence: this.failureSequence,
    };
  }

  async start(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.released || this.preparing || this.saving ||
        (this.captureSnapshot.state !== OriginalRecordingCaptureState.IDLE &&
          this.captureSnapshot.state !== OriginalRecordingCaptureState.FAILED)) {
        return false;
      }
      this.preparing = true;
      this.failure = OriginalRecordingSessionFailure.NONE;
      this.publish();
      try {
        if (!await this.permission.requestMicrophonePermission()) {
          this.preparing = false;
          this.publishFailure(OriginalRecordingSessionFailure.PERMISSION_DENIED);
          return false;
        }
        await this.beforeStart();
        await this.focus.activate((): void => this.onAudioInterrupted());
        this.focusActive = true;
        const started: boolean = await this.capture.start();
        this.preparing = false;
        if (!started) {
          await this.deactivateFocus();
          if (this.failure === OriginalRecordingSessionFailure.NONE) {
            this.publishFailure(OriginalRecordingSessionFailure.START_FAILED);
          } else {
            this.publish();
          }
          return false;
        }
        this.publish();
        return true;
      } catch (error) {
        await this.capture.abort();
        await this.deactivateFocus();
        this.preparing = false;
        console.error(`starting recording session failed: ${JSON.stringify(error)}`);
        this.publishFailure(OriginalRecordingSessionFailure.START_FAILED);
        return false;
      }
    });
  }

  async pause(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.released || this.preparing || this.saving) {
        return false;
      }
      return await this.capture.pause();
    });
  }

  async resume(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.released || this.preparing || this.saving) {
        return false;
      }
      return await this.capture.resume();
    });
  }

  async stop(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      return await this.stopInternal();
    });
  }

  async finishAndRelease(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.released) {
        return true;
      }
      let completed: boolean = true;
      if (isOriginalRecordingCaptureActive(this.captureSnapshot.state)) {
        completed = await this.stopInternal();
      } else {
        await this.deactivateFocus();
      }
      this.released = true;
      this.capture.setListener(null);
      await this.capture.release();
      this.preparing = false;
      this.saving = false;
      this.captureSnapshot = this.capture.getSnapshot();
      this.publish();
      this.listener = null;
      return completed;
    });
  }

  private async stopInternal(): Promise<boolean> {
    if (this.released || this.preparing || this.saving ||
      !isOriginalRecordingCaptureActive(this.captureSnapshot.state)) {
      return false;
    }
    const result: OriginalRecordingCaptureResult | null = await this.capture.stop();
    await this.deactivateFocus();
    if (result === null) {
      if (this.failure === OriginalRecordingSessionFailure.NONE) {
        this.publishFailure(OriginalRecordingSessionFailure.SAVE_FAILED);
      }
      return false;
    }
    this.saving = true;
    this.failure = OriginalRecordingSessionFailure.NONE;
    this.publish();
    try {
      await this.persistCapture(result);
      this.saving = false;
      this.publish();
      return true;
    } catch (error) {
      this.saving = false;
      console.error(`saving recording session failed: ${JSON.stringify(error)}`);
      this.publishFailure(OriginalRecordingSessionFailure.SAVE_FAILED);
      return false;
    }
  }

  private onCaptureSnapshot(snapshot: OriginalRecordingCaptureSnapshot): void {
    const previous: OriginalRecordingCaptureState = this.captureSnapshot.state;
    this.captureSnapshot = snapshot;
    if (snapshot.state === OriginalRecordingCaptureState.FAILED &&
      previous !== OriginalRecordingCaptureState.FAILED) {
      this.deactivateFocus().catch((): void => {});
      if (this.failure === OriginalRecordingSessionFailure.NONE) {
        this.publishFailure(previous === OriginalRecordingCaptureState.STARTING ?
          OriginalRecordingSessionFailure.START_FAILED :
          OriginalRecordingSessionFailure.SAVE_FAILED);
        return;
      }
    }
    this.publish();
  }

  private onAudioInterrupted(): void {
    this.focusActive = false;
    this.stop().catch((error: Object): void => {
      console.error(`interrupted recording stop failed: ${JSON.stringify(error)}`);
    });
  }

  private async deactivateFocus(): Promise<void> {
    if (!this.focusActive) {
      return;
    }
    this.focusActive = false;
    try {
      await this.focus.deactivate();
    } catch (error) {
      console.error(`recording audio focus release failed: ${JSON.stringify(error)}`);
    }
  }

  private publishFailure(failure: OriginalRecordingSessionFailure): void {
    this.failure = failure;
    this.failureSequence++;
    this.publish();
  }

  private publish(): void {
    if (this.listener !== null) {
      this.listener(this.getSnapshot());
    }
  }
}

export function isOriginalRecordingCaptureActive(state: OriginalRecordingCaptureState): boolean {
  return state === OriginalRecordingCaptureState.STARTING ||
    state === OriginalRecordingCaptureState.RECORDING ||
    state === OriginalRecordingCaptureState.PAUSING ||
    state === OriginalRecordingCaptureState.PAUSED ||
    state === OriginalRecordingCaptureState.RESUMING ||
    state === OriginalRecordingCaptureState.STOPPING;
}
