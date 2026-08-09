import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op } from '../core/model/OpTypes';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';

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
