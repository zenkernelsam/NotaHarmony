# Harmony Evidence: Recording Failure UI Disposal Binding

Date: 2026-08-23

- `showRecordingFailure()` checks `editorDisposed` at entry before the permission dialog or save/start-failure toast.
- Disposed paths skip all UI publication; failure sequencing remains authoritative in the snapshot path.

Replay: `d02-recording-failure-ui-disposal-bound.mjs` TOTAL=2 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=303 PASSED=303 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 13 s 574 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 7 s 526 ms`
