# Harmony evidence — original auto-deselect eraser

Phase 563, 2026-09-22.

## Original evidence

`x22.java` renders the "Handwriting & drawing" subsection of the
note-editor settings; case 3 mounts a toggle row:

- `feature_settings__auto_deselect_eraser` — "Auto-deselect eraser"
- `feature_settings__auto_deselect_eraser_description` — "After erasing,
  the toolbox auto-switches back to your last used tool."

`i8f.d` (toolbox controller) is the consumer:

```java
boolean z = ((l59) this.h.f().getValue()).f;   // autoDeselectEraser
if (z) {
    x6f toolbox = ...;
    j7f prev = epi.c(toolbox);                 // previously selected tool
    if (prev != null) { this.b.e(prev, ...); } // select previous tool
}
```

`o59` declares the `noteEditorSettings` datastore keys; `o59.c` gives the
read-side truth table:

| key | default |
| --- | --- |
| keepAwake | false |
| noteNightView | false |
| straightLinesEnabled | true |
| shapeDetectionEnabled | true |
| palmDetectionEnabled | true |
| autoDeselectEraser | **false** |
| rulerUnits | IMPERIAL |
| hideStatusBar | **true** |
| hideNavigationBar | **true** |

This corrects the Phase 561 registered assumption — the original hides
both system bars in note view **by default** (opt-out), and confirms the
Phase 560/562 defaults (keepAwake=false, noteNightView=false).

## Harmony landing

- `EditorSettingsStore.ets`: `autoDeselectEraser` pref key (same proto
  name) in `noteEditorSettings`; `getAutoDeselectEraser`/
  `saveAutoDeselectEraser` on the shared boolean helper.
  `DEFAULT_AUTO_DESELECT_ERASER=false`; `DEFAULT_HIDE_STATUS_BAR`/
  `DEFAULT_HIDE_NAVIGATION_BAR` corrected to `true` per `o59.c`.
- `EditorViewModel.ets`: `autoDeselectEraser` loaded beside
  `shapeDetectionEnabled` in `initialize`; `autoDeselectEraserAfterUse()`
  implements `i8f.d` — when enabled and the active tool is an eraser,
  reselect `previousToolId` (the toolbox's previously-selected row,
  skipping hidden/missing rows).
- `NoteCanvasView.ets`: after `applyEraser()` completes on touch-up,
  `viewModel.autoDeselectEraserAfterUse()` fires (catch →
  `onPersistenceError`). Cancellation paths (`cancelActiveInteraction`)
  do not trigger it — the gesture was not "after erasing".
- `SettingsPage.ets`: toggle row (title + original description) directly
  after `shape_detection`, matching `x22`'s item order.

## Strings

```json
auto_deselect_eraser             "Auto-deselect eraser"  / "自动取消选择橡皮擦"
auto_deselect_eraser_description "After erasing, the toolbox
  auto-switches back to your last used tool."
                                 / "擦除后，工具栏自动切换回上次使用的工具。"
```
