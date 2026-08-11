# ADR-0123: Render original vector checkbox markers

## Status

Accepted, 2026-08-12.

## Evidence

- Original `jo3.a()` calls Compose `DrawScope.drawCircle` through `no3.c0()/p()`. The marker is a
  circle, not a square checkbox glyph.
- Unchecked uses text color at 0.75 alpha, radius `r` and a one-unit stroke. Checked uses a filled
  circle of radius `r + 0.5`.
- The checked path is a closed six-segment polygon expressed in fifteenths of the marker diameter.
  Its fill is black when marker luminance exceeds 0.7 and white otherwise (`iu1.b/iu1.e`).
- Original `zoe.b()` reserves `1.6 * fontSize` for CHECK_BOX, while `zoe.c()` advances each indent
  level by `36/14 * fontSize`. A platform Unicode glyph has neither stable geometry nor stable
  advance and therefore cannot support original rendering or exact hit testing.

## Decision

- Stop emitting U+2610/U+2611. Reserve the original fixed checkbox column in natural-width,
  wrapping, alignment and drawing calculations.
- Draw the unchecked ring and checked fill/check path directly through the existing Canvas context.
  Preserve source ARGB alpha; multiply only the unchecked ring by 0.75.
- Use the same radius and center helpers for vector drawing and `TextCheckboxMarker` hit geometry.
- Replace the approximate 1.5-font indent step with the original `36/14` scale for paragraph
  layout, marker placement and available wrap width.

## Rejected Alternatives

- Choose a closer Unicode or icon-font glyph: platform font fallback still changes its shape,
  baseline and advance.
- Keep glyph drawing but use vector hit geometry: the visible target and interactive target would
  continue to disagree.
- Rasterize an icon asset: the original marker is parameterized by line height and text color, and
  vector drawing preserves that behavior without scale-specific assets.

## Verification

- `RendererStyle.test.ets` checks an empty unchecked center, filled checked center and contrasting
  white check pixels for a black marker.
- `d02-checkbox-marker-render.mjs` locks the original circle, alpha, check coordinates, contrast,
  fixed column and indent evidence and rejects reintroduction of platform glyphs.
- Full replay and clean HAP results are recorded in the Phase 146 report. No device is used.

## Remaining Boundary

Device acceptance still needs pixel comparison at multiple fonts, zoom levels and dark/light text
colors. The active `TextArea` rich-marker limitation remains as described in ADR-0122.
