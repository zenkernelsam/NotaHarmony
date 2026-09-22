# ADR-0532 — Original note-view immersive toggles

- Status: accepted
- Date: 2026-09-22
- Phase: 561

## Context

The original's note-editor settings include "Hide status bar in note
view" and "Hide navigation bar in note view" (`r22` cases 3/4). The
Harmony port had neither the toggles nor any immersive handling in the
editor.

## Decision

Port both toggles on the Phase 560 settings infrastructure:

- Two new prefs (`hideStatusBar`, `hideNavigationBar`) in
  `EditorSettingsStore`, via a shared `getBooleanPref`/`saveBooleanPref`
  helper preserving the mutex + flush-failure rollback contract.
- Two toggle rows in `SettingsPage` under "Note editor", each with the
  same optimistic-update + rollback + lifecycle-generation pattern.
- `NotePage` applies them with `window.setSpecificSystemBarEnabled` —
  `'status'` for the status bar; `'navigation'` and
  `'navigationIndicator'` together for the single original nav-bar
  switch — and restores the bars in `aboutToDisappear`.

## Consequences

- The editor can go immersive per the original's note-view semantics.
- Original defaults are not evidenced; assumed off (opt-in).
- Nav-bar handling covers both HarmonyOS navigation variants; each bar
  kind degrades independently on failure.
- The test fake implements the widened `EditorSettingsRepository`.

## Verification

`d02-original-hide-system-bars.mjs` (27 assertions); full Desktop Replay
suite green; `note@default` and `note@ohosTest` builds clean.
