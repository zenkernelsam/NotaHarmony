# ADR-0534 — Original auto-deselect eraser

- Status: accepted
- Date: 2026-09-22
- Phase: 563

## Context

The original's note-editor settings include "Auto-deselect eraser"
(`x22` case 3): when enabled, the toolbox switches back to the
previously selected tool after an erasing gesture (`i8f.d` reads
`l59.f` and reselects `epi.c(toolbox)`). The Harmony port kept the
eraser active until the user picked another tool, and had neither the
toggle nor the switch-back.

Researching `o59.c` also yielded the original `noteEditorSettings`
truth table, which corrects Phase 561's registered assumption:
`hideStatusBar`/`hideNavigationBar` default **true** (opt-out), not
false.

## Decision

Port the toggle and the switch-back on existing infrastructure:

- New pref `autoDeselectEraser` (original datastore key name) in
  `EditorSettingsStore` via the shared boolean helper; default false
  per `o59.c`.
- `EditorViewModel` loads it at `initialize` (alongside
  `shapeDetectionEnabled`) and exposes `autoDeselectEraserAfterUse()`:
  when enabled and an eraser is active, `selectToolById(previousToolId)`
  — which is exactly the original's "toolbox auto-switches back to your
  last used tool" (`epi.c` semantics). Hidden/missing/same previous rows
  are skipped.
- `NoteCanvasView` invokes it after a completed eraser gesture
  (`applyEraser()` on touch-up); cancelled gestures do not deselect.
- `SettingsPage` renders the row (title + original description) directly
  after `shape_detection`, matching the original `x22` item order.
- `DEFAULT_HIDE_STATUS_BAR`/`DEFAULT_HIDE_NAVIGATION_BAR` corrected to
  `true` with the `o59.c` evidence recorded; the Phase 560/562 defaults
  (keepAwake=false, noteNightView=false) are now evidence-confirmed.

## Consequences

- Eraser use auto-restores the previous tool per the original.
- First-run note views now hide system bars by default, matching the
  original opt-out semantics; existing explicit user choices are
  unaffected (the pref key is only read when present).
- The switch-back rides the existing tool-selection pipeline, so undo,
  tray persistence, and toolbar re-render behave identically to a manual
  tool switch.
- The VM's copy is loaded at editor init; toggling the setting while a
  note is open takes effect on the next note open — same limitation as
  `shapeDetectionEnabled` (registered).
- The test fake implements the widened `EditorSettingsRepository`.

## Verification

`d02-original-auto-deselect-eraser.mjs` (27 assertions); full Desktop
Replay suite green; `note@default` and `note@ohosTest` builds clean.
