import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata } from '../core/model/OpTypes';

export function validateHistoryMetadata(history: HistoryMetadata): void {
  if (history.actionId.length === 0 || history.actionId.length > 512 ||
    !Number.isSafeInteger(history.actionTime) || history.actionTime < 0 ||
    (history.effect !== HistoryEffect.PUSH && history.effect !== HistoryEffect.UNDO &&
      history.effect !== HistoryEffect.REDO) ||
    (history.coalesceTrack !== HistoryCoalesceTrack.NONE &&
      history.coalesceTrack !== HistoryCoalesceTrack.INSERT_TEXT &&
      history.coalesceTrack !== HistoryCoalesceTrack.REMOVE_TEXT &&
      history.coalesceTrack !== HistoryCoalesceTrack.CREATE_INK)) {
    throw new Error('operation history metadata is invalid');
  }
}
