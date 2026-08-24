# Evidence: Recording toggle disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NotePage.ets`
- Function: `toggleRecording()`
- Before: no `editorDisposed` check before find/load/pause/play paths.

## Change

- Function entry now checks `editorDisposed`; disposed callbacks return immediately.

## Verification

- Focused replay: `docs/migration/replays/d02-recording-toggle-disposal-bound.mjs` -> `D02_RECORDING_TOGGLE_DISPOSAL_BOUND_REPLAY_OK TOTAL=1 FAILED=0`.
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=308 PASSED=308 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 17 s 691 ms; main BUILD SUCCESSFUL in 3 s 888 ms (25 seconds total).
