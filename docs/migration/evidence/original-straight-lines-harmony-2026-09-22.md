# Harmony evidence — original straight-lines setting

Phase 565, 2026-09-22.

## Original evidence

`x22.java` renders the "Handwriting & drawing" subsection; case 0 mounts
"Straight lines" (`feature_settings__straight_lines`), and `v22` case 20
renders its caption: "Use the pen, pencil, or highlighter to draw a
line, then continue to hold down to automatically straighten it."

Case 1 mounts "Shapes detection" with caption (v22 case 21): "Use the
pen, pencil, or highlighter to draw a shape, then continue to hold down
to automatically detect it."

The two are **independent flags** (`l59.c`/`l59.d`, datastore keys
`straightLinesEnabled`/`shapeDetectionEnabled`), both default `true`
per `o59.c`. The same hold gesture drives both: the line-straightening
result is gated by `straightLinesEnabled`, shape results by
`shapeDetectionEnabled` — the descriptions make the split explicit
("draw a line" vs "draw a shape").

## Harmony landing

- `EditorSettingsStore.ets`: `straightLinesEnabled` pref key (original
  datastore name) via the shared boolean helper;
  `DEFAULT_STRAIGHT_LINES=true` per `o59.c`.
- `EditorViewModel.ets`: `straightLinesEnabled` loaded beside the other
  editor prefs in `initialize`.
- `NoteCanvasView.ets`:
  - `shapeDetectionAvailable()` now requires
    `straightLinesEnabled || shapeDetectionEnabled` (either flag enables
    the hold gesture) on pen/pencil/highlighter — the same tool set the
    original's captions name.
  - `tryShapeDetect` filters `result.elements`: `LINE` elements survive
    only with `straightLinesEnabled`; all other kinds only with
    `shapeDetectionEnabled`.
- `SettingsPage.ets`: "Straight lines" row (title + original caption)
  placed **before** "Shapes detection", matching `x22` order
  (case 0 → case 1); the `shape_detection` row gains its original
  caption (was missing pre-port).

## Strings

```json
straight_lines             "Straight lines"  / "直线"
straight_lines_description "Use the pen, pencil, or highlighter to
  draw a line, then continue to hold down to automatically straighten it."
                           / "使用钢笔、铅笔或荧光笔画一条线，然后继续按住即可自动拉直。"
shape_detection_description "Use the pen, pencil, or highlighter to
  draw a shape, then continue to hold down to automatically detect it."
                           / "使用钢笔、铅笔或荧光笔画一个形状，然后继续按住即可自动识别。"
```
