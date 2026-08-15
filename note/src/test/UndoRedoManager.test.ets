import { describe, it, expect } from '@ohos/hypium';
import {
  AddStrokeAction, buildPartialEraseElementReplacementMap, buildPartialEraseReplacementMap,
  estimateHistoryActionBytes,
  GroupElementsAction, HistoryMetrics, partialEraseElementOrder, RestoredHistoryAction,
  partialEraseMixedElementOrder, UndoableAction, UndoableActionType, UndoRedoManager,
  validatePartialEraseElementHistoryState, validatePartialEraseStrokeHistoryState,
} from '../main/ets/rendering/UndoRedoManager';
import { HistoryCoalesceTrack, HistoryEffect } from '../main/ets/core/model/OpTypes';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { PageElementKind, PageElementRef } from '../main/ets/core/model/PageElementOrder';
import { ElementType, ShapeElement } from '../main/ets/core/model/ElementTypes';

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
    it('preserves local partial-erase remnant positions across undo and redo', 0, () => {
      const keepBefore: StrokeElementData = historyStroke('keep-before');
      const sourceA: StrokeElementData = historyStroke('source-a');
      const keepMiddle: StrokeElementData = historyStroke('keep-middle');
      const sourceB: StrokeElementData = historyStroke('source-b');
      const keepAfter: StrokeElementData = historyStroke('keep-after');
      const remnantA0: StrokeElementData = historyStroke('remnant-a-0');
      const remnantA1: StrokeElementData = historyStroke('remnant-a-1');
      const remnantB0: StrokeElementData = historyStroke('remnant-b-0');
      const sources: StrokeElementData[] = [sourceA, sourceB];
      const remnants: StrokeElementData[] = [remnantA0, remnantA1, remnantB0];
      const sourceIndices: number[] = [1, 3];
      const remnantIndices: number[] = [1, 2, 4];
      const remnantCounts: number[] = [2, 1];
      const before: StrokeElementData[] = [
        keepBefore, sourceA, keepMiddle, sourceB, keepAfter,
      ];
      const after: StrokeElementData[] = [
        keepBefore, remnantA0, remnantA1, keepMiddle, remnantB0, keepAfter,
      ];
      expect(validatePartialEraseStrokeHistoryState(
        before, sources, sourceIndices, remnants, remnantIndices, remnantCounts, false)).assertTrue();
      expect(validatePartialEraseStrokeHistoryState(
        after, sources, sourceIndices, remnants, remnantIndices, remnantCounts, true)).assertTrue();
      expect(validatePartialEraseStrokeHistoryState(
        after, sources, sourceIndices, remnants, [1, 3, 4], remnantCounts, true)).assertFalse();
      const replacementById: Map<string, StrokeElementData[]> | null =
        buildPartialEraseReplacementMap(sources, remnants, remnantCounts);
      expect(replacementById !== null).assertTrue();
      if (replacementById !== null) {
        const orderBefore: PageElementRef[] = [
          { kind: PageElementKind.STROKE, elementId: keepBefore.id, zIndex: 0 },
          { kind: PageElementKind.STROKE, elementId: sourceA.id, zIndex: 1 },
          { kind: PageElementKind.SHAPE, elementId: 'shape-middle', zIndex: 2 },
          { kind: PageElementKind.STROKE, elementId: sourceB.id, zIndex: 3 },
          { kind: PageElementKind.STROKE, elementId: keepAfter.id, zIndex: 4 },
        ];
        const orderAfter: PageElementRef[] | null = partialEraseElementOrder(
          orderBefore, replacementById);
        expect(orderAfter?.map((ref: PageElementRef): string => ref.elementId).join(','))
          .assertEqual('keep-before,remnant-a-0,remnant-a-1,shape-middle,remnant-b-0,keep-after');
      }
      expect(buildPartialEraseReplacementMap(sources, remnants, [1, 1]) === null).assertTrue();
    });

    it('replaces mixed Stroke and Shape sources with Ink in full-page order', 0, () => {
      const keep: StrokeElementData = historyStroke('keep');
      const sourceStroke: StrokeElementData = historyStroke('source-stroke');
      const sourceShape: ShapeElement = {
        id: 'source-shape', type: ElementType.POLYGON,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 10, bottom: 10 },
        vertices: [{ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 0, y: 10 }],
        isClosed: true, color: 0xFF102030, strokeWidth: 2, fillColor: null,
      };
      const strokeRemnant: StrokeElementData = historyStroke('stroke-remnant');
      const shapeRemnant0: StrokeElementData = historyStroke('shape-remnant-0');
      const shapeRemnant1: StrokeElementData = historyStroke('shape-remnant-1');
      const sourceRefs: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: sourceStroke.id, zIndex: 1 },
        { kind: PageElementKind.SHAPE, elementId: sourceShape.id, zIndex: 3 },
      ];
      const remnants: StrokeElementData[] = [strokeRemnant, shapeRemnant0, shapeRemnant1];
      const replacement = buildPartialEraseElementReplacementMap(sourceRefs, remnants, [1, 2]);
      expect(replacement !== null).assertTrue();
      const orderBefore: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: keep.id, zIndex: 0 },
        sourceRefs[0],
        { kind: PageElementKind.TEXT, elementId: 'text-middle', zIndex: 2 },
        sourceRefs[1],
      ];
      const orderAfter: PageElementRef[] | null = replacement === null ? null :
        partialEraseMixedElementOrder(orderBefore, replacement);
      expect(orderAfter?.map((ref: PageElementRef): string => ref.elementId).join(','))
        .assertEqual('keep,stroke-remnant,text-middle,shape-remnant-0,shape-remnant-1');
      expect(validatePartialEraseElementHistoryState(
        [keep, sourceStroke], [sourceShape], sourceRefs, [sourceStroke], [1], [sourceShape], [0],
        remnants, [1, 2, 3], [1, 2], false)).assertTrue();
      expect(validatePartialEraseElementHistoryState(
        [keep, strokeRemnant, shapeRemnant0, shapeRemnant1], [], sourceRefs,
        [sourceStroke], [1], [sourceShape], [0], remnants, [1, 2, 3], [1, 2], true)).assertTrue();
    });

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

function historyStroke(id: string): StrokeElementData {
  return {
    id: id, pathPoints: [], cubicSegments: [], splatPoints: [],
    renderSpec: {
      color: -16777216, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 1, bottom: 1 }, maskPath: [], isFinished: true,
  };
}
