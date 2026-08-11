# ADR-0122: Share checkbox marker layout between rendering and local interaction

## Status

Accepted, 2026-08-12.

## Evidence

- Original `yqa.d()` walks unique laid-out paragraphs, accepts only `CHECK_BOX`, obtains the marker
  geometry from the same `jo3.c()` helper used by drawing and accepts a touch whose distance from
  the marker center is less than `radius * 1.5`.
- `jo3.c()` derives the checkbox radius from the paragraph's natural line height: half the height
  minus one unit, bounded below by one quarter of the height. Alignment and indentation are already
  reflected in the cached paragraph geometry.
- The original touch routes in `htd` and `ww2` run this marker test before normal caret/selection
  handling and call `fm7.n(codePointIndex)` on success.
- Harmony previously rendered a Unicode checkbox prefix but exposed only a plain `TextArea` editing
  overlay. There was no marker hit path. Its wrapping helper also lacked line starts, so a wrapped
  continuation could repeat a decorator and a hard wrap could skip its first character.

## Decision

- Replace the renderer's end-only wrapping output with `TextLayoutLine { start, end,
  paragraphStart }`. Rendering draws a decorator only on the first visual line of a real paragraph;
  hard wraps retain their first character and continuation lines retain the paragraph style without
  gaining another marker.
- Expose renderer-owned checkbox marker geometry. Marker centers use the exact aligned/indented
  marker column; radius follows the original natural-line-height formula. ADR-0123 subsequently
  makes vector drawing consume that same center instead of a platform glyph.
- Convert canvas points through the full inverse Text transform and apply the original strict
  `radius * 1.5` distance test. Singular transforms are not interactive.
- In DEFAULT mode, test the topmost unlocked Text block marker before recording a normal double tap.
  A hit calls `toggleOriginalCheckboxAt()`, records one `REPLACE_ELEMENT`, refreshes history and
  rendering, and enters the normal save pipeline. Original-aligned pages therefore use the Phase
  144 type-28 writer; non-original pages retain the normal snapshot behavior.

## Rejected Alternatives

- Use the entire text-block bounds as the checkbox hit area: the original tests marker geometry,
  and a broad target would toggle while the user is trying to place a caret.
- Reimplement marker layout in `NoteCanvasView`: alignment, indentation, font metrics and wrapping
  would drift from rendering.
- Add invisible hit rectangles to `TextBlockOverlay`: the current plain `TextArea` does not render
  rich paragraph prefixes or maintain their offsets, so invisible controls would not correspond to
  what the user sees.
- Toggle paragraph runs without history/persistence: that bypasses Undo/Redo and the dedicated
  original checkbox register.

## Verification

- `RendererStyle.test.ets` locks two paragraph markers despite a wrapped first paragraph, full
  rotate/translate inverse mapping and the strict 1.5-radius outside boundary.
- `d02-checkbox-marker-hit.mjs` locks the original geometry/call chain and the Harmony shared-layout,
  UI, history and persistence wiring.
- Full replay and clean HAP results are recorded in the Phase 145 report. No device is used.

## Remaining Boundary

The durable single-tap canvas workflow is complete. The active editor remains a platform
`TextArea`, which cannot present per-paragraph rich markers at matching glyph offsets. Adding
controls over that approximation would reduce fidelity; an active-draft checkbox interaction must
wait for a rich editor overlay that consumes the same layout model and can merge text and style
mutations atomically.
