# Harmony Evidence — Recording Loading Page-Failure Ownership

Date: 2026-08-25
Scope: Harmony static source/replay evidence

## Gap

1. Recording query A increments `recordingLoadGeneration` and sets `recordingsLoading = true`.
2. Query B starts, invalidating A.
3. B settles; the current page load then fails.
4. Page failure advances the recording generation (ADR-0408), so A's `finally` sees a non-current generation and skips cleanup.
5. Because no current recording request is active, `recordingsLoading` remains true on the failure UI.

## Implementation Facts

- Current-generation page failure performs `recordingLoadGeneration++` followed by `recordingsLoading = false`.
- This ownership handoff precedes all failure projection effects.
- `loadRecordings()` still clears loading only for its own current generation.

## Replay Bound

`docs/migration/replays/d02-recording-loading-page-failure-ownership-bound.mjs` asserts ordering and ownership boundaries at `TOTAL=3 FAILED=0`.
