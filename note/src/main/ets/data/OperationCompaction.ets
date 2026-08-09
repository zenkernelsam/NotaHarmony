export function safeOperationCompactionBoundary(ackedThroughSequence: number,
  historyThroughSequence: number): number {
  if (!Number.isSafeInteger(ackedThroughSequence) || ackedThroughSequence < 0 ||
    !Number.isSafeInteger(historyThroughSequence) || historyThroughSequence < 0) {
    throw new Error('operation compaction watermarks are invalid');
  }
  if (ackedThroughSequence === 0 || historyThroughSequence === 0) {
    return 0;
  }
  return Math.min(ackedThroughSequence, historyThroughSequence);
}

export function advanceSyncedOperationCount(currentCount: number, newlyAcknowledgedCount: number): number {
  if (!Number.isSafeInteger(currentCount) || currentCount < 0 ||
    !Number.isSafeInteger(newlyAcknowledgedCount) || newlyAcknowledgedCount < 0 ||
    currentCount > Number.MAX_SAFE_INTEGER - newlyAcknowledgedCount) {
    throw new Error('synced operation count is invalid or exhausted');
  }
  return currentCount + newlyAcknowledgedCount;
}
