import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op, OpType } from '../core/model/OpTypes';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';
import {
  classifyPageMutation, decodePageMutationOp, PageMutationOpPayload, replayPageMutation,
} from './PageMutationOpCodec';
import {
  classifyPageStructureMutation, decodePageStructureMutation, PageStructureMutation,
} from './PageStructureOpCodec';
import { SearchSourceElement } from './SearchIndexPolicy';
import { PageInfo } from '../core/model/NoteTypes';
import {
  AddPageAction, PageSettingsAction, PersistedPageMutationsAction, ReorderPagesAction,
  RestoredHistoryAction, UndoableAction, UndoableActionType,
} from '../rendering/UndoRedoManager';

export interface PersistentHistoryAction {
  actionId: string;
  coalesceTrack: HistoryCoalesceTrack;
  actionTime: number;
  operations: Op[];
}

export interface PersistentHistoryState {
  undo: PersistentHistoryAction[];
  redo: PersistentHistoryAction[];
  legacyOperationCount: number;
}

export interface RestoredHistoryState {
  undo: RestoredHistoryAction[];
  redo: RestoredHistoryAction[];
  legacyOperationCount: number;
}

interface HistoryEvent {
  metadata: HistoryMetadata;
  operations: Op[];
  segment: number;
}

interface GroupedHistoryEvents {
  events: HistoryEvent[];
  finalSegment: number;
}

// Input must use operation_log order (client_time, sequence). Legacy rows are retained for
// document replay but cannot be guessed into an Undo action.
export function reducePersistentHistory(operations: Op[]): PersistentHistoryState {
  const undo: PersistentHistoryAction[] = [];
  const redo: PersistentHistoryAction[] = [];
  const known: Set<string> = new Set<string>();
  const seenPushIds: Set<string> = new Set<string>();
  let legacyOperationCount: number = 0;
  let activeSegment: number = 0;
  const grouped: GroupedHistoryEvents = groupEvents(
    operations, (): void => { legacyOperationCount++; });
  for (const event of grouped.events) {
    if (event.segment !== activeSegment) {
      undo.length = 0;
      redo.length = 0;
      known.clear();
      activeSegment = event.segment;
    }
    const metadata: HistoryMetadata = event.metadata;
    if (metadata.effect === HistoryEffect.PUSH) {
      if (seenPushIds.has(metadata.actionId)) {
        throw new Error('persistent history contains a duplicate PUSH action');
      }
      const action: PersistentHistoryAction = {
        actionId: metadata.actionId,
        coalesceTrack: metadata.coalesceTrack,
        actionTime: metadata.actionTime,
        operations: event.operations.slice(),
      };
      seenPushIds.add(metadata.actionId);
      known.add(metadata.actionId);
      undo.push(action);
      redo.length = 0;
      continue;
    }
    if (!known.has(metadata.actionId)) {
      throw new Error('persistent history movement references an unknown action');
    }
    if (metadata.effect === HistoryEffect.UNDO) {
      redo.push(popExpected(undo, metadata.actionId, 'UNDO'));
    } else {
      undo.push(popExpected(redo, metadata.actionId, 'REDO'));
    }
  }
  if (grouped.finalSegment !== activeSegment) {
    undo.length = 0;
    redo.length = 0;
  }
  return { undo: undo, redo: redo, legacyOperationCount: legacyOperationCount };
}

export function materializePersistentHistory(state: PersistentHistoryState,
  currentPageId: string): RestoredHistoryState {
  return {
    undo: materializeActions(state.undo, currentPageId),
    redo: materializeActions(state.redo, currentPageId),
    legacyOperationCount: state.legacyOperationCount,
  };
}

export function replayPersistentPageMutations(current: SearchSourceElement[], operations: Op[],
  isUndo: boolean): SearchSourceElement[] {
  let result: SearchSourceElement[] = current;
  if (isUndo) {
    for (let index: number = operations.length - 1; index >= 0; index--) {
      result = replayPageMutation(result, decodePageMutationOp(operations[index].payload), false);
    }
  } else {
    for (const operation of operations) {
      result = replayPageMutation(result, decodePageMutationOp(operation.payload), true);
    }
  }
  return result;
}

function materializeActions(actions: PersistentHistoryAction[], currentPageId: string): RestoredHistoryAction[] {
  const result: RestoredHistoryAction[] = [];
  for (const action of actions) {
    const materialized: UndoableAction = materializeAction(action, currentPageId);
    result.push({
      action: materialized,
      history: {
        actionId: action.actionId,
        effect: HistoryEffect.PUSH,
        coalesceTrack: action.coalesceTrack,
        actionTime: action.actionTime,
      },
    });
  }
  return result;
}

function materializeAction(action: PersistentHistoryAction, currentPageId: string): UndoableAction {
  if (action.operations.length === 0) {
    throw new Error('persistent action has no mutation operations');
  }
  const noteId: string = action.operations[0].noteId;
  for (const operation of action.operations) {
    if (operation.noteId !== noteId || operation.history === undefined ||
      operation.history.actionId !== action.actionId || operation.history.effect !== HistoryEffect.PUSH ||
      operation.history.coalesceTrack !== action.coalesceTrack ||
      operation.history.actionTime !== action.actionTime) {
      throw new Error('persistent action operation identity mismatch');
    }
  }
  if (isElementOperation(action.operations[0])) {
    let pageId: string = '';
    let previousRevision: number = -1;
    for (const operation of action.operations) {
      if (!isElementOperation(operation)) {
        throw new Error('persistent action mixes element and page mutations');
      }
      const mutation: PageMutationOpPayload = decodePageMutationOp(operation.payload);
      if (classifyPageMutation(mutation) !== operation.opType) {
        throw new Error('persistent element operation type contradicts its payload');
      }
      if (pageId.length === 0) {
        pageId = mutation.pageId;
      } else if (pageId !== mutation.pageId) {
        throw new Error('persistent element action spans multiple pages');
      }
      if (previousRevision >= 0 && mutation.fromRevision !== previousRevision) {
        throw new Error('persistent element action revisions are not contiguous');
      }
      previousRevision = mutation.toRevision;
    }
    const restored: PersistedPageMutationsAction = {
      type: UndoableActionType.PERSISTED_PAGE_MUTATIONS,
      noteId: noteId,
      pageId: pageId,
      operations: action.operations.slice(),
    };
    return restored;
  }
  if (action.operations.length !== 1) {
    throw new Error('persistent page action must contain exactly one NPG1 mutation');
  }
  return materializePageAction(noteId, action.operations[0], currentPageId);
}

function materializePageAction(noteId: string, operation: Op, currentPageId: string): UndoableAction {
  const mutation: PageStructureMutation = decodePageStructureMutation(operation.payload);
  if (classifyPageStructureMutation(mutation) !== operation.opType) {
    throw new Error('persistent page operation type contradicts its payload');
  }
  const beforeIds: string[] = mutation.beforePages.map((page: PageInfo): string => page.pageId);
  const afterIds: string[] = mutation.afterPages.map((page: PageInfo): string => page.pageId);
  if (operation.opType === OpType.CREATE_PAGE) {
    const added: PageInfo = findMembershipPage(mutation.afterPages, beforeIds);
    if (beforeIds.length === 0 || afterIds.length === 0 || afterIds[afterIds.length - 1] !== added.pageId) {
      throw new Error('persistent ADD_PAGE was not an empty tail-page action');
    }
    const selectedBefore: string = contains(beforeIds, currentPageId)
      ? currentPageId : beforeIds[beforeIds.length - 1];
    const restored: AddPageAction = {
      type: UndoableActionType.ADD_PAGE, noteId: noteId, pageId: added.pageId,
      pageAfter: added, pageOrderBefore: beforeIds, pageOrderAfter: afterIds,
      pageStrokes: [], pageTextBlocks: [], pageShapes: [], pageElementOrder: [],
      selectedPageIdBefore: selectedBefore, selectedPageIdAfter: added.pageId,
    };
    return restored;
  }
  if (operation.opType === OpType.UPDATE_PAGE) {
    const changed: PageInfo[] = changedPages(mutation.beforePages, mutation.afterPages);
    if (changed.length !== 1) {
      throw new Error('persistent PAGE_SETTINGS does not change exactly one page');
    }
    const before: PageInfo = findPage(mutation.beforePages, changed[0].pageId);
    const restored: PageSettingsAction = {
      type: UndoableActionType.PAGE_SETTINGS, noteId: noteId, pageId: changed[0].pageId,
      pageBefore: before, pageAfter: changed[0],
    };
    return restored;
  }
  if (operation.opType === OpType.REORDER_PAGES) {
    const selected: string = contains(afterIds, currentPageId) ? currentPageId : afterIds[0];
    const restored: ReorderPagesAction = {
      type: UndoableActionType.REORDER_PAGES, noteId: noteId, pageId: selected,
      pageOrderBefore: beforeIds, pageOrderAfter: afterIds,
    };
    return restored;
  }
  throw new Error('persistent page action type is not restorable');
}

function isElementOperation(operation: Op): boolean {
  return operation.opType >= OpType.INSERT_ELEMENTS && operation.opType <= OpType.REORDER_ELEMENTS;
}

function findMembershipPage(pages: PageInfo[], otherIds: string[]): PageInfo {
  for (const page of pages) {
    if (!contains(otherIds, page.pageId)) {
      return page;
    }
  }
  throw new Error('persistent page membership mutation has no affected page');
}

function changedPages(before: PageInfo[], after: PageInfo[]): PageInfo[] {
  const result: PageInfo[] = [];
  for (const page of after) {
    const source: PageInfo = findPage(before, page.pageId);
    if (source.pageIndex !== page.pageIndex || source.size !== page.size ||
      source.template !== page.template || source.orientation !== page.orientation ||
      source.widthMm !== page.widthMm || source.heightMm !== page.heightMm) {
      result.push(page);
    }
  }
  return result;
}

function findPage(pages: PageInfo[], pageId: string): PageInfo {
  for (const page of pages) {
    if (page.pageId === pageId) {
      return page;
    }
  }
  throw new Error('persistent page action references a missing page');
}

function contains(values: string[], value: string): boolean {
  for (const candidate of values) {
    if (candidate === value) {
      return true;
    }
  }
  return false;
}

function groupEvents(operations: Op[], onLegacy: () => void): GroupedHistoryEvents {
  const events: HistoryEvent[] = [];
  let active: HistoryEvent | undefined = undefined;
  let segment: number = 0;
  for (const operation of operations) {
    if (operation.history === undefined) {
      onLegacy();
      active = undefined;
      segment++;
      continue;
    }
    validateHistoryMetadata(operation.history);
    if (active !== undefined && sameEvent(active.metadata, operation.history)) {
      active.operations.push(operation);
    } else {
      active = { metadata: operation.history, operations: [operation], segment: segment };
      events.push(active);
    }
  }
  return { events: events, finalSegment: segment };
}

function sameEvent(left: HistoryMetadata, right: HistoryMetadata): boolean {
  return left.actionId === right.actionId && left.effect === right.effect &&
    left.coalesceTrack === right.coalesceTrack && left.actionTime === right.actionTime;
}

function popExpected(stack: PersistentHistoryAction[], actionId: string,
  effect: string): PersistentHistoryAction {
  const top: PersistentHistoryAction | undefined = stack.length > 0 ? stack[stack.length - 1] : undefined;
  if (top === undefined || top.actionId !== actionId) {
    throw new Error(`persistent history ${effect} does not reference the stack top`);
  }
  const result: PersistentHistoryAction | undefined = stack.pop();
  if (result === undefined) {
    throw new Error(`persistent history ${effect} stack unexpectedly became empty`);
  }
  return result;
}
