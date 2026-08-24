# Evidence: WebDAV save feedback generation bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The save success continuation already checked the captured lifecycle generation before applying normalized state.
- Its feedback helper only tested `pageDisposed`; a replaced-but-not-disposed page could still receive a late saved or failed toast.
- The commit-failure and request-failure paths also published through that weak helper after asynchronous work.

## Change

- Extended `safeToast()` with an optional expected lifecycle generation and routed both disposal and replacement checks through `isDisposed()`.
- Passed the captured generation to every save-related toast after persistence work, including cleanup-pending success, commit failure, and request failure.
- Preserved current-generation behavior for synchronous preflight helpers and unchanged test-connection feedback.

## Actual verification

- Focused replay: docs/migration/replays/d02-webdav-save-feedback-generation-bound.mjs (5/5).
- Adjacent replay: docs/migration/replays/d02-webdav-settings-disposal-bound.mjs (9/9), strengthened for the new safeToast contract.
- Additional adjacent replay: docs/migration/replays/d02-webdav-test-failures-disposal-bound.mjs (4/4).
- Full Desktop Replay: REPLAY_FILES=351 PASSED=351 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 12.295 seconds; default in 76.318 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.