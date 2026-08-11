import { describe, it, expect } from '@ohos/hypium';
import {
  AddStrokeAction, estimateHistoryActionBytes, GroupElementsAction, HistoryMetrics,
  RestoredHistoryAction, UndoableAction, UndoableActionType, UndoRedoManager,
} from '../main/ets/rendering/UndoRedoManager';
import { HistoryCoalesceTrack, HistoryEffect } from '../main/ets/core/model/OpTypes';

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

function restored(action: UndoableAction, actionId: string,
  track: HistoryCoalesceTrack = HistoryCoalesceTrack.NONE,
  actionTime: number = 100): RestoredHistoryAction {
  return {
    action: action,
    history: {
      actionId: actionId, effect: HistoryEffect.PUSH,
      coalesceTrack: track, actionTime: actionTime,
    },
  };
}

function restoreRejects(manager: UndoRedoManager, undo: RestoredHistoryAction[],
  redo: RestoredHistoryAction[]): boolean {
  try {
    manager.restore(undo, redo);
  } catch (_error) {
    return true;
  }
  return false;
}

export default function undoRedoManagerTest() {
  describe('UndoRedoManager', () => {
    it('accounts and moves a persisted Group action as a single boundary', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: GroupElementsAction = {
        type: UndoableActionType.GROUP_ELEMENTS, noteId: 'note-1', pageId: 'page-1',
        beforeGroups: [], afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
          members: ['op:14:2', 'op:1e:3'] }],
        elementOrderBefore: [
          { kind: 1, elementId: 'op:14:2', zIndex: 0 },
          { kind: 3, elementId: 'op:1e:3', zIndex: 1 },
        ],
        elementOrderAfter: [
          { kind: 3, elementId: 'op:1e:3', zIndex: 0 },
          { kind: 1, elementId: 'op:14:2', zIndex: 1 },
        ],
      };
      expect(estimateHistoryActionBytes(action) > 256).assertTrue();
      manager.push(action);
      expect(manager.peekUndoGroup().length).assertEqual(1);
      expect(manager.commitUndo(action)).assertTrue();
      expect(manager.peekRedo() === action).assertTrue();
    });

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

    it('reserves one page action identity before persistence and reuses it for history moves', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: UndoableAction = makeAction('page-1');
      const prepared = manager.prepareHistoryMetadata(action);
      expect(manager.getHistoryRevision()).assertEqual(0);
      expect(manager.canUndo()).assertFalse();
      manager.push(action, prepared);
      expect(manager.getLatestHistoryMetadata()?.actionId).assertEqual(prepared.actionId);
      expect(manager.getHistoryMetadataForMove(action, true)?.effect).assertEqual(HistoryEffect.UNDO);
      expect(manager.getHistoryMetadataForMove(makeAction('page-1'), true) === null).assertTrue();
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

    it('restores stack order and preserves action identity for later moves', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-2');
      const third: UndoableAction = makeAction('page-3');
      manager.restore([restored(first, 'a'), restored(second, 'b')], [restored(third, 'c')]);

      expect(manager.peekUndo() === second).assertTrue();
      expect(manager.peekRedo() === third).assertTrue();
      expect(manager.getHistoryRevision()).assertEqual(0);
      expect(manager.getLatestHistoryMetadata() === null).assertTrue();
      expect(manager.getHistoryMetadataForMove(second, true)?.actionId).assertEqual('b');
      expect(manager.getHistoryMetadataForMove(second, true)?.effect).assertEqual(HistoryEffect.UNDO);
      expect(manager.getHistoryMetadataForMove(third, false)?.actionId).assertEqual('c');
      expect(manager.commitUndo(second)).assertTrue();
      expect(manager.getLatestHistoryMetadata()?.actionId).assertEqual('b');
      expect(manager.getLatestHistoryMetadata()?.effect).assertEqual(HistoryEffect.UNDO);
    });

    it('validates a restored stack atomically and rejects duplicate identities', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const existing: UndoableAction = makeAction('existing');
      manager.push(existing);
      expect(restoreRejects(manager,
        [restored(makeAction('page-1'), 'same')], [restored(makeAction('page-2'), 'same')])).assertTrue();
      expect(manager.peekUndo() === existing).assertTrue();
      expect(manager.canRedo()).assertFalse();
    });

    it('evicts only the oldest undo entries when restored redo history fits the budget', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager(2);
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-2');
      const redo: UndoableAction = makeAction('page-3');
      manager.restore([restored(first, 'a'), restored(second, 'b')], [restored(redo, 'c')]);

      expect(manager.peekUndo() === second).assertTrue();
      expect(manager.peekRedo() === redo).assertTrue();
      expect(manager.getMetrics().undoActions).assertEqual(1);
      expect(manager.getMetrics().redoActions).assertEqual(1);
      expect(manager.getMetrics().evictedActions).assertEqual(1);
    });

    it('selects original-style adjacent ink groups with an inclusive pairwise window', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-1');
      const third: UndoableAction = makeAction('page-1');
      manager.restore([
        restored(first, 'a', HistoryCoalesceTrack.CREATE_INK, 100),
        restored(second, 'b', HistoryCoalesceTrack.CREATE_INK, 110),
        restored(third, 'c', HistoryCoalesceTrack.CREATE_INK, 120),
      ], []);

      const group = manager.peekUndoGroup();
      expect(group.length).assertEqual(3);
      expect(group[0].action === third).assertTrue();
      expect(group[1].action === second).assertTrue();
      expect(group[2].action === first).assertTrue();
      expect(group[0].history.effect).assertEqual(HistoryEffect.UNDO);
      expect(manager.commitUndoGroup(group)).assertTrue();
      expect(manager.getHistoryRevision()).assertEqual(3);

      const redo = manager.peekRedoGroup();
      expect(redo.length).assertEqual(3);
      expect(redo[0].action === first).assertTrue();
      expect(redo[1].action === second).assertTrue();
      expect(redo[2].action === third).assertTrue();
      expect(manager.commitRedoGroup(redo)).assertTrue();
      expect(manager.peekUndo() === third).assertTrue();
    });

    it('stops grouping at a mismatched track or adjacent window gap', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-1');
      const third: UndoableAction = makeAction('page-1');
      manager.restore([
        restored(first, 'a', HistoryCoalesceTrack.CREATE_INK, 100),
        restored(second, 'b', HistoryCoalesceTrack.CREATE_INK, 111),
        restored(third, 'c', HistoryCoalesceTrack.CREATE_INK, 120),
      ], []);
      expect(manager.peekUndoGroup().length).assertEqual(2);

      manager.restore([
        restored(first, 'a', HistoryCoalesceTrack.CREATE_INK, 100),
        restored(second, 'b', HistoryCoalesceTrack.REMOVE_TEXT, 110),
        restored(third, 'c', HistoryCoalesceTrack.CREATE_INK, 120),
      ], []);
      expect(manager.peekUndoGroup().length).assertEqual(1);
    });

    it('rejects a stale group without moving any entry or changing metrics', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-1');
      manager.restore([
        restored(first, 'a', HistoryCoalesceTrack.INSERT_TEXT, 100),
        restored(second, 'b', HistoryCoalesceTrack.INSERT_TEXT, 2100),
      ], []);
      const group = manager.peekUndoGroup();
      group[1].history.actionId = 'stale';
      const before: HistoryMetrics = manager.getMetrics();
      expect(manager.commitUndoGroup(group)).assertFalse();
      expect(manager.peekUndo() === second).assertTrue();
      expect(manager.canRedo()).assertFalse();
      expect(manager.getHistoryRevision()).assertEqual(0);
      expect(manager.getMetrics().estimatedBytes).assertEqual(before.estimatedBytes);
    });
  });
}
