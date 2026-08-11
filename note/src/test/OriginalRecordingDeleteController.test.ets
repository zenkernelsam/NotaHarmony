import { describe, expect, it } from '@ohos/hypium';
import {
  ORIGINAL_RECORDING_DELETE_UNDO_MS, OriginalRecordingDeleteController,
  OriginalRecordingDeleteScheduler,
} from '../main/ets/core/adaptation/OriginalRecordingDeleteController';
import { decodeOriginalDeleteEntitiesTable } from
  '../main/ets/data/OriginalDeleteEntitiesOperation';
import { encodeOriginalEntityDeletes } from
  '../main/ets/data/OriginalDeleteEntitiesPayloadEncoder';
import { OriginalFlatBufferTableReader } from
  '../main/ets/data/OriginalSyncedOperationFlatBuffer';

class DeleteTestScheduler implements OriginalRecordingDeleteScheduler {
  delays: number[] = [];
  tasks: Map<number, () => void> = new Map<number, () => void>();
  cancelled: number[] = [];
  private nextHandle: number = 1;

  schedule(delayMs: number, task: () => void): number {
    const handle: number = this.nextHandle++;
    this.delays.push(delayMs);
    this.tasks.set(handle, task);
    return handle;
  }

  cancel(handle: number): void {
    this.cancelled.push(handle);
    this.tasks.delete(handle);
  }

  fire(handle: number): void {
    const task: (() => void) | undefined = this.tasks.get(handle);
    this.tasks.delete(handle);
    if (task !== undefined) {
      task();
    }
  }
}

export default function originalRecordingDeleteControllerTest() {
  describe('OriginalRecordingDeleteController', () => {
    it('encodes exact original entity-delete vectors without losing identity bits', 0, () => {
      const bytes: Uint8Array = encodeOriginalEntityDeletes([
        { timestamp: 0xFFFFFFFF, siteId: 0xFFFF },
        { timestamp: 7, siteId: 3 },
        { timestamp: 7, siteId: 3 },
      ]);
      const decoded = decodeOriginalDeleteEntitiesTable(
        OriginalFlatBufferTableReader.fromRoot(bytes));
      expect(decoded.entityDeletes.length).assertEqual(2);
      expect(decoded.entityDeletes[0].timestamp).assertEqual(0xFFFFFFFF);
      expect(decoded.entityDeletes[0].siteId).assertEqual(0xFFFF);
      expect(decoded.entityDeletes[1].timestamp).assertEqual(7);
      expect(decoded.entityUndeletes.length).assertEqual(0);
      expect(decoded.pageDeletes.length).assertEqual(0);
    });

    it('keeps deletion pending for the original ten-second undo window', 0, async () => {
      const scheduler = new DeleteTestScheduler();
      const commits: string[][] = [];
      const controller = new OriginalRecordingDeleteController(
        async (ids: string[]): Promise<void> => { commits.push(ids); }, scheduler);
      expect(controller.request('op:1:2')).assertTrue();
      expect(scheduler.delays[0]).assertEqual(ORIGINAL_RECORDING_DELETE_UNDO_MS);
      expect(controller.undo('op:1:2')).assertTrue();
      await controller.flush();
      expect(commits.length).assertEqual(0);
      expect(controller.getPendingIds().length).assertEqual(0);
    });

    it('commits on timeout and batches all scheduled deletes on flush', 0, async () => {
      const scheduler = new DeleteTestScheduler();
      const commits: string[][] = [];
      const controller = new OriginalRecordingDeleteController(
        async (ids: string[]): Promise<void> => { commits.push(ids); }, scheduler);
      controller.request('op:1:1');
      scheduler.fire(1);
      await controller.flush();
      expect(commits.length).assertEqual(1);
      expect(commits[0][0]).assertEqual('op:1:1');

      controller.request('op:2:1');
      controller.request('op:3:1');
      await controller.flush();
      expect(commits.length).assertEqual(2);
      expect(commits[1].length).assertEqual(2);
      expect(controller.getPendingIds().length).assertEqual(0);
    });
  });
}
