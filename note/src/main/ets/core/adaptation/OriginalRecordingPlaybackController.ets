import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { AsyncMutex } from '../../data/AsyncMutex';
import { MaterializedOriginalRecording, OriginalRecordingAssetState } from '../../data/OriginalRecordingStore';
import {
  OpenedOriginalRecordingAsset, OriginalRecordingAssetLease, OriginalRecordingAssetLoader,
} from './OriginalRecordingAssetLoader';

export enum OriginalRecordingPlaybackState {
  IDLE = 0,
  LOADING = 1,
  READY = 2,
  PLAYING = 3,
  PAUSED = 4,
  COMPLETED = 5,
  FAILED = 6,
  RELEASED = 7,
}

export interface OriginalRecordingPlaybackSnapshot {
  state: OriginalRecordingPlaybackState;
  recordingId: string | null;
  positionMs: number;
  durationMs: number;
  error: string | null;
}

export type OriginalRecordingPlaybackListener = (snapshot: OriginalRecordingPlaybackSnapshot) => void;

export class OriginalRecordingPlaybackController {
  private loader: OriginalRecordingAssetLoader;
  private mutex: AsyncMutex = new AsyncMutex();
  private player: media.AVPlayer | null = null;
  private lease: OriginalRecordingAssetLease | null = null;
  private generation: number = 0;
  private permanentlyReleased: boolean = false;
  private autoPlay: boolean = false;
  private initialPositionMs: number = 0;
  private listener: OriginalRecordingPlaybackListener | null = null;
  private snapshot: OriginalRecordingPlaybackSnapshot = emptySnapshot(OriginalRecordingPlaybackState.IDLE);
  private stateHandler: media.OnAVPlayerStateChangeHandle | null = null;
  private timeHandler: Callback<number> | null = null;
  private durationHandler: Callback<number> | null = null;
  private errorHandler: ((error: BusinessError) => void) | null = null;

  constructor(loader: OriginalRecordingAssetLoader = new OriginalRecordingAssetLoader()) {
    this.loader = loader;
  }

  setListener(listener: OriginalRecordingPlaybackListener | null): void {
    this.listener = listener;
    if (listener !== null) {
      listener(this.getSnapshot());
    }
  }

  getSnapshot(): OriginalRecordingPlaybackSnapshot {
    return { state: this.snapshot.state, recordingId: this.snapshot.recordingId,
      positionMs: this.snapshot.positionMs, durationMs: this.snapshot.durationMs,
      error: this.snapshot.error };
  }

  async load(recording: MaterializedOriginalRecording, autoPlay: boolean = false,
    initialPositionMs: number = 0): Promise<boolean> {
    const requestGeneration: number = ++this.generation;
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      if (this.permanentlyReleased || requestGeneration !== this.generation) {
        return false;
      }
      await this.releaseCurrent();
      if (requestGeneration !== this.generation) {
        return false;
      }
      const opened: OpenedOriginalRecordingAsset = this.loader.open(recording);
      if (opened.state !== OriginalRecordingAssetState.READY || opened.lease === null) {
        this.publish({ state: OriginalRecordingPlaybackState.FAILED, recordingId: recording.id,
          positionMs: 0, durationMs: 0, error: opened.error ?? 'recording asset is unavailable' });
        return false;
      }
      let player: media.AVPlayer | null = null;
      try {
        player = await media.createAVPlayer();
        if (requestGeneration !== this.generation || this.permanentlyReleased) {
          await player.release();
          opened.lease.close();
          return false;
        }
        this.player = player;
        this.lease = opened.lease;
        this.autoPlay = autoPlay;
        this.initialPositionMs = sanitizeInitialPosition(initialPositionMs);
        this.installHandlers(player, requestGeneration);
        this.publish({ state: OriginalRecordingPlaybackState.LOADING, recordingId: recording.id,
          positionMs: 0, durationMs: 0, error: null });
        player.fdSrc = opened.lease.descriptor;
        return true;
      } catch (error) {
        if (player !== null) {
          if (player === this.player) {
            this.removeHandlers(player);
            this.player = null;
            this.lease = null;
          }
          try {
            await player.release();
          } catch (_releaseError) {
          }
        }
        opened.lease.close();
        if (requestGeneration === this.generation) {
          this.publishFailure(recording.id, error);
        }
        return false;
      }
    });
  }

  async play(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      const player: media.AVPlayer | null = this.player;
      if (player === null || this.permanentlyReleased) {
        return false;
      }
      try {
        if (player.state === 'completed') {
          player.seek(0);
        } else if (player.state !== 'prepared' && player.state !== 'paused') {
          return false;
        }
        await player.play();
        return true;
      } catch (error) {
        this.publishFailure(this.snapshot.recordingId, error);
        return false;
      }
    });
  }

  async pause(): Promise<boolean> {
    return await this.mutex.runExclusive(async (): Promise<boolean> => {
      const player: media.AVPlayer | null = this.player;
      if (player === null || player.state !== 'playing' || this.permanentlyReleased) {
        return false;
      }
      try {
        await player.pause();
        return true;
      } catch (error) {
        this.publishFailure(this.snapshot.recordingId, error);
        return false;
      }
    });
  }

  seek(positionMs: number): boolean {
    const player: media.AVPlayer | null = this.player;
    if (player === null || this.permanentlyReleased ||
      (player.state !== 'prepared' && player.state !== 'playing' &&
        player.state !== 'paused' && player.state !== 'completed')) {
      return false;
    }
    const target: number = clampRecordingSeek(positionMs, this.snapshot.durationMs);
    try {
      player.seek(target);
      return true;
    } catch (error) {
      this.publishFailure(this.snapshot.recordingId, error);
      return false;
    }
  }

  async release(): Promise<void> {
    ++this.generation;
    this.permanentlyReleased = true;
    await this.mutex.runExclusive(async (): Promise<void> => {
      await this.releaseCurrent();
      this.publish(emptySnapshot(OriginalRecordingPlaybackState.RELEASED));
      this.listener = null;
    });
  }

  private installHandlers(player: media.AVPlayer, generation: number): void {
    this.stateHandler = (state: media.AVPlayerState, _reason: media.StateChangeReason): void => {
      this.handleStateChange(player, generation, state);
    };
    this.timeHandler = (positionMs: number): void => {
      if (generation === this.generation && player === this.player) {
        this.publish({ state: this.snapshot.state, recordingId: this.snapshot.recordingId,
          positionMs: clampRecordingSeek(positionMs, this.snapshot.durationMs),
          durationMs: this.snapshot.durationMs, error: this.snapshot.error });
      }
    };
    this.durationHandler = (durationMs: number): void => {
      if (generation === this.generation && player === this.player) {
        const duration: number = validDuration(durationMs);
        this.publish({ state: this.snapshot.state, recordingId: this.snapshot.recordingId,
          positionMs: clampRecordingSeek(this.snapshot.positionMs, duration),
          durationMs: duration, error: this.snapshot.error });
      }
    };
    this.errorHandler = (error: BusinessError): void => {
      if (generation === this.generation && player === this.player) {
        this.publishFailure(this.snapshot.recordingId, error);
      }
    };
    player.on('stateChange', this.stateHandler);
    player.on('timeUpdate', this.timeHandler);
    player.on('durationUpdate', this.durationHandler);
    player.on('error', this.errorHandler);
  }

  private handleStateChange(player: media.AVPlayer, generation: number,
    state: media.AVPlayerState): void {
    if (generation !== this.generation || player !== this.player) {
      return;
    }
    if (state === 'initialized') {
      this.prepare(player, generation);
      return;
    }
    if (state === 'prepared') {
      this.publishState(OriginalRecordingPlaybackState.READY);
      this.finishPreparedLoad(player, generation);
    } else if (state === 'playing') {
      this.publishState(OriginalRecordingPlaybackState.PLAYING);
    } else if (state === 'paused') {
      this.publishState(OriginalRecordingPlaybackState.PAUSED);
    } else if (state === 'completed') {
      this.publishState(OriginalRecordingPlaybackState.COMPLETED);
    } else if (state === 'error') {
      this.publishFailure(this.snapshot.recordingId, new Error('AVPlayer entered error state'));
    }
  }

  private async prepare(player: media.AVPlayer, generation: number): Promise<void> {
    try {
      await player.prepare();
    } catch (error) {
      if (generation === this.generation && player === this.player) {
        this.publishFailure(this.snapshot.recordingId, error);
      }
    }
  }

  private async playPrepared(player: media.AVPlayer, generation: number): Promise<void> {
    try {
      await player.play();
    } catch (error) {
      if (generation === this.generation && player === this.player) {
        this.publishFailure(this.snapshot.recordingId, error);
      }
    }
  }

  private finishPreparedLoad(player: media.AVPlayer, generation: number): void {
    try {
      if (this.initialPositionMs > 0) {
        player.seek(this.initialPositionMs);
        this.initialPositionMs = 0;
      }
      if (this.autoPlay) {
        this.autoPlay = false;
        this.playPrepared(player, generation);
      }
    } catch (error) {
      if (generation === this.generation && player === this.player) {
        this.publishFailure(this.snapshot.recordingId, error);
      }
    }
  }

  private async releaseCurrent(): Promise<void> {
    const player: media.AVPlayer | null = this.player;
    const lease: OriginalRecordingAssetLease | null = this.lease;
    this.player = null;
    this.lease = null;
    this.autoPlay = false;
    this.initialPositionMs = 0;
    if (player !== null) {
      this.removeHandlers(player);
      try {
        if (player.state !== 'released') {
          await player.release();
        }
      } catch (_releaseError) {
      }
    }
    if (lease !== null) {
      lease.close();
    }
  }

  private removeHandlers(player: media.AVPlayer): void {
    if (this.stateHandler !== null) {
      player.off('stateChange', this.stateHandler);
    }
    if (this.timeHandler !== null) {
      player.off('timeUpdate', this.timeHandler);
    }
    if (this.durationHandler !== null) {
      player.off('durationUpdate', this.durationHandler);
    }
    if (this.errorHandler !== null) {
      player.off('error', this.errorHandler);
    }
    this.stateHandler = null;
    this.timeHandler = null;
    this.durationHandler = null;
    this.errorHandler = null;
  }

  private publishState(state: OriginalRecordingPlaybackState): void {
    this.publish({ state: state, recordingId: this.snapshot.recordingId,
      positionMs: this.snapshot.positionMs, durationMs: this.snapshot.durationMs, error: null });
  }

  private publishFailure(recordingId: string | null, error: Object): void {
    this.publish({ state: OriginalRecordingPlaybackState.FAILED, recordingId: recordingId,
      positionMs: this.snapshot.positionMs, durationMs: this.snapshot.durationMs,
      error: JSON.stringify(error) });
  }

  private publish(snapshot: OriginalRecordingPlaybackSnapshot): void {
    this.snapshot = snapshot;
    if (this.listener !== null) {
      this.listener(this.getSnapshot());
    }
  }
}

export function clampRecordingSeek(positionMs: number, durationMs: number): number {
  if (!Number.isFinite(positionMs) || positionMs <= 0) {
    return 0;
  }
  const duration: number = validDuration(durationMs);
  if (duration === 0) {
    return 0;
  }
  return Math.min(Math.round(positionMs), duration);
}

function validDuration(durationMs: number): number {
  return Number.isSafeInteger(durationMs) && durationMs > 0 ? durationMs : 0;
}

function sanitizeInitialPosition(positionMs: number): number {
  return Number.isSafeInteger(positionMs) && positionMs > 0 ? positionMs : 0;
}

function emptySnapshot(state: OriginalRecordingPlaybackState): OriginalRecordingPlaybackSnapshot {
  return { state: state, recordingId: null, positionMs: 0, durationMs: 0, error: null };
}
