# Evidence: Backup failures disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Successful continuations in local export/import and WebDAV backup/restore already checked `isStale(lifecycleGeneration)`.
- The outer catches logged late exceptions and then unconditionally called `showAlert`.
- Navigation or recreation could therefore surface a dialog on a disposed/stale BackupPage.

## Change

- Added the existing staleness gate to all four outer catches before `showAlert`.
- Durable error logs remain; busy, status, and global lease cleanup remain authoritative in `finally`.

## Verification

- Focused replay: docs/migration/replays/d02-backup-failures-disposal-bound.mjs (4/4).
- Adjacent replay: library mutation failures lifecycle 6/6.
- Full Desktop Replay: REPLAY_FILES=342 PASSED=342 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.378 seconds; default in 52.315 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
