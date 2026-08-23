# Harmony Evidence: Audio Source Selection Disposal Binding

Date: 2026-08-23

- Both post-dialog branches (microphone, device-only) check `editorDisposed` before `session.start()`.
- The direct microphone path without dialog remains unchanged: no await exists between its decision and start.

Replay: `d02-recording-audio-source-disposal-bound.mjs` TOTAL=3 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=304 PASSED=304 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 13 s 666 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 7 s 866 ms`
