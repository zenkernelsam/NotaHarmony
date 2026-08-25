# Harmony Evidence — Recording Delete Pending Ownership

Date: 2026-08-25
Scope: Harmony static source/replay evidence

## Race

1. Delete A enters `commitRecordingDeletes()` and awaits `deleteVisible()` / `loadRecordings()`.
2. Delete B is requested; the controller adds B to its pending map and publishes `[B]`.
3. A resumes and assigns `[]`, erasing B despite B not being committed or undone.

## Implementation Facts

- Controller `request()` inserts into `pending` before `publish()`.
- Controller `startCommit()` cleanup order is: delete each owned ID, splice its commit record, then publish.
- Page listener is the sole writer to `pendingRecordingDeleteIds`; it is guarded by `editorDisposed`.
- Commit continuation keeps disposal guards around `loadRecordings()` and no longer writes pending state.

## Replay Bound

`docs/migration/replays/d02-recording-delete-pending-ownership-bound.mjs` asserts all five facts above and reports `TOTAL=5 FAILED=0`.
