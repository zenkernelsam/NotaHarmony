import { describe, it, expect } from '@ohos/hypium';
import {
  HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op, OpType,
} from '../main/ets/core/model/OpTypes';
import { reducePersistentHistory } from '../main/ets/data/PersistentHistory';
import { validateHistoryMetadata } from '../main/ets/data/PersistentHistoryMetadata';

function makeOp(opId: string, actionId?: string, effect: HistoryEffect = HistoryEffect.PUSH,
  actionTime: number = 100): Op {
  const op: Op = {
    opId: opId,
    noteId: 'note-1',
    opType: OpType.INSERT_ELEMENTS,
    payload: new Uint8Array([1]),
    clientTime: actionTime,
  };
  if (actionId !== undefined) {
    op.history = {
      actionId: actionId,
      effect: effect,
      coalesceTrack: HistoryCoalesceTrack.NONE,
      actionTime: actionTime,
    };
  }
  return op;
}

function rejects(operations: Op[]): boolean {
  try {
    reducePersistentHistory(operations);
  } catch (_error) {
    return true;
  }
  return false;
}

export default function persistentHistoryTest() {
  describe('PersistentHistory', () => {
    it('rebuilds PUSH UNDO REDO without treating reverse mutations as new actions', 0, () => {
      const state = reducePersistentHistory([
        makeOp('op-a', 'action-a', HistoryEffect.PUSH, 100),
        makeOp('op-b', 'action-b', HistoryEffect.PUSH, 101),
        makeOp('undo-b', 'action-b', HistoryEffect.UNDO, 101),
        makeOp('redo-b', 'action-b', HistoryEffect.REDO, 101),
      ]);
      expect(state.undo.length).assertEqual(2);
      expect(state.undo[0].actionId).assertEqual('action-a');
      expect(state.undo[1].actionId).assertEqual('action-b');
      expect(state.redo.length).assertEqual(0);
    });

    it('groups multiple mutation rows belonging to one atomic action', 0, () => {
      const state = reducePersistentHistory([
        makeOp('op-a-1', 'action-a'),
        makeOp('op-a-2', 'action-a'),
      ]);
      expect(state.undo.length).assertEqual(1);
      expect(state.undo[0].operations.length).assertEqual(2);
    });

    it('keeps legacy operations out of guessed history', 0, () => {
      const state = reducePersistentHistory([
        makeOp('old', 'old-action'), makeOp('legacy'), makeOp('op-a', 'action-a'),
      ]);
      expect(state.legacyOperationCount).assertEqual(1);
      expect(state.undo.length).assertEqual(1);
      expect(state.undo[0].actionId).assertEqual('action-a');
      const trailingLegacy = reducePersistentHistory([
        makeOp('op-b', 'action-b'), makeOp('trailing-legacy'),
      ]);
      expect(trailingLegacy.undo.length).assertEqual(0);
    });

    it('rejects unknown, stale, and duplicate action movements', 0, () => {
      expect(rejects([makeOp('undo-a', 'action-a', HistoryEffect.UNDO)])).assertTrue();
      expect(rejects([
        makeOp('op-a', 'action-a'), makeOp('op-b', 'action-b'),
        makeOp('undo-a', 'action-a', HistoryEffect.UNDO),
      ])).assertTrue();
      expect(rejects([makeOp('op-a', 'action-a'), makeOp('op-a-2', 'action-a')])).assertFalse();
      expect(rejects([
        makeOp('op-a', 'action-a'), makeOp('legacy'), makeOp('op-a-2', 'action-a'),
      ])).assertTrue();
    });

    it('rejects incomplete metadata domains', 0, () => {
      const invalid: HistoryMetadata = {
        actionId: '', effect: HistoryEffect.PUSH,
        coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: 1,
      };
      let rejected: boolean = false;
      try {
        validateHistoryMetadata(invalid);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
