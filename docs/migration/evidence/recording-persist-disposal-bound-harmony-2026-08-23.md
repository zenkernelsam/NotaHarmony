# Harmony Evidence: Recording Persist Disposal Binding

Date: 2026-08-23

- After `persistCapturedOriginalRecording()` completes, the path checks `editorDisposed` before calling `loadRecordings()`.
- Disposed paths skip all snapshot publication; the durable capture remains authoritative.

Replay: `d02-recording-persist-disposal-bound.mjs` TOTAL=2 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=298 PASSED=298 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 803 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 852 ms`
