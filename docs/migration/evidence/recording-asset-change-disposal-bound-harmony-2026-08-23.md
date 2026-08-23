# Harmony Evidence: Recording Asset Change Disposal Binding

Date: 2026-08-23

- `onRecordingAssetAvailabilityChanged()` checks `editorDisposed` at entry before matching note IDs or calling `loadRecordings()`.
- Teardown still unsubscribes from the hub; the disposal guard closes the synchronous delivery window.

Replay: `d02-recording-asset-change-disposal-bound.mjs` TOTAL=2 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=302 PASSED=302 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 13 s 320 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 7 s 582 ms`
