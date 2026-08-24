# Evidence: Backup page load disposal bound

Date: 2026-08-25 (Asia/Shanghai)

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
