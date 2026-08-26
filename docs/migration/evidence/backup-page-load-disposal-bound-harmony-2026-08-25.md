# Evidence: Backup page load disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Phase 508 increment (2026-08-26)

- Audit found that the backup error-state retry button relied only on reactive disabling before calling `reloadPage()`. A late click racing an export, import, cloud backup, or restore could increment load generation and republish LOADING.
- The retry callback now rejects `isBusy` first. Initialization, return refreshes, shared backup-operation leasing, lifecycle guards, and normal error recovery are unchanged.
- Extended the existing backup page load disposal-bound replay to `TOTAL=8 FAILED=0`.

## Source review

- `BackupPage.reloadPage()` awaited database initialization and WebDAV configuration reads before publishing config and `READY`.
- The original guard combined disposal with load generation but did not capture a lifecycle generation; a disposed continuation could still publish.
- Catch and finally used load generation alone, so superseded work could overwrite error state or mark the new load initialized.

## Change

- Captured `expectedLifecycleGeneration` before loading and increment it on disappearance.
- Added `isStaleReload()` to jointly check disposal, lifecycle generation, and load generation.
- Applied the joint gate before `READY`, `ERROR`, and `initialized` publication while preserving all backup-operation guards.

## Verification

* New focused replay: docs/migration/replays/d02-backup-page-load-disposal-bound.mjs (7/7), asserting capture, success, failure, and finally ordering.
* Adjacent WebDAV settings disposal replay: d02-webdav-settings-disposal-bound.mjs (9/9).
* Full Desktop Replay: REPLAY_FILES=363 PASSED=363 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 11.163 seconds; default in 52.950 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
## Phase 520 increment (2026-08-26)

- Continued audit found that the local Export All Notes and Import Note File buttons lacked reactive `!isBusy` disabling and their callbacks forwarded directly during long operations.
- Both buttons now disable while busy, and each callback rejects `isBusy` before invoking its existing method. Shared backup-operation leasing, file selection, cloud actions, retry behavior, lifecycle guards, and normal semantics are unchanged.
- Extended the existing backup page operation lease replay to `TOTAL=11 FAILED=0`.
