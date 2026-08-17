import { describe, it, expect } from '@ohos/hypium';
import {
  HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op, OpType,
} from '../main/ets/core/model/OpTypes';
import {
  NoteBackgroundSettings, PageInfo, PageOrientation, PaperSize, PaperTemplate,
} from '../main/ets/core/model/NoteTypes';
import {
  applyOriginalPaperSettings, originalDefaultNoteBackgroundSettings, sameNoteBackgroundSettings,
} from '../main/ets/core/model/PageBackgroundModel';
import {
  materializePersistentHistory, PersistentHistoryState, reducePersistentHistory, reducePersistentHistoryTail,
  replayPersistentPageMutations, RestoredHistoryState,
  trimPersistentHistoryState,
} from '../main/ets/data/PersistentHistory';
import { validateHistoryMetadata } from '../main/ets/data/PersistentHistoryMetadata';
import {
  classifyPageMutation, createPageMutation, encodePageMutationOp, PageMutationOpPayload,
} from '../main/ets/data/PageMutationOpCodec';
import { createPageStructureMutation, encodePageStructureMutation } from '../main/ets/data/PageStructureOpCodec';
import { SearchSourceElement } from '../main/ets/data/SearchIndexPolicy';
import { PageDeleteCheckpoint } from '../main/ets/data/PageDeleteCheckpoint';
import { encodePersistedElement } from '../main/ets/data/StrokePersistence';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { UndoableActionType } from '../main/ets/rendering/UndoRedoManager';
import { ElementType, ImageElement } from '../main/ets/core/model/ElementTypes';
import { encodeOriginalClipboardPasteMutation,
  OriginalClipboardPasteMutation } from '../main/ets/data/OriginalClipboardPasteMutationCodec';
import { encodeOriginalGroupMutation, OriginalGroupMutationOpPayload } from
  '../main/ets/data/OriginalGroupMutationOpCodec';
import { decodeOriginalPartialEraseMutation, encodeOriginalPartialEraseMutation } from
  '../main/ets/data/OriginalPartialEraseMutationCodec';
import { encodeNoteBackgroundMutation } from
  '../main/ets/data/NoteBackgroundMutationCodec';
import { encodeNoteTitleMutation } from '../main/ets/data/NoteTitleMutationCodec';

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

function trackedOp(opId: string, actionId: string, effect: HistoryEffect,
  actionTime: number): Op {
  const op: Op = makeOp(opId, actionId, effect, actionTime);
  if (op.history !== undefined) {
    op.history.coalesceTrack = HistoryCoalesceTrack.CREATE_INK;
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

function rejectsCheckpointTail(checkpoint: PersistentHistoryState, operations: Op[]): boolean {
  try {
    reducePersistentHistoryTail(checkpoint, operations);
  } catch (_error) {
    return true;
  }
  return false;
}

function history(actionId: string, actionTime: number = 100): HistoryMetadata {
  return {
    actionId: actionId, effect: HistoryEffect.PUSH,
    coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: actionTime,
  };
}

function mutationOp(opId: string, actionId: string, pageId: string, fromRevision: number,
  before: SearchSourceElement[], after: SearchSourceElement[], opType?: OpType): Op {
  const mutation: PageMutationOpPayload = createPageMutation(
    pageId, fromRevision, fromRevision + 1, before, after);
  return {
    opId: opId, noteId: 'note-1',
    opType: opType === undefined ? classifyPageMutation(mutation) : opType,
    payload: encodePageMutationOp(mutation), clientTime: fromRevision + 1,
    history: history(actionId),
  };
}

function pageOp(opId: string, actionId: string, opType: OpType, fromRevision: number,
  before: PageInfo[], after: PageInfo[], effect: HistoryEffect = HistoryEffect.PUSH,
  actionTime: number = fromRevision + 100): Op {
  return {
    opId: opId, noteId: 'note-1', opType: opType,
    payload: encodePageStructureMutation(
      createPageStructureMutation(fromRevision, fromRevision + 1, before, after)),
    clientTime: fromRevision + 1,
    history: {
      actionId: actionId, effect: effect,
      coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: actionTime,
    },
  };
}

function noteBackgroundOp(opId: string, actionId: string, fromRevision: number,
  selectedPageId: string, before: NoteBackgroundSettings,
  after: NoteBackgroundSettings): Op {
  return {
    opId: opId, noteId: 'note-1', opType: OpType.UPDATE_NOTE_BACKGROUND,
    payload: encodeNoteBackgroundMutation({
      fromRevision: fromRevision, toRevision: fromRevision + 1,
      selectedPageId: selectedPageId, before: before, after: after,
    }),
    clientTime: fromRevision + 1,
    history: history(actionId),
  };
}

function noteTitleOp(opId: string, actionId: string, fromRevision: number,
  selectedPageId: string, before: string, after: string): Op {
  return {
    opId: opId, noteId: 'note-1', opType: OpType.UPDATE_TITLE,
    payload: encodeNoteTitleMutation({
      fromRevision: fromRevision, toRevision: fromRevision + 1,
      selectedPageId: selectedPageId, before: before, after: after,
    }),
    clientTime: fromRevision + 1,
    history: history(actionId),
  };
}

function groupHistoryOp(opId: string, effect: HistoryEffect): Op {
  const mutation: OriginalGroupMutationOpPayload = {
    pageId: 'page-1', beforeGroups: [],
    afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
      members: ['op:14:2', 'op:1e:3'] }],
    elementOrderBefore: [
      { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
      { kind: PageElementKind.SHAPE, elementId: 'op:1e:3', zIndex: 1 },
    ],
    elementOrderAfter: [
      { kind: PageElementKind.SHAPE, elementId: 'op:1e:3', zIndex: 0 },
      { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 1 },
    ],
  };
  return {
    opId: opId, noteId: 'note-1', opType: OpType.GROUP_ELEMENTS,
    payload: encodeOriginalGroupMutation(mutation), clientTime: 100,
    history: {
      actionId: 'group-action', effect: effect,
      coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: 100,
    },
  };
}

function clipboardPasteHistoryOp(opId: string, effect: HistoryEffect): Op {
  const before: SearchSourceElement[] = [element('op:a:1', PageElementKind.STROKE, 1)];
  const after: SearchSourceElement[] = [before[0],
    element('op:14:2', PageElementKind.STROKE, 2),
    element('op:15:2', PageElementKind.SHAPE, 3)];
  const mutation: OriginalClipboardPasteMutation = {
    pageMutation: createPageMutation('page-1', 7, 8, before, after),
    groups: [{ id: 'op:1e:3', timestamp: 30, siteId: 3,
      members: ['op:14:2', 'op:15:2'] }],
    topGroupIds: ['op:1e:3'],
  };
  return {
    opId: opId, noteId: 'note-1', opType: OpType.ORIGINAL_CLIPBOARD_PASTE,
    payload: encodeOriginalClipboardPasteMutation(mutation), clientTime: 100,
    history: {
      actionId: 'clipboard-paste-action', effect: effect,
      coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: 100,
    },
  };
}

function partialEraseHistoryOp(opId: string, effect: HistoryEffect,
  grouped: boolean = false): Op {
  const before: SearchSourceElement[] = [
    element('op:a:1', PageElementKind.STROKE, 1),
    element('op:14:2', PageElementKind.STROKE, 2),
  ];
  const after: SearchSourceElement[] = [
    before[0],
    element('op:15:2', PageElementKind.STROKE, 3),
    element('op:16:2', PageElementKind.STROKE, 4),
  ];
  return {
    opId: opId, noteId: 'note-1', opType: OpType.ORIGINAL_PARTIAL_ERASE,
    payload: encodeOriginalPartialEraseMutation(
      { pageMutation: createPageMutation('page-1', 8, 9, before, after),
        replacements: grouped ? [{ sourceId: 'op:14:2',
          remnantIds: ['op:15:2', 'op:16:2'] }] : [],
        beforeGroups: grouped ? [{ id: 'op:1e:3', timestamp: 30, siteId: 3,
          members: ['op:14:2', 'op:a:1'] }] : [],
        afterGroups: grouped ? [{ id: 'op:1e:3', timestamp: 30, siteId: 3,
          members: ['op:a:1', 'op:15:2', 'op:16:2'] }] : [] }),
    clientTime: 100,
    history: {
      actionId: 'partial-erase-action', effect: effect,
      coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: 100,
    },
  };
}

function element(elementId: string, kind: number, value: number): SearchSourceElement {
  return { elementId: elementId, kind: kind, payload: new Uint8Array([value]) };
}

function page(pageId: string, pageIndex: number, template: PaperTemplate = PaperTemplate.PLAIN): PageInfo {
  return {
    pageId: pageId, pageIndex: pageIndex, size: PaperSize.A4, template: template,
    orientation: PageOrientation.PORTRAIT, widthMm: 210, heightMm: 297,
  };
}

function materializeRejects(state: PersistentHistoryState,
  checkpoints: PageDeleteCheckpoint[] = []): boolean {
  try {
    materializePersistentHistory(state, 'page-1', checkpoints);
  } catch (_error) {
    return true;
  }
  return false;
}

function stroke(id: string): StrokeElementData {
  return {
    id: id, pathPoints: [], cubicSegments: [], splatPoints: [],
    renderSpec: {
      color: 0xFF000000, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { x: 0, y: 0, width: 1, height: 1 }, maskPath: [], isFinished: true,
  };
}

function image(id: string): ImageElement {
  const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'];
  return {
    id: id, type: ElementType.IMAGE, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 },
    assetHash: bits.join(':'), assetHashBits: bits, fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 100, intrinsicWidth: 200, intrinsicHeight: 100, cropRect: null,
    blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
    enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
    imageFlippedVertically: false, positionLocked: false,
  };
}

function deleteCheckpoint(pageInfo: PageInfo): PageDeleteCheckpoint {
  return {
    noteId: 'note-1', actionId: 'delete-action', page: pageInfo,
    contentRevision: 7, indexedRevision: 7, createdTime: 100,
    elements: [
      {
        elementId: 'stroke-1', kind: PageElementKind.STROKE,
        payload: encodePersistedElement({ kind: 'stroke', data: stroke('stroke-1') }),
        revision: 7, elementOrder: 0,
      },
      {
        elementId: 'image-1', kind: PageElementKind.IMAGE,
        payload: encodePersistedElement({ kind: 'image', data: image('image-1') }),
        revision: 7, elementOrder: 1,
      },
    ],
  };
}

export default function persistentHistoryTest() {
  describe('PersistentHistory', () => {
    it('restores NCP1 Group Paste as one dedicated action across UNDO', 0, () => {
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          clipboardPasteHistoryOp('paste-push', HistoryEffect.PUSH),
          clipboardPasteHistoryOp('paste-undo', HistoryEffect.UNDO),
        ]), 'page-1');
      expect(restored.undo.length).assertEqual(0);
      expect(restored.redo.length).assertEqual(1);
      expect(restored.redo[0].action.type)
        .assertEqual(UndoableActionType.ORIGINAL_CLIPBOARD_PASTE);
      if (restored.redo[0].action.type === UndoableActionType.ORIGINAL_CLIPBOARD_PASTE) {
        expect(restored.redo[0].action.pageId).assertEqual('page-1');
        expect(restored.redo[0].action.operation.opType)
          .assertEqual(OpType.ORIGINAL_CLIPBOARD_PASTE);
      }
    });

    it('restores original partial erase as one dedicated action across UNDO', 0, () => {
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          partialEraseHistoryOp('erase-push', HistoryEffect.PUSH),
          partialEraseHistoryOp('erase-undo', HistoryEffect.UNDO),
        ]), 'page-1');
      expect(restored.undo.length).assertEqual(0);
      expect(restored.redo.length).assertEqual(1);
      expect(restored.redo[0].action.type)
        .assertEqual(UndoableActionType.ORIGINAL_PARTIAL_ERASE);
      if (restored.redo[0].action.type === UndoableActionType.ORIGINAL_PARTIAL_ERASE) {
        expect(restored.redo[0].action.pageId).assertEqual('page-1');
        expect(restored.redo[0].action.operation.opType)
          .assertEqual(OpType.ORIGINAL_PARTIAL_ERASE);
      }
    });

    it('restores NPE2 partial erase Group history as one dedicated action', 0, () => {
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          partialEraseHistoryOp('erase-push', HistoryEffect.PUSH, true),
          partialEraseHistoryOp('erase-undo', HistoryEffect.UNDO, true),
        ]), 'page-1');
      expect(restored.redo.length).assertEqual(1);
      expect(restored.redo[0].action.type)
        .assertEqual(UndoableActionType.ORIGINAL_PARTIAL_ERASE);
      if (restored.redo[0].action.type === UndoableActionType.ORIGINAL_PARTIAL_ERASE) {
        const mutation = decodeOriginalPartialEraseMutation(
          restored.redo[0].action.operation.payload);
        expect(mutation.beforeGroups[0].members.join(','))
          .assertEqual('op:14:2,op:a:1');
        expect(mutation.afterGroups[0].members.join(','))
          .assertEqual('op:a:1,op:15:2,op:16:2');
      }
    });

    it('rejects mixed or corrupt NCP1 persistent actions', 0, () => {
      const first: Op = clipboardPasteHistoryOp('paste-a', HistoryEffect.PUSH);
      const second: Op = clipboardPasteHistoryOp('paste-b', HistoryEffect.PUSH);
      second.history = first.history;
      expect(materializeRejects(reducePersistentHistory([first, second]))).assertTrue();

      const corrupt: Op = clipboardPasteHistoryOp('paste-corrupt', HistoryEffect.PUSH);
      corrupt.payload = corrupt.payload.slice(0, corrupt.payload.length - 1);
      expect(materializeRejects(reducePersistentHistory([corrupt]))).assertTrue();
    });

    it('restores NGM1 Group actions across PUSH UNDO and REDO', 0, () => {
      const undone: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          groupHistoryOp('group-push', HistoryEffect.PUSH),
          groupHistoryOp('group-undo', HistoryEffect.UNDO),
        ]), 'page-1');
      expect(undone.undo.length).assertEqual(0);
      expect(undone.redo.length).assertEqual(1);
      expect(undone.redo[0].action.type).assertEqual(UndoableActionType.GROUP_ELEMENTS);
      if (undone.redo[0].action.type === UndoableActionType.GROUP_ELEMENTS) {
        expect(undone.redo[0].action.afterGroups[0].id).assertEqual('op:28:4');
        expect(undone.redo[0].action.elementOrderAfter[0].elementId).assertEqual('op:1e:3');
      }
      const redone: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          groupHistoryOp('group-push', HistoryEffect.PUSH),
          groupHistoryOp('group-undo', HistoryEffect.UNDO),
          groupHistoryOp('group-redo', HistoryEffect.REDO),
        ]), 'page-1');
      expect(redone.undo.length).assertEqual(1);
      expect(redone.redo.length).assertEqual(0);
    });

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

    it('rebuilds grouped moves in original stack order across restart', 0, () => {
      const pushed: Op[] = [
        trackedOp('push-a', 'a', HistoryEffect.PUSH, 100),
        trackedOp('push-b', 'b', HistoryEffect.PUSH, 110),
        trackedOp('push-c', 'c', HistoryEffect.PUSH, 120),
      ];
      const undone = reducePersistentHistory(pushed.concat([
        trackedOp('undo-c', 'c', HistoryEffect.UNDO, 120),
        trackedOp('undo-b', 'b', HistoryEffect.UNDO, 110),
        trackedOp('undo-a', 'a', HistoryEffect.UNDO, 100),
      ]));
      expect(undone.undo.length).assertEqual(0);
      expect(undone.redo.length).assertEqual(3);
      expect(undone.redo[2].actionId).assertEqual('a');

      const redone = reducePersistentHistory(pushed.concat([
        trackedOp('undo-c', 'c', HistoryEffect.UNDO, 120),
        trackedOp('undo-b', 'b', HistoryEffect.UNDO, 110),
        trackedOp('undo-a', 'a', HistoryEffect.UNDO, 100),
        trackedOp('redo-a', 'a', HistoryEffect.REDO, 100),
        trackedOp('redo-b', 'b', HistoryEffect.REDO, 110),
        trackedOp('redo-c', 'c', HistoryEffect.REDO, 120),
      ]));
      expect(redone.undo.length).assertEqual(3);
      expect(redone.undo[2].actionId).assertEqual('c');
      expect(redone.redo.length).assertEqual(0);
    });

    it('continues strict stack reduction from a canonical checkpoint', 0, () => {
      const checkpoint = reducePersistentHistory([
        trackedOp('push-a', 'a', HistoryEffect.PUSH, 100),
        trackedOp('push-b', 'b', HistoryEffect.PUSH, 110),
      ]);
      const state = reducePersistentHistoryTail(checkpoint, [
        trackedOp('undo-b', 'b', HistoryEffect.UNDO, 110),
        trackedOp('redo-b', 'b', HistoryEffect.REDO, 110),
      ]);
      expect(state.undo.length).assertEqual(2);
      expect(state.undo[1].actionId).assertEqual('b');
      expect(state.redo.length).assertEqual(0);
      expect(rejectsCheckpointTail(checkpoint,
        [trackedOp('undo-a', 'a', HistoryEffect.UNDO, 100)])).assertTrue();
    });

    it('trims only the oldest undo actions and never truncates redo history', 0, () => {
      const state = reducePersistentHistory([
        makeOp('a', 'a'), makeOp('b', 'b'), makeOp('c', 'c'), makeOp('d', 'd'),
        makeOp('undo-d', 'd', HistoryEffect.UNDO),
      ]);
      const trimmed = trimPersistentHistoryState(state, 3);
      expect(trimmed.undo.length).assertEqual(2);
      expect(trimmed.undo[0].actionId).assertEqual('b');
      expect(trimmed.redo.length).assertEqual(1);
      expect(trimmed.redo[0].actionId).assertEqual('d');

      const redoOnly = reducePersistentHistory([
        makeOp('e', 'e'), makeOp('f', 'f'),
        makeOp('undo-f', 'f', HistoryEffect.UNDO),
        makeOp('undo-e', 'e', HistoryEffect.UNDO),
      ]);
      let redoOverflowRejected: boolean = false;
      try {
        trimPersistentHistoryState(redoOnly, 1);
      } catch (_error) {
        redoOverflowRejected = true;
      }
      expect(redoOverflowRejected).assertTrue();
    });

    it('lets a legacy tail invalidate checkpoint stacks conservatively', 0, () => {
      const checkpoint = reducePersistentHistory([
        makeOp('a', 'a'), makeOp('b', 'b'),
      ]);
      const state = reducePersistentHistoryTail(checkpoint, [makeOp('legacy-tail')]);
      expect(state.undo.length).assertEqual(0);
      expect(state.redo.length).assertEqual(0);
      expect(state.legacyOperationCount).assertEqual(1);
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

    it('keeps original outbound companions transparent to local history', 0, () => {
      const createPage: Op = makeOp('original-page');
      createPage.opType = OpType.ORIGINAL_CREATE_PAGE;
      const recording: Op = makeOp('original-recording');
      recording.opType = OpType.ORIGINAL_CREATE_RECORDING;
      const positions: Op = makeOp('original-positions');
      positions.opType = OpType.ORIGINAL_MODIFY_POSITIONS;
      const block: Op = makeOp('original-block');
      block.opType = OpType.ORIGINAL_MODIFY_BLOCK;
      const createBlock: Op = makeOp('original-create-block');
      createBlock.opType = OpType.ORIGINAL_CREATE_BLOCK;
      const insertText: Op = makeOp('original-insert-text');
      insertText.opType = OpType.ORIGINAL_INSERT_TEXT;
      const textVisibility: Op = makeOp('original-text-visibility');
      textVisibility.opType = OpType.ORIGINAL_TEXT_VISIBILITY;
      const textStyle: Op = makeOp('original-text-style');
      textStyle.opType = OpType.ORIGINAL_MODIFY_TEXT_STYLE;
      const paragraphStyle: Op = makeOp('original-paragraph-style');
      paragraphStyle.opType = OpType.ORIGINAL_MODIFY_PARAGRAPH_STYLE;
      const modifyPage: Op = makeOp('original-modify-page');
      modifyPage.opType = OpType.ORIGINAL_MODIFY_PAGE;
      const setMetadata: Op = makeOp('original-set-metadata');
      setMetadata.opType = OpType.ORIGINAL_SET_METADATA;
      const state: PersistentHistoryState = reducePersistentHistory([
        makeOp('op-a', 'action-a', HistoryEffect.PUSH, 100),
        createPage, positions,
        makeOp('op-b', 'action-b', HistoryEffect.PUSH, 101),
        recording, block, createBlock, insertText, textVisibility, textStyle, paragraphStyle,
        modifyPage, setMetadata,
      ]);
      expect(state.undo.length).assertEqual(2);
      expect(state.undo[0].actionId).assertEqual('action-a');
      expect(state.undo[1].actionId).assertEqual('action-b');
      expect(state.legacyOperationCount).assertEqual(0);
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

    it('materializes and replays persisted element actions in both directions', 0, () => {
      const before: SearchSourceElement[] = [element('a', 1, 1)];
      const middle: SearchSourceElement[] = [element('a', 1, 1), element('b', 2, 2)];
      const after: SearchSourceElement[] = [element('a', 1, 3), element('b', 2, 2)];
      const first: Op = mutationOp('m1', 'action-a', 'page-1', 0, before, middle);
      const second: Op = mutationOp('m2', 'action-a', 'page-1', 1, middle, after);
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([first, second]), 'page-1');

      expect(restored.undo.length).assertEqual(1);
      expect(restored.undo[0].action.type).assertEqual(UndoableActionType.PERSISTED_PAGE_MUTATIONS);
      expect(restored.undo[0].history.actionId).assertEqual('action-a');
      const reversed: SearchSourceElement[] = replayPersistentPageMutations(
        after, restored.undo[0].action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS
          ? restored.undo[0].action.operations : [], true);
      expect(reversed.length).assertEqual(1);
      expect(reversed[0].elementId).assertEqual('a');
      expect(reversed[0].payload[0]).assertEqual(1);
      const replayed: SearchSourceElement[] = replayPersistentPageMutations(
        before, restored.undo[0].action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS
          ? restored.undo[0].action.operations : [], false);
      expect(replayed.length).assertEqual(2);
      expect(replayed[0].payload[0]).assertEqual(3);
    });

    it('materializes supported page actions with strict source states', 0, () => {
      const first: PageInfo = page('page-1', 0);
      const second: PageInfo = page('page-2', 1, PaperTemplate.GRID);
      const changedFirst: PageInfo = page('page-1', 0, PaperTemplate.LINES);
      const reorderedSecond: PageInfo = page('page-2', 0, PaperTemplate.GRID);
      const reorderedFirst: PageInfo = page('page-1', 1, PaperTemplate.LINES);
      const restored: RestoredHistoryState = materializePersistentHistory(reducePersistentHistory([
        pageOp('p1', 'add', OpType.CREATE_PAGE, 0, [first], [first, second]),
        pageOp('p2', 'settings', OpType.UPDATE_PAGE, 1, [first, second], [changedFirst, second]),
        pageOp('p3', 'reorder', OpType.REORDER_PAGES, 2, [changedFirst, second],
          [reorderedSecond, reorderedFirst]),
      ]), 'page-2');

      expect(restored.undo.length).assertEqual(3);
      expect(restored.undo[0].action.type).assertEqual(UndoableActionType.ADD_PAGE);
      expect(restored.undo[1].action.type).assertEqual(UndoableActionType.PAGE_SETTINGS);
      expect(restored.undo[2].action.type).assertEqual(UndoableActionType.REORDER_PAGES);
      expect(restored.undo[2].action.pageId).assertEqual('page-2');
    });

    it('restores note-level background history after its original SET_METADATA row', 0, () => {
      const before: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
      const after: NoteBackgroundSettings = applyOriginalPaperSettings(
        before, PaperSize.A4, PaperTemplate.GRID, PageOrientation.LANDSCAPE);
      const original: Op = makeOp('original-set-metadata');
      original.opType = OpType.ORIGINAL_SET_METADATA;
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          original,
          noteBackgroundOp('background-history', 'background-action', 7,
            'page-2', before, after),
        ]), 'page-1');
      expect(restored.legacyOperationCount).assertEqual(0);
      expect(restored.undo.length).assertEqual(1);
      expect(restored.undo[0].action.type).assertEqual(UndoableActionType.NOTE_BACKGROUND);
      if (restored.undo[0].action.type === UndoableActionType.NOTE_BACKGROUND) {
        expect(restored.undo[0].action.selectedPageId).assertEqual('page-2');
        expect(sameNoteBackgroundSettings(
          restored.undo[0].action.backgroundBefore, before)).assertTrue();
        expect(sameNoteBackgroundSettings(
          restored.undo[0].action.backgroundAfter, after)).assertTrue();
      } else {
        expect(false).assertTrue();
      }
    });

    it('restores note title history after its original SET_METADATA row', 0, () => {
      const original: Op = makeOp('original-title-set-metadata');
      original.opType = OpType.ORIGINAL_SET_METADATA;
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([
          original,
          noteTitleOp('title-history', 'title-action', 12, 'page-2', 'Before', 'After'),
        ]), 'page-1');
      expect(restored.legacyOperationCount).assertEqual(0);
      expect(restored.undo.length).assertEqual(1);
      expect(restored.undo[0].action.type).assertEqual(UndoableActionType.NOTE_TITLE);
      if (restored.undo[0].action.type === UndoableActionType.NOTE_TITLE) {
        expect(restored.undo[0].action.pageId).assertEqual('page-2');
        expect(restored.undo[0].action.titleBefore).assertEqual('Before');
        expect(restored.undo[0].action.titleAfter).assertEqual('After');
      } else {
        expect(false).assertTrue();
      }
    });

    it('materializes DELETE_PAGE only with its exact durable checkpoint', 0, () => {
      const first: PageInfo = page('page-1', 0);
      const second: PageInfo = page('page-2', 1, PaperTemplate.GRID);
      const operation: Op = pageOp(
        'delete', 'delete-action', OpType.DELETE_PAGE, 0, [first, second], [first]);
      const checkpoint: PageDeleteCheckpoint = {
        noteId: 'note-1',
        actionId: 'delete-action',
        page: second,
        contentRevision: 0,
        indexedRevision: null,
        createdTime: 100,
        elements: [],
      };
      const restored: RestoredHistoryState = materializePersistentHistory(
        reducePersistentHistory([operation]), 'page-1', [checkpoint]);
      expect(restored.undo.length).assertEqual(1);
      expect(restored.undo[0].action.type).assertEqual(UndoableActionType.DELETE_PAGE);
      expect(restored.undo[0].action.pageId).assertEqual('page-2');
    });

    it('restores non-empty DELETE_PAGE content and survives PUSH UNDO REDO reduction', 0, () => {
      const first: PageInfo = page('page-1', 0);
      const second: PageInfo = page('page-2', 1, PaperTemplate.GRID);
      const checkpoint: PageDeleteCheckpoint = deleteCheckpoint(second);
      const restored: RestoredHistoryState = materializePersistentHistory(reducePersistentHistory([
        pageOp('delete-push', 'delete-action', OpType.DELETE_PAGE, 0,
          [first, second], [first], HistoryEffect.PUSH, 100),
        pageOp('delete-undo', 'delete-action', OpType.CREATE_PAGE, 1,
          [first], [first, second], HistoryEffect.UNDO, 100),
        pageOp('delete-redo', 'delete-action', OpType.DELETE_PAGE, 2,
          [first, second], [first], HistoryEffect.REDO, 100),
      ]), 'page-1', [checkpoint]);

      expect(restored.undo.length).assertEqual(1);
      expect(restored.redo.length).assertEqual(0);
      if (restored.undo[0].action.type === UndoableActionType.DELETE_PAGE) {
        expect(restored.undo[0].action.pageStrokes.length).assertEqual(1);
        expect(restored.undo[0].action.pageStrokes[0].id).assertEqual('stroke-1');
        expect(restored.undo[0].action.pageElementOrder[0].elementId).assertEqual('stroke-1');
        expect(restored.undo[0].action.pageImages.length).assertEqual(1);
        expect(restored.undo[0].action.pageImages[0].id).assertEqual('image-1');
        expect(restored.undo[0].action.pageElementOrder[1].elementId).assertEqual('image-1');
      } else {
        expect(false).assertTrue();
      }
    });

    it('rejects contradictory DELETE_PAGE checkpoint headers and elements', 0, () => {
      const first: PageInfo = page('page-1', 0);
      const second: PageInfo = page('page-2', 1, PaperTemplate.GRID);
      const operation: Op = pageOp(
        'delete', 'delete-action', OpType.DELETE_PAGE, 0, [first, second], [first]);
      const state: PersistentHistoryState = reducePersistentHistory([operation]);

      const wrongTime: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongTime.createdTime = 101;
      expect(materializeRejects(state, [wrongTime])).assertTrue();

      const wrongPage: PageDeleteCheckpoint = deleteCheckpoint(page('page-2', 1, PaperTemplate.LINES));
      expect(materializeRejects(state, [wrongPage])).assertTrue();

      const wrongRevision: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongRevision.elements[0].revision = 6;
      expect(materializeRejects(state, [wrongRevision])).assertTrue();

      const wrongHeaderRevision: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongHeaderRevision.indexedRevision = 8;
      expect(materializeRejects(state, [wrongHeaderRevision])).assertTrue();

      const wrongOrder: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongOrder.elements[0].elementOrder = 1;
      expect(materializeRejects(state, [wrongOrder])).assertTrue();

      const wrongIdentity: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongIdentity.elements[0].elementId = 'other-stroke';
      expect(materializeRejects(state, [wrongIdentity])).assertTrue();

      const wrongKind: PageDeleteCheckpoint = deleteCheckpoint(second);
      wrongKind.elements[0].kind = PageElementKind.TEXT;
      expect(materializeRejects(state, [wrongKind])).assertTrue();

      const duplicate: PageDeleteCheckpoint = deleteCheckpoint(second);
      duplicate.elements.push({
        elementId: duplicate.elements[0].elementId, kind: duplicate.elements[0].kind,
        payload: duplicate.elements[0].payload, revision: 7, elementOrder: 1,
      });
      expect(materializeRejects(state, [duplicate])).assertTrue();

      const duplicateAcrossKinds: PageDeleteCheckpoint = deleteCheckpoint(second);
      duplicateAcrossKinds.elements.push({
        elementId: duplicateAcrossKinds.elements[0].elementId, kind: PageElementKind.IMAGE,
        payload: encodePersistedElement({ kind: 'image', data: image(
          duplicateAcrossKinds.elements[0].elementId) }),
        revision: 7, elementOrder: 2,
      });
      expect(materializeRejects(state, [duplicateAcrossKinds])).assertTrue();
    });

    it('rejects missing delete checkpoints, mixed pages, discontinuous revisions, and false op types', 0, () => {
      const first: PageInfo = page('page-1', 0);
      const second: PageInfo = page('page-2', 1);
      const retained: PageInfo = page('page-2', 0);
      expect(materializeRejects(reducePersistentHistory([
        pageOp('delete', 'delete-action', OpType.DELETE_PAGE, 0, [first, second], [retained]),
      ]))).assertTrue();

      const empty: SearchSourceElement[] = [];
      const onFirst: SearchSourceElement[] = [element('a', 1, 1)];
      const onSecond: SearchSourceElement[] = [element('b', 1, 2)];
      expect(materializeRejects(reducePersistentHistory([
        mutationOp('m1', 'cross-page', 'page-1', 0, empty, onFirst),
        mutationOp('m2', 'cross-page', 'page-2', 1, empty, onSecond),
      ]))).assertTrue();
      expect(materializeRejects(reducePersistentHistory([
        mutationOp('m1', 'revision-gap', 'page-1', 0, empty, onFirst),
        mutationOp('m2', 'revision-gap', 'page-1', 3, onFirst, [element('a', 1, 2)]),
      ]))).assertTrue();
      expect(materializeRejects(reducePersistentHistory([
        mutationOp('mismatch', 'false-type', 'page-1', 0, empty, onFirst, OpType.TRANSFORM_ELEMENTS),
      ]))).assertTrue();
    });

    it('materializes a trailing legacy boundary as empty restored stacks', 0, () => {
      const reduced: PersistentHistoryState = reducePersistentHistory([
        makeOp('op-a', 'action-a'), makeOp('legacy'),
      ]);
      const restored: RestoredHistoryState = materializePersistentHistory(reduced, 'page-1');
      expect(restored.undo.length).assertEqual(0);
      expect(restored.redo.length).assertEqual(0);
      expect(restored.legacyOperationCount).assertEqual(1);
    });
  });
}
