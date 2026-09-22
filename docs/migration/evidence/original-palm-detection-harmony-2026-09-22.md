# Harmony evidence — original palm detection

Phase 564, 2026-09-22.

## Original evidence

`x22.java` renders the "Handwriting & drawing" subsection; case 2 mounts
a toggle row:

- `feature_settings__palm_detection` — "Palm detection"
- `feature_settings__palm_detection_lets_you_rest_your_palm_anywhere_while_writing`
  — "Palm Detection lets you rest your palm anywhere while writing."

`o59.c` truth table: `palmDetectionEnabled` defaults **true**.

The low-level rejection runs in native/obfuscated input code (not in the
decompiled surface). The portable contract from the caption: while
writing (a stylus stroke is in progress), extra palm/finger touches must
not interrupt the stroke.

## Harmony landing

- `EditorSettingsStore.ets`: `palmDetectionEnabled` pref key (original
  datastore name); `getPalmDetectionEnabled`/`savePalmDetectionEnabled`
  on the shared boolean helper; `DEFAULT_PALM_DETECTION=true` per
  `o59.c`.
- `EditorViewModel.ets`: `palmDetectionEnabled` loaded beside
  `shapeDetectionEnabled` in `initialize`.
- `NoteCanvasView.ets`: `activeStrokeStylus` records whether the active
  pointer is `SourceTool.Pen`; `palmRejectionActive()` = pref on +
  stylus-driven stroke session active. Three touch-path guards:
  - `onTouchDown`: an extra **non-pen** touch during a stylus stroke is
    ignored (no cancel, no two-finger-gesture handoff).
  - `onTouchMove`: `touches.length > 1` no longer cancels under
    rejection; the pen pointer keeps tracking by `activePointerId`.
  - `onTouchUp`: a non-pen lift while the pen is still down is ignored;
    a pen lift with palms still down commits the stroke normally.
  - `resetPointerTracking` clears the stylus flag.

## Strings

```json
palm_detection             "Palm detection"  / "手掌检测"
palm_detection_description "Palm Detection lets you rest your palm
  anywhere while writing."       / "手掌检测可让您在书写时将手掌放在屏幕任意位置。"
```

## Registered limitation

Palm-first ordering is out of scope: if a finger stroke is already in
progress when the pen lands, the two-touch handoff still cancels it.
The original's native rejection likely also deprioritizes the finger
touch; reproducing that mid-gesture pen takeover is not portable on the
current event surface.
