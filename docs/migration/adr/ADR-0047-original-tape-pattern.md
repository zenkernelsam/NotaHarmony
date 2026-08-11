# ADR-0047: Restore original Tape pattern state and bounded tile renderer

## Status

Accepted, 2026-08-11.

## Evidence

- Original `ife.java` fixes the wire order as STRIPES=0, GRID=1, DOTS=2,
  PLAIN=3, STARS=4, FLOWERS=5, HEARTS=6, WAVES=7 and CHECKERS=8.
- Original `i16.java:154-162` defaults a Tape CREATE without field 6 to
  STRIPES. Non-Tape Ink does not acquire Tape state merely because the enum's
  FlatBuffer default is zero.
- Original `q06.java` applies MODIFY_INK field 16 as its own LWW register.
  Its winner is independent from style, color, width and Ink effects.
- Original `i16.java:175,228` supplies white pattern color in normal mode and
  the Tape body color as the FLOWERS center color. `y4g`/`c5g` draw ordinary
  Ink first and then overlay the Tape pattern.
- Original `qfe.java` renders a finite cell bitmap, caches 32 variants and
  fills the final Ink path with a repeated BitmapShader. Logical cell sizes
  are 11.313708 square, 8 square, 8x16, 30x13, 28x14, 26x13, 6x8 and 12
  square. Its zoom bucket changes raster density only and is clamped to at
  most 8 pixels per logical unit.

## Decision

- `RenderSpec.tapePattern` is optional: presence identifies original Tape;
  absence remains ordinary Ink. Database v49 adds the CREATE baseline and an
  independent value/winner/presence register with enum and consistency checks.
  Migrated rows remain non-Tape.
- CREATE_INK accepts tool 3, decodes field 6 with original enum normalization,
  defaults a missing field to STRIPES and rejects a Tape field on non-Tape
  tools. Exact retry compares the immutable CREATE baseline while validating
  the materialized payload against the latest MODIFY winner.
- MODIFY_INK field 16 uses the existing timestamp/site LWW ordering. Stale
  operations are no-ops; equal identity with another value is a conflict.
  Applying it to non-Tape Ink defers. Tape plus nonzero Ink effects also
  defers, matching CREATE's tool/effect boundary.
- Standalone, NOTE_BUNDLE and hidden-entity paths share the same reducer and
  transaction. Package validation, persistence JSON, clipboard copies and
  editor Undo/history snapshots retain the optional enum.
- The renderer first draws ordinary Ink, then fills its final custom path or
  generated width outline with the original repeated cell. Each tile is
  rasterized at the original maximum density, transformed back to logical
  dimensions with `CanvasPattern.setTransform()`, and held in a 32-entry LRU.
  Eviction and renderer disposal close ImageBitmaps. Work is bounded by one
  finite tile plus one outline fill, regardless of page-coordinate magnitude.
- PLAIN intentionally produces no overlay. FLOWERS uses the body color only
  for its centers; all other pattern geometry uses the overlay color.

## Verification

- `d02-original-tape.mjs` covers v48-to-v49 defaults, CREATE default,
  independent LWW stale/site-tie behavior, rollback, all nine patterns,
  bounded repeat-cache guards and propagation through model/copy/render paths.
- `RendererStyle.test.ets` compiles pixel assertions for all patterned enums,
  PLAIN, clipping, FLOWERS two-color output and final custom-path clipping.
- All Node/SQLite replays pass: `TOTAL=56 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` assembleHap
  builds succeed. Device Hypium and pixel comparison were not executed.

## Remaining boundary

The original dim/inversion state changes the overlay from white to black. The
current Harmony renderer has no equivalent global Ink dim-state path, and its
completed-stroke bitmap must be rebuilt when that state changes. This is kept
as one renderer-cache fidelity batch rather than changing Tape alone and
leaving cached Ink inconsistent. Real original fixtures must still verify all
nine patterns at multiple zooms, custom paths, thumbnails, restart and v48-to-
v49 device migration. PDF background, authenticated transport, incoming
content replay and server note/site creation remain separate D-02 work.
