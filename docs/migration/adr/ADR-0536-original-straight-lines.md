# ADR-0536 — Original straight-lines setting

- Status: accepted
- Date: 2026-09-22
- Phase: 565

## Context

The original's "Handwriting & drawing" section has two independent
detection toggles driven by the same draw-and-hold gesture:
"Straight lines" (`x22` case 0, line straightening) and "Shapes
detection" (case 1, shape conversion) — both default true (`o59.c`).
The Harmony port had a single `shapeDetectionEnabled` flag gating the
whole detector, including LINE results — so disabling "Shapes
detection" also disabled line straightening, and there was no
straight-lines toggle at all.

## Decision

- New pref `straightLinesEnabled` (original datastore key name),
  default true.
- `shapeDetectionAvailable()` now enables the hold gesture when
  *either* flag is on (same pen/pencil/highlighter tool set).
- `tryShapeDetect` filters the detector output per flag:
  `ElementType.LINE` requires `straightLinesEnabled`; all other kinds
  require `shapeDetectionEnabled`. This mirrors the original's
  independent toggles without restructuring the detector.
- SettingsPage gains the "Straight lines" row (title + original
  caption) ahead of "Shapes detection" per `x22` order, and the
  `shape_detection` row gains its original caption.

## Consequences

- Users can independently disable line straightening or shape
  detection, matching the original.
- The detector itself is unchanged — the split is a post-filter on
  classified output, so detection quality/config is untouched.
- The VM's copy loads at editor init (same registered limitation as the
  other editor settings).
- The test fake implements the widened `EditorSettingsRepository`.

## Verification

`d02-original-straight-lines.mjs` (25 assertions); full Desktop Replay
suite green; `note@default` and `note@ohosTest` builds clean.
