# ADR-0535 — Original palm detection

- Status: accepted
- Date: 2026-09-22
- Phase: 564

## Context

The original's note-editor settings include "Palm detection"
(`x22` case 2): "Palm Detection lets you rest your palm anywhere while
writing." — enabled by default per `o59.c`. The Harmony port cancelled
the active stroke on *any* second touch (`touches.length > 1 →
cancelActiveInteraction`), so resting a palm while writing destroyed
the in-progress stroke.

## Decision

Port the toggle plus a stroke-scoped palm-rejection policy:

- New pref `palmDetectionEnabled` (original datastore key name) in
  `EditorSettingsStore`, default `true` per the `o59.c` truth table.
- `EditorViewModel` loads it at `initialize` alongside the other editor
  prefs.
- `NoteCanvasView` tracks `activeStrokeStylus`
  (`event.sourceTool === SourceTool.Pen` at pointer down) and gates
  `palmRejectionActive()` on: pref on + stylus-driven stroke session
  active. While active:
  - extra non-pen `Down` touches are ignored (palm landing),
  - `Move` events with multiple touches keep tracking the pen pointer
    instead of cancelling,
  - non-pen `Up` events are ignored while the pen is still down; a pen
    `Up` commits the stroke even with palms still touching.

## Consequences

- Writing with a palm resting on the canvas no longer cancels strokes,
  matching the original's default-on behavior.
- Two-finger zoom/pan still works when no stylus stroke is active
  (rejection only applies mid-stroke); a second *pen* touch is never
  treated as a palm.
- Finger-driven strokes and eraser/selection gestures are unaffected —
  the description scopes rejection to "while writing".
- Palm-first ordering is a registered limitation (see evidence doc).
- The VM's copy loads at editor init; toggling while a note is open
  applies on next open (same limitation as `shapeDetectionEnabled`).
- The test fake implements the widened `EditorSettingsRepository`.

## Verification

`d02-original-palm-detection.mjs` (27 assertions); full Desktop Replay
suite green; `note@default` and `note@ohosTest` builds clean.
