# Harmony Evidence: Recording Timeline Seek Disposal Binding

Date: 2026-08-23

- Entry checks `editorDisposed` before timeline lookup, same-recording seek, or cross-recording load.
- No new controller interaction is possible after disposal; the released controller remains authoritative.

Replay: `d02-recording-seek-disposal-bound.mjs` TOTAL=2 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=297 PASSED=297 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 496 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 233 ms`
