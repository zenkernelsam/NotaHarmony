import { describe, it, expect } from '@ohos/hypium';
import {
  AddStrokeAction, HistoryMetrics, UndoableAction, UndoableActionType, UndoRedoManager,
} from '../main/ets/rendering/UndoRedoManager';
import { HistoryEffect } from '../main/ets/core/model/OpTypes';

function makeAction(pageId: string): AddStrokeAction {
  return {
    type: UndoableActionType.ADD_STROKE,
    noteId: 'note-1',
    pageId: pageId,
    addedStrokes: [],
    elementOrderBefore: [],
    elementOrderAfter: [],
  };
}

export default function undoRedoManagerTest() {
  describe('UndoRedoManager', () => {
    it('does not move history until the caller commits a successful apply', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: UndoableAction = makeAction('page-2');
      manager.push(action);

      expect(manager.getHistoryRevision()).assertEqual(1);
      const pushedId: string = manager.getLatestHistoryMetadata()?.actionId ?? '';
      expect(pushedId.length > 0).assertTrue();
      expect(manager.getLatestHistoryMetadata()?.effect).assertEqual(HistoryEffect.PUSH);

      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canUndo()).assertTrue();
      expect(manager.canRedo()).assertFalse();

      // A failed document apply performs no commit, so the same action remains available.
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canRedo()).assertFalse();
    });

    it('rejects a stale commit and moves the exact action symmetrically', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: UndoableAction = makeAction('page-1');
      const stale: UndoableAction = makeAction('page-1');
      manager.push(action);
      const pushedId: string = manager.getLatestHistoryMetadata()?.actionId ?? '';

      const bytesBefore: number = manager.getMetrics().estimatedBytes;
      expect(manager.commitUndo(stale)).assertFalse();
      expect(manager.getHistoryRevision()).assertEqual(1);
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.getMetrics().estimatedBytes).assertEqual(bytesBefore);
      expect(manager.commitUndo(action)).assertTrue();
      expect(manager.getHistoryRevision()).assertEqual(2);
      expect(manager.getLatestHistoryMetadata()?.actionId).assertEqual(pushedId);
      expect(manager.getLatestHistoryMetadata()?.effect).assertEqual(HistoryEffect.UNDO);
      expect(manager.canUndo()).assertFalse();
      expect(manager.peekRedo() === action).assertTrue();
      expect(manager.getMetrics().estimatedBytes).assertEqual(bytesBefore);
      expect(manager.commitRedo(action)).assertTrue();
      expect(manager.getHistoryRevision()).assertEqual(3);
      expect(manager.getLatestHistoryMetadata()?.actionId).assertEqual(pushedId);
      expect(manager.getLatestHistoryMetadata()?.effect).assertEqual(HistoryEffect.REDO);
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canRedo()).assertFalse();
      expect(manager.getMetrics().estimatedBytes).assertEqual(bytesBefore);
      expect(manager.peekUndo()?.noteId).assertEqual('note-1');
    });

    it('uses the configured capacity without changing action order', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager(2);
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-2');
      const third: UndoableAction = makeAction('page-3');
      manager.push(first);
      manager.push(second);
      manager.push(third);

      expect(manager.peekUndo() === third).assertTrue();
      expect(manager.commitUndo(third)).assertTrue();
      expect(manager.peekUndo() === second).assertTrue();
      expect(manager.commitUndo(second)).assertTrue();
      expect(manager.peekUndo() === null).assertTrue();
      const metrics: HistoryMetrics = manager.getMetrics();
      expect(metrics.evictedActions).assertEqual(1);
      expect(metrics.evictedEstimatedBytes > 0).assertTrue();
    });

    it('evicts oversized history using the estimated memory budget', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager({ maxActions: 20, maxEstimatedBytes: 1 });
      manager.push(makeAction('page-1'));
      expect(manager.canUndo()).assertFalse();
      const metrics: HistoryMetrics = manager.getMetrics();
      expect(metrics.estimatedBytes).assertEqual(0);
      expect(metrics.evictedActions).assertEqual(1);
    });

    it('clears live bytes while retaining cumulative eviction metrics', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager(1);
      manager.push(makeAction('page-1'));
      manager.push(makeAction('page-2'));
      const beforeClear: HistoryMetrics = manager.getMetrics();
      expect(beforeClear.undoActions).assertEqual(1);
      expect(beforeClear.evictedActions).assertEqual(1);
      manager.clear();
      const afterClear: HistoryMetrics = manager.getMetrics();
      expect(afterClear.undoActions).assertEqual(0);
      expect(afterClear.redoActions).assertEqual(0);
      expect(afterClear.estimatedBytes).assertEqual(0);
      expect(afterClear.evictedActions).assertEqual(beforeClear.evictedActions);
      expect(afterClear.evictedEstimatedBytes).assertEqual(beforeClear.evictedEstimatedBytes);
    });

    it('normalizes invalid configured budgets instead of disabling eviction', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager({ maxActions: Number.NaN, maxEstimatedBytes: 1 });
      manager.push(makeAction('page-1'));
      expect(manager.canUndo()).assertFalse();
      expect(manager.getMetrics().evictedActions).assertEqual(1);
    });
  });
}
