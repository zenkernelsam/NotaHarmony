# Harmony Evidence — Recording Advance Pending-Delete Gate

Date: 2026-08-25
Scope: Harmony static source/replay evidence

## Race

1. Recording A publishes COMPLETED and starts its owned async auto-advance task.
2. User requests deletion of A; controller adds A to pending IDs and unloads A.
3. Timeline rebuild excludes A.
4. A's stale continuation still calls `nextTimelineRecordingId()` and loads B, making B play although A is no longer visible/playable in the panel.

## Implementation Facts

- `advanceAfterRecordingCompletion()` checks `editorDisposed` first, then rejects if the completed ID belongs to `pendingRecordingDeleteIds`.
- Only after both gates does it query `nextTimelineRecordingId()`.
- Ownership remains with the caller's per-event increment/decrement; no blanket flag reset was introduced.

## Replay Bound

`docs/migration/replays/d02-recording-advance-pending-delete-bound.mjs` asserts gate ordering at `TOTAL=2 FAILED=0`.
