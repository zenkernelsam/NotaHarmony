export const ORIGINAL_RECORDING_DELETE_UNDO_MS: number = 10000;

export interface OriginalRecordingDeleteScheduler {
  schedule(delayMs: number, task: () => void): number;
  cancel(handle: number): void;
}

export type OriginalRecordingDeleteCommitter = (recordingIds: string[]) => Promise<void>;
export type OriginalRecordingDeleteListener = (pendingIds: string[]) => void;
export type OriginalRecordingDeleteFailureListener = (error: Object) => void;

interface PendingRecordingDelete {
  recordingId: string;
  timer: number | null;
}

class DefaultRecordingDeleteScheduler implements OriginalRecordingDeleteScheduler {
  schedule(delayMs: number, task: () => void): number {
    return setTimeout(task, delayMs);
  }

  cancel(handle: number): void {
    clearTimeout(handle);
  }
}

export class OriginalRecordingDeleteController {
  private committer: OriginalRecordingDeleteCommitter;
  private scheduler: OriginalRecordingDeleteScheduler;
  private listener: OriginalRecordingDeleteListener | null = null;
  private failureListener: OriginalRecordingDeleteFailureListener | null = null;
  private pending: Map<string, PendingRecordingDelete> =
    new Map<string, PendingRecordingDelete>();
  private commits: Promise<void>[] = [];

  constructor(committer: OriginalRecordingDeleteCommitter,
    scheduler: OriginalRecordingDeleteScheduler = new DefaultRecordingDeleteScheduler()) {
    this.committer = committer;
    this.scheduler = scheduler;
  }

  setListener(listener: OriginalRecordingDeleteListener | null): void {
    this.listener = listener;
    this.publish();
  }

  setFailureListener(listener: OriginalRecordingDeleteFailureListener | null): void {
    this.failureListener = listener;
  }

  request(recordingId: string): boolean {
    if (recordingId.length === 0 || this.pending.has(recordingId)) {
      return false;
    }
    const entry: PendingRecordingDelete = { recordingId: recordingId, timer: null };
    entry.timer = this.scheduler.schedule(ORIGINAL_RECORDING_DELETE_UNDO_MS, (): void => {
      entry.timer = null;
      this.startCommit([recordingId]);
    });
    this.pending.set(recordingId, entry);
    this.publish();
    return true;
  }

  undo(recordingId: string): boolean {
    const entry: PendingRecordingDelete | undefined = this.pending.get(recordingId);
    if (entry === undefined || entry.timer === null) {
      return false;
    }
    this.scheduler.cancel(entry.timer);
    this.pending.delete(recordingId);
    this.publish();
    return true;
  }

  getPendingIds(): string[] {
    return Array.from(this.pending.keys());
  }

  async flush(): Promise<void> {
    const scheduled: string[] = [];
    for (const entry of this.pending.values()) {
      if (entry.timer !== null) {
        this.scheduler.cancel(entry.timer);
        entry.timer = null;
        scheduled.push(entry.recordingId);
      }
    }
    if (scheduled.length > 0) {
      this.startCommit(scheduled);
    }
    await Promise.all(this.commits.slice());
  }

  private startCommit(recordingIds: string[]): void {
    const commit: Promise<void> = this.committer(recordingIds.slice())
      .catch((error: Object): void => {
        if (this.failureListener !== null) {
          this.failureListener(error);
        }
      })
      .finally((): void => {
        for (const recordingId of recordingIds) {
          this.pending.delete(recordingId);
        }
        const index: number = this.commits.indexOf(commit);
        if (index >= 0) {
          this.commits.splice(index, 1);
        }
        this.publish();
      });
    this.commits.push(commit);
  }

  private publish(): void {
    if (this.listener !== null) {
      this.listener(this.getPendingIds());
    }
  }
}
