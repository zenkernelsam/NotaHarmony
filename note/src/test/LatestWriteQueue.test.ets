import { describe, it, expect } from '@ohos/hypium';
import { LatestWriteQueue } from '../main/ets/data/LatestWriteQueue';

export default function latestWriteQueueTest() {
  describe('LatestWriteQueue', () => {
    it('serializes the active write and coalesces pending revisions', 0, async () => {
      let releaseFirst: () => void = () => {
      };
      const firstGate: Promise<void> = new Promise<void>((resolve: () => void) => {
        releaseFirst = resolve;
      });
      const writtenValues: number[] = [];
      const writtenRevisions: number[] = [];
      const queue = new LatestWriteQueue<number>(async (value: number, revision: number): Promise<void> => {
        writtenValues.push(value);
        writtenRevisions.push(revision);
        if (revision === 1) {
          await firstGate;
        }
      });

      queue.enqueue(1);
      queue.enqueue(2);
      queue.enqueue(3);
      releaseFirst();
      await queue.flush();

      expect(writtenValues.length).assertEqual(2);
      expect(writtenValues[0]).assertEqual(1);
      expect(writtenValues[1]).assertEqual(3);
      expect(writtenRevisions[0]).assertEqual(1);
      expect(writtenRevisions[1]).assertEqual(3);
      expect(queue.isDirty()).assertFalse();
    });

    it('keeps a failed snapshot dirty and retries it on flush', 0, async () => {
      let attempts: number = 0;
      const queue = new LatestWriteQueue<number>(async (_value: number, _revision: number): Promise<void> => {
        attempts++;
        if (attempts === 1) {
          throw new Error('injected failure');
        }
      });

      queue.enqueue(7);
      let failed: boolean = false;
      try {
        await queue.flush();
      } catch (e) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect(queue.isDirty()).assertTrue();

      await queue.flush();
      expect(attempts).assertEqual(2);
      expect(queue.isDirty()).assertFalse();
    });
  });
}
