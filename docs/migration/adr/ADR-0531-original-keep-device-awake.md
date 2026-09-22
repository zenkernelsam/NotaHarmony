# ADR-0531 — Original "Keep device awake" setting

- Status: accepted
- Date: 2026-09-22
- Phase: 560

## Context

The original's note-editor settings section includes a "Keep device
awake" toggle (`r22` case 2, `feature_settings__keep_device_awake`). The
Harmony settings page only had shape detection, and the editor never
touched the screen-timeout flag.

## Decision

Port the toggle end-to-end on existing infrastructure:

- `EditorSettingsStore` gains `getKeepDeviceAwake`/`saveKeepDeviceAwake`
  with the same mutex + rollback semantics as the sibling pref.
- `SettingsPage` gains the toggle row under "Note editor", riding the
  same load/save/lifecycle pattern as shape detection.
- `NotePage` applies `window.setWindowKeepScreenOn(enabled)` in
  `aboutToAppear` and clears it in `aboutToDisappear`, guarded by a
  dedicated generation counter.

## Consequences

- The editor honors the original setting; leaving the editor restores
  normal screen timeout automatically.
- Default assumed off (no original truth table; safe because the flag is
  opt-in behavior) — registered.
- Failures degrade silently — a keep-awake failure never blocks editing.
- The `FakeEditorSettingsRepository` test double implements the widened
  interface.

## Verification

`d02-original-keep-device-awake.mjs` (21 assertions); full Desktop Replay
suite green; `note@default` and `note@ohosTest` builds clean.
