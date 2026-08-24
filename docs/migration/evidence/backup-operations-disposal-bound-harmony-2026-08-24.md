# Evidence: Backup operations disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/settings/BackupPage.ets`
- Before: no `aboutToDisappear()`; local export/import and cloud backup/restore continuations published
  status text, last-backup state, dialogs, or toasts after every await.
- The process-wide backup operation lease was already released in each `finally`; UI publication was not lifecycle bound.

## Change

- Added page disposal plus per-operation lifecycle identity.
- Guarded nine key await continuations across the four operations before any user-visible publication.
- Stale paths return through the existing `finally`; lease release and busy/status cleanup remain unchanged.

## Verification

- Focused replay: `docs/migration/replays/d02-backup-operations-disposal-bound.mjs` (10/10).
- Adjacent lease replay remained green: `d02-backup-page-operation-lease.mjs` (9/9).
- Full Desktop Replay: `REPLAY_FILES=316 PASSED=316 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 9 s 103 ms; main BUILD SUCCESSFUL in 55 s 860 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
