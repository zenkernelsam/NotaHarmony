import { describe, it, expect } from '@ohos/hypium';
import { AsyncMutex, MutexRelease } from '../main/ets/data/AsyncMutex';

export default function asyncMutexTest() {
  describe('AsyncMutex', () => {
    it('grants queued locks in FIFO order', 0, async () => {
      const mutex = new AsyncMutex();
      const order: number[] = [];
      const first: MutexRelease = await mutex.lock();
      const secondTask: Promise<void> = (async (): Promise<void> => {
        const release: MutexRelease = await mutex.lock();
        order.push(2);
        release();
      })();
      const thirdTask: Promise<void> = (async (): Promise<void> => {
        const release: MutexRelease = await mutex.lock();
        order.push(3);
        release();
      })();

      order.push(1);
      first();
      await Promise.all([secondTask, thirdTask]);
      expect(order.length).assertEqual(3);
      expect(order[0]).assertEqual(1);
      expect(order[1]).assertEqual(2);
      expect(order[2]).assertEqual(3);
    });

    it('can be acquired again after release', 0, async () => {
      const mutex = new AsyncMutex();
      const first: MutexRelease = await mutex.lock();
      first();
      const second: MutexRelease = await mutex.lock();
      second();
      expect(true).assertTrue();
    });

    it('releases runExclusive after an operation throws', 0, async () => {
      const mutex = new AsyncMutex();
      try {
        await mutex.runExclusive(async (): Promise<void> => {
          throw new Error('expected');
        });
      } catch (_error) {
      }
      await mutex.runExclusive(async (): Promise<void> => {
      });
      expect(true).assertTrue();
    });
  });
}
