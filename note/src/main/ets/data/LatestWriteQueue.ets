export interface RevisionedWrite<T> {
  revision: number;
  value: T;
  preserveBoundary: boolean;
}

export type RevisionWriter<T> = (value: T, revision: number) => Promise<void>;

// A single-writer queue. Ordinary snapshots coalesce, while user-action boundaries stay FIFO.
export class LatestWriteQueue<T> {
  private writer: RevisionWriter<T>;
  private idleHandler: (() => void) | null = null;
  private nextRevision: number = 0;
  private pending: RevisionedWrite<T>[] = [];
  private running: Promise<void> | null = null;
  private dirty: boolean = false;

  constructor(writer: RevisionWriter<T>) {
    this.writer = writer;
  }

  setIdleHandler(handler: () => void): void {
    this.idleHandler = handler;
  }

  enqueue(value: T, preserveBoundary: boolean = false): number {
    this.nextRevision++;
    const entry: RevisionedWrite<T> = {
      revision: this.nextRevision,
      value: value,
      preserveBoundary: preserveBoundary,
    };
    const lastIndex: number = this.pending.length - 1;
    if (!preserveBoundary && lastIndex >= 0 && !this.pending[lastIndex].preserveBoundary) {
      this.pending[lastIndex] = entry;
    } else {
      this.pending.push(entry);
    }
    this.dirty = true;
    this.start();
    return this.nextRevision;
  }

  async flush(): Promise<void> {
    while (this.pending.length > 0 || this.running !== null) {
      this.start();
      const active: Promise<void> | null = this.running;
      if (active !== null) {
        await active;
      }
    }
  }

  isDirty(): boolean {
    return this.dirty;
  }

  private start(): void {
    if (this.running === null && this.pending.length > 0) {
      this.running = this.drain();
    }
  }

  private async drain(): Promise<void> {
    let active: RevisionedWrite<T> | null = null;
    try {
      while (this.pending.length > 0) {
        const next: RevisionedWrite<T> | undefined = this.pending.shift();
        if (next === undefined) {
          break;
        }
        active = next;
        await this.writer(active.value, active.revision);
        active = null;
      }
      this.dirty = false;
    } catch (e) {
      // A failed user action is never replaceable. An ordinary full snapshot may be superseded
      // by a newer pending snapshot, matching the queue's original latest-state semantics.
      if (active !== null && (active.preserveBoundary || this.pending.length === 0)) {
        this.pending.unshift(active);
      }
      this.dirty = true;
      throw new Error(`queued write failed: ${JSON.stringify(e)}`);
    } finally {
      this.running = null;
      if (!this.dirty && this.idleHandler !== null) {
        this.idleHandler();
      }
    }
  }
}
