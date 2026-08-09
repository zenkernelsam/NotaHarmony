export type MutexRelease = () => void;

export class AsyncMutex {
  private locked: boolean = false;
  private waiters: Array<() => void> = [];

  async lock(): Promise<MutexRelease> {
    if (!this.locked) {
      this.locked = true;
      return (): void => this.release();
    }
    await new Promise<void>((resolve: () => void) => {
      this.waiters.push(resolve);
    });
    return (): void => this.release();
  }

  async runExclusive<T>(operation: () => Promise<T>): Promise<T> {
    const release: MutexRelease = await this.lock();
    try {
      return await operation();
    } finally {
      release();
    }
  }

  private release(): void {
    const next: (() => void) | undefined = this.waiters.shift();
    if (next !== undefined) {
      next();
      return;
    }
    this.locked = false;
  }
}
