# Evidence: Tool settings failure disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `EditorViewModel` publishes tool/settings persistence failures through `onPersistenceError`.
- `NotePage.loadPages()` assigned the callback with diagnostic logging followed by an unconditional toast.
- A late failure after teardown or recreation could therefore toast a disposed editor.

## Change

- Added an `editorDisposed` return guard after logging and before the toast.
- Durable failure diagnostics remain unchanged; live editors keep the existing toast.
- ViewModel error publication semantics remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-tool-settings-failure-disposal-bound.mjs (4/4).
- Adjacent replays: editor initialization 5/5, NotePage load lifecycle 4/4, and editor load disposal race 4/4.
- Full Desktop Replay: REPLAY_FILES=337 PASSED=337 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.726 seconds; default in 57.423 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
