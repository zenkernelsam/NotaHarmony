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
import { samePageBackground } from '../core/model/PageBackgroundModel';
import { PageDeleteCheckpoint, PageDeleteCheckpointElement } from './PageDeleteCheckpoint';
import { decodePersistedElement, PersistedElement } from './StrokePersistence';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { ImageElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { cloneImageElement, imageBlockWorldBounds } from '../core/model/ImageBlockGeometry';
import { cloneShapeElement, recomputeShapeBounds } from '../core/model/ShapeGeometry';
import { cloneTextBlockElement, textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { PageElementKind, PageElementRef } from '../core/model/PageElementOrder';
import {
  AddPageAction, DeletePageAction, PageSettingsAction, PersistedPageMutationsAction, ReorderPagesAction,
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
  return reducePersistentHistoryTail({ undo: [], redo: [], legacyOperationCount: 0 }, operations);
}

export function reducePersistentHistoryTail(initial: PersistentHistoryState,
  operations: Op[]): PersistentHistoryState {
  const undo: PersistentHistoryAction[] = clonePersistentActions(initial.undo);
  const redo: PersistentHistoryAction[] = clonePersistentActions(initial.redo);
  const known: Set<string> = new Set<string>();
  const seenPushIds: Set<string> = new Set<string>();
  for (const action of undo) {
    registerInitialAction(action, known, seenPushIds);
  }
  for (const action of redo) {
    registerInitialAction(action, known, seenPushIds);
  }
  let legacyOperationCount: number = initial.legacyOperationCount;
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

export function trimPersistentHistoryState(state: PersistentHistoryState,
  maxActions: number): PersistentHistoryState {
  if (!Number.isSafeInteger(maxActions) || maxActions <= 0) {
    throw new Error('persistent history checkpoint action limit is invalid');
  }
  const undo: PersistentHistoryAction[] = clonePersistentActions(state.undo);
  const redo: PersistentHistoryAction[] = clonePersistentActions(state.redo);
  while (undo.length + redo.length > maxActions && undo.length > 0) {
    undo.shift();
  }
  if (undo.length + redo.length > maxActions) {
    throw new Error('persistent redo history exceeds the checkpoint action limit');
  }
  return { undo: undo, redo: redo, legacyOperationCount: state.legacyOperationCount };
}

function clonePersistentActions(actions: PersistentHistoryAction[]): PersistentHistoryAction[] {
  const result: PersistentHistoryAction[] = [];
  for (const action of actions) {
    result.push({
      actionId: action.actionId,
      coalesceTrack: action.coalesceTrack,
      actionTime: action.actionTime,
      operations: action.operations.slice(),
    });
  }
  return result;
}

function registerInitialAction(action: PersistentHistoryAction, known: Set<string>,
  seenPushIds: Set<string>): void {
  if (action.actionId.length === 0 || action.operations.length === 0 || known.has(action.actionId)) {
    throw new Error('persistent history checkpoint contains an invalid action');
  }
  known.add(action.actionId);
  seenPushIds.add(action.actionId);
}

export function materializePersistentHistory(state: PersistentHistoryState,
  currentPageId: string, deleteCheckpoints: PageDeleteCheckpoint[] = []): RestoredHistoryState {
  return {
    undo: materializeActions(state.undo, currentPageId, deleteCheckpoints),
    redo: materializeActions(state.redo, currentPageId, deleteCheckpoints),
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

function materializeActions(actions: PersistentHistoryAction[], currentPageId: string,
  deleteCheckpoints: PageDeleteCheckpoint[]): RestoredHistoryAction[] {
  const result: RestoredHistoryAction[] = [];
  for (const action of actions) {
    const materialized: UndoableAction = materializeAction(action, currentPageId, deleteCheckpoints);
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

function materializeAction(action: PersistentHistoryAction, currentPageId: string,
  deleteCheckpoints: PageDeleteCheckpoint[]): UndoableAction {
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
    throw new Error('persistent page action must contain exactly one page mutation');
  }
  return materializePageAction(noteId, action.operations[0], currentPageId,
    action.actionId, action.actionTime, deleteCheckpoints);
}

function materializePageAction(noteId: string, operation: Op, currentPageId: string,
  actionId: string, actionTime: number, deleteCheckpoints: PageDeleteCheckpoint[]): UndoableAction {
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
      pageStrokes: [], pageTextBlocks: [], pageShapes: [], pageImages: [], pageElementOrder: [],
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
  if (operation.opType === OpType.DELETE_PAGE) {
    const deleted: PageInfo = findMembershipPage(mutation.beforePages, afterIds);
    const checkpoint: PageDeleteCheckpoint = findDeleteCheckpoint(
      deleteCheckpoints, noteId, actionId, deleted.pageId);
    if (!samePageInfo(checkpoint.page, deleted) || checkpoint.createdTime !== actionTime) {
      throw new Error('persistent DELETE_PAGE checkpoint header contradicts its action');
    }
    const content = materializeCheckpointContent(checkpoint);
    const selectedAfter: string = contains(afterIds, currentPageId) ? currentPageId :
      afterIds[Math.min(deleted.pageIndex, afterIds.length - 1)];
    const restored: DeletePageAction = {
      type: UndoableActionType.DELETE_PAGE,
      noteId: noteId,
      pageId: deleted.pageId,
      pageBefore: deleted,
      pageOrderBefore: beforeIds,
      pageOrderAfter: afterIds,
      pageStrokes: content.strokes,
      pageTextBlocks: content.textBlocks,
      pageShapes: content.shapes,
      pageImages: content.images,
      pageElementOrder: content.elementOrder,
      selectedPageIdBefore: deleted.pageId,
      selectedPageIdAfter: selectedAfter,
    };
    return restored;
  }
  throw new Error('persistent page action type is not restorable');
}

interface MaterializedCheckpointContent {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  shapes: ShapeElement[];
  images: ImageElement[];
  elementOrder: PageElementRef[];
}

function findDeleteCheckpoint(checkpoints: PageDeleteCheckpoint[], noteId: string,
  actionId: string, pageId: string): PageDeleteCheckpoint {
  let found: PageDeleteCheckpoint | undefined = undefined;
  for (const checkpoint of checkpoints) {
    if (checkpoint.noteId === noteId && checkpoint.actionId === actionId) {
      if (found !== undefined || checkpoint.page.pageId !== pageId) {
        throw new Error('persistent DELETE_PAGE checkpoint identity is ambiguous');
      }
      found = checkpoint;
    }
  }
  if (found === undefined) {
    throw new Error('persistent DELETE_PAGE checkpoint is missing');
  }
  return found;
}

function materializeCheckpointContent(checkpoint: PageDeleteCheckpoint): MaterializedCheckpointContent {
  if (!Number.isSafeInteger(checkpoint.contentRevision) || checkpoint.contentRevision < 0 ||
    (checkpoint.indexedRevision !== null && (!Number.isSafeInteger(checkpoint.indexedRevision) ||
      checkpoint.indexedRevision < 0 || checkpoint.indexedRevision > checkpoint.contentRevision))) {
    throw new Error('persistent DELETE_PAGE checkpoint revision header is invalid');
  }
  const strokes: StrokeElementData[] = [];
  const textBlocks: TextBlockElement[] = [];
  const shapes: ShapeElement[] = [];
  const images: ImageElement[] = [];
  const elementOrder: PageElementRef[] = [];
  for (let index: number = 0; index < checkpoint.elements.length; index++) {
    const element: PageDeleteCheckpointElement = checkpoint.elements[index];
    if (element.elementOrder !== index || element.revision !== checkpoint.contentRevision) {
      throw new Error('persistent DELETE_PAGE checkpoint element revision or order is invalid');
    }
    for (let previous: number = 0; previous < index; previous++) {
      if (checkpoint.elements[previous].kind === element.kind &&
        checkpoint.elements[previous].elementId === element.elementId) {
        throw new Error('persistent DELETE_PAGE checkpoint contains a duplicate element identity');
      }
    }
    const persisted: PersistedElement = decodePersistedElement(element.payload);
    if (element.kind === PageElementKind.STROKE && persisted.kind === 'stroke') {
      const stroke: StrokeElementData = persisted.data as StrokeElementData;
      if (stroke.id !== element.elementId) {
        throw new Error('persistent DELETE_PAGE stroke identity mismatch');
      }
      strokes.push(stroke);
    } else if (element.kind === PageElementKind.TEXT && persisted.kind === 'text') {
      const text: TextBlockElement = cloneTextBlockElement(persisted.data as TextBlockElement);
      if (text.id !== element.elementId) {
        throw new Error('persistent DELETE_PAGE text identity mismatch');
      }
      text.bounds = textBlockWorldBounds(text);
      textBlocks.push(text);
    } else if (element.kind === PageElementKind.SHAPE && persisted.kind === 'shape') {
      const shape: ShapeElement = cloneShapeElement(persisted.data as ShapeElement);
      if (shape.id !== element.elementId) {
        throw new Error('persistent DELETE_PAGE shape identity mismatch');
      }
      shape.bounds = recomputeShapeBounds(shape);
      shapes.push(shape);
    } else if (element.kind === PageElementKind.IMAGE && persisted.kind === 'image') {
      const image: ImageElement = cloneImageElement(persisted.data as ImageElement);
      if (image.id !== element.elementId) {
        throw new Error('persistent DELETE_PAGE image identity mismatch');
      }
      image.bounds = imageBlockWorldBounds(image);
      images.push(image);
    } else {
      throw new Error('persistent DELETE_PAGE element kind mismatch');
    }
    elementOrder.push({ kind: element.kind, elementId: element.elementId, zIndex: index });
  }
  return { strokes: strokes, textBlocks: textBlocks, shapes: shapes,
    images: images, elementOrder: elementOrder };
}

function samePageInfo(left: PageInfo, right: PageInfo): boolean {
  return left.pageId === right.pageId && left.pageIndex === right.pageIndex && left.size === right.size &&
    left.template === right.template && left.orientation === right.orientation &&
    left.widthMm === right.widthMm && left.heightMm === right.heightMm &&
    samePageBackground(left.background, right.background);
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
      source.widthMm !== page.widthMm || source.heightMm !== page.heightMm ||
      !samePageBackground(source.background, page.background)) {
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
