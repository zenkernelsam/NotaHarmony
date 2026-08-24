# Evidence: WebDAV backup flush-all terminal

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `LatestWriteQueue.drain()` intentionally requeues a failed snapshot and keeps the queue dirty for retry.
- `StrokePersistence.flushAll()` used `while (true)`, repeatedly collected those dirty queues and flushed them again.
- Therefore one failed page write made `NoteExporter.exportAllNotes()` loop indefinitely before its pending-save gate could reject the backup.

## Change

- Replaced the retry loop with one snapshot of dirty queues and sequential `flush()` calls.
- A failure now propagates immediately to backup preparation; successful queues are still deregistered.
- Failed queues remain available to editor-driven retries; exporter generation and pending gates remain authoritative.

## Verification

- Focused replay: docs/migration/replays/d02-backup-flush-all-terminal.mjs (6/6).
- Adjacent replay: d02-backup-library-snapshot.mjs strengthened from 11 to 12 checks and passed.
- Full Desktop Replay: REPLAY_FILES=348 PASSED={TOTAL} FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded: ohosTest in 9.303 seconds; default in 53.026 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
