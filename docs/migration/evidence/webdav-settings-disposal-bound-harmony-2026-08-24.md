# Evidence: WebDAV settings disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/settings/WebDAVSettingsPage.ets`
- Before: no `aboutToDisappear()`; continuations after `showDialog()`, `client.testConnection()`,
  `WebDAVConfigStore.load()`, and `WebDAVConfigStore.save()` unconditionally wrote component state or showed UI.
- The save lease was correctly released in `finally`, but a late committed result could still mutate and toast after teardown.

## Change

- Added disposal plus lifecycle generation identity.
- Guarded every relevant continuation before state publication.
- `safeToast()` rejects disposed pages; durable persistence and shared backup operation lease semantics remain unchanged.

## Verification

- Focused replay: `docs/migration/replays/d02-webdav-settings-disposal-bound.mjs` (9/9).
- Existing adjacent replays remained green:
  - `d02-backup-page-operation-lease.mjs` (9/9)
  - `d02-webdav-config-normalization.mjs` (15/15)
- Full Desktop Replay and dual HAP static build results are recorded in the progress document before commit.
- No simulator, virtual machine, physical device, or Hypium execution.
