# Harmony evidence — original "Keep device awake" setting

Phase 560, 2026-09-22.

## Original evidence

`r22.java` renders the note-editor settings section rows; case 2 mounts
`feature_settings__keep_device_awake` = "Keep device awake" as a toggle
alongside `note_view_night_mode`, `hide_status_bar`, and
`hide_navigation_bar`. The Android effect (FLAG_KEEP_SCREEN_ON while the
note view is foreground) is applied in native/obfuscated code — no
decompiled consumer is visible; the toggle + persistence surface is the
portable contract.

## Harmony landing

- `EditorSettingsStore.ets`: `keepDeviceAwake` pref key in the existing
  `noteEditorSettings` preferences store; `getKeepDeviceAwake` /
  `saveKeepDeviceAwake` on `EditorSettingsRepository` with the same
  mutex + flush-failure rollback semantics as `shapeDetectionEnabled`.
  `DEFAULT_KEEP_DEVICE_AWAKE = false`.
- `SettingsPage.ets`: second row in the "Note editor" section — a
  `Toggle` bound to `keepDeviceAwakeEnabled`, loaded in
  `reloadSettings`, saved via `setKeepDeviceAwakeEnabled` with the
  established optimistic-update + rollback + lifecycle-generation guard
  pattern.
- `NotePage.ets`: `applyKeepDeviceAwakeSetting()` runs in
  `aboutToAppear`, reads the pref, and calls
  `window.setWindowKeepScreenOn(enabled)`; `aboutToDisappear` clears the
  flag when it was applied. Generation-guarded against dispose races;
  failures log + degrade silently (editing is never blocked).

## Strings

`keep_device_awake`: "Keep device awake" / "保持设备常亮" (EN verbatim).

## Adaptations registered

- Original default value is not evidenced — assumed off (safe default:
  no screen behavior change until the user opts in).
- Applied at the editor page level (`aboutToAppear`/`aboutToDisappear`)
  since the setting lives under the original's note-editor section;
  leaving the editor always restores normal screen timeout.
- The ArkUI equivalent of FLAG_KEEP_SCREEN_ON is
  `window.setWindowKeepScreenOn` — same semantics, per-window scope.

## Verification

`d02-original-keep-device-awake.mjs` — 21 assertions covering the pref
key/interface/rollback, page state + toggle wiring + lifecycle guard,
and the appear/disappear application contract.
