# Harmony Evidence — Recording List Page-Failure Generation

Date: 2026-08-25
Scope: Harmony static source/replay evidence

## Race

1. `loadPages()` reaches `await loadRecordings()` after successful note/page/background reads.
2. Recording query A is in flight when a retry or external trigger starts recording query B (`++recordingLoadGeneration`).
3. B settles and publishes; then page load fails for A's page generation.
4. Page catch passes because its page generation remains current and resets to the failure UI.
5. Recording continuation A later sees `generation === recordingLoadGeneration` (unchanged by the page catch) and overwrites the failure projection.

## Implementation Facts

- Current-generation page failures now execute `recordingLoadGeneration++` before `pages = []` and `recordings = []`.
- Stale/disposed page continuations continue to return before any failure effects.
- `loadRecordings()` success and failure paths remain generation/disposal guarded.
- Same-generation cleanup of `recordingsLoading` remains in `finally`.

## Replay Bound

`docs/migration/replays/d02-recording-list-page-failure-generation-bound.mjs` asserts ordering and stale-publication boundaries at `TOTAL=4 FAILED=0`.
