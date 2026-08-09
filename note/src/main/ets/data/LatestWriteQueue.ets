export interface RevisionedWrite<T> {
  revision: number;
  value: T;
}

export type RevisionWriter<T> = (value: T, revision: number) => Promise<void>;

// A single-writer queue that coalesces writes which have not started yet.
export class LatestWriteQueue<T> {
  private writer: RevisionWriter<T>;
  private nextRevision: number = 0;
  private pending: RevisionedWrite<T> | null = null;
  private running: Promise<void> | null = null;
  private dirty: boolean = false;

  constructor(writer: RevisionWriter<T>) {
    this.writer = writer;
  }

  enqueue(value: T): number {
    this.nextRevision++;
    this.pending = { revision: this.nextRevision, value: value };
    this.dirty = true;
    this.start();
    return this.nextRevision;
  }

  async flush(): Promise<void> {
    while (this.pending !== null || this.running !== null) {
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
    if (this.running === null && this.pending !== null) {
      this.running = this.drain();
    }
  }

  private async drain(): Promise<void> {
    let active: RevisionedWrite<T> | null = null;
    try {
      while (this.pending !== null) {
        active = this.pending;
        this.pending = null;
        await this.writer(active.value, active.revision);
        active = null;
      }
      this.dirty = false;
    } catch (e) {
      if (active !== null && (this.pending === null || this.pending.revision < active.revision)) {
        this.pending = active;
      }
      this.dirty = true;
      throw new Error(`queued write failed: ${JSON.stringify(e)}`);
    } finally {
      this.running = null;
    }
  }
}
