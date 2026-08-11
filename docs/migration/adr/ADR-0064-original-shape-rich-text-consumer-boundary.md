# ADR-0064: Keep Shape RichText non-visual in the 1.0.3 consumer

## Status

Accepted, 2026-08-11. This corrects the visible-consumer boundary stated by ADR-0061 and the
Phase 83 report; it does not change ADR-0061's inbound CRDT decision.

## Evidence

- Original 1.0.3 `itd.a()` builds static text states by adding the note-level text field and then
  iterating `a79.I`, the Block map. It does not enumerate `a79.G`, the Shape map.
- `z5c.y()` resolves either the note-level RichText or a `cie` Text Block and returns its
  `RichTextFieldData`. It has no Shape branch.
- The original tile/selection content path in `kkf` handles `m4d`/`n5d` Shapes by producing an
  `lqc` from the Shape path, transform, fill path and border width. It does not submit `n5d.s` to
  the text layout renderer.
- `fu1` similarly uses the Shape geometry path and border width for hit testing. Shape RichText is
  still valid model state: `n5d` owns `m4c`, and `m5d` routes text operations to it.

## Decision

- Preserve Shape RichText through inbound replay, persistence, search, copy and package paths as
  decided by ADR-0061.
- Do not draw it, create a caret/editor for it, or expand Shape hit bounds from it when targeting
  original Android 1.0.3 behavior.
- Treat visible Shape text as a non-goal unless a different original version or runtime capture
  proves a consumer that is absent from the 1.0.3 decompilation.

## Verification

- `d02-shape-rich-text-consumer-boundary.mjs` locks the current production split: Shape rendering
  remains geometry-only in the main canvas and thumbnail, while `Canvas2DTextRenderer` accepts
  `TextBlockElement` and ADR-0061's Shape CRDT reducer remains present.
- No device claim is made. The decision is based on direct 1.0.3 code paths and prevents an
  unsupported UI addition rather than substituting for pixel verification.

