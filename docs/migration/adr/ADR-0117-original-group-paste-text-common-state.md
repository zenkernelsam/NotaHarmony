# ADR-0117: Preserve original Text common Block state in Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `baj.d()` encodes CREATE_BLOCK as a 21-field FlatBuffer. Text can carry corner,
  textWrap, enableCaption, paper, resizesWidthToFitText, margins and positionLocked in fields 1, 7,
  8, 15, 18, 19 and 20.
- `cie.u()` copies a Text Block by passing all of those effective registers to `baj.a()`. Its
  `vy7` margins contain four independent top, bottom, left and right values; the defaults are
  `(3,10,5,5)`, not symmetric vertical padding.
- `k3a` Paper uses nullable scalar fields. Explicit enum/index zero and explicit false booleans are
  different from absent fields and must remain present in the nested FlatBuffer vtable.

## Decision

- Encode every Text common field directly in type-22 CREATE_BLOCK. Validate original enum ranges,
  booleans, non-negative finite margins and Paper alpha/nullable-field rules before allocating any
  Group Paste operation.
- Extend `TextBlockElement` with optional right/bottom insets. Existing Harmony snapshots remain
  readable; original-backed snapshots are enriched from the authoritative `original_block_state`
  four-margin baseline on load, and the MODIFY_BLOCK path repairs missing legacy values before its
  state check.
- Preserve all four margins through CREATE_BLOCK reduction, Group Paste canonical materialization,
  RichText reducer clones and general Text clones. Rendering, width-to-fit, edit height and overlay
  padding use asymmetric right/bottom values, with symmetric fallback only for non-original legacy
  objects that have no authoritative state.
- Keep character and paragraph style runs gated. CREATE_BLOCK has no RichText style fields, so those
  require their original RichText operation sequence in a separate phase.

## Rejected Alternatives

- Encode only the already-modeled left/top margins: this changes original line wrapping and layout
  after copy, reload or first edit.
- Store common state only in the Harmony snapshot: peers and later original operations would observe
  a different CREATE baseline.
- Treat nullable Paper zero/false values as omitted defaults: this loses the original register's
  presence semantics.

## Verification

- `OriginalCreateTextPayloadEncoder.test.ets` round-trips every common field, including explicit
  Paper zero/false scalars and asymmetric margins, and rejects negative margins and translucent Paper.
- `d02-original-group-paste-text-common-state.mjs` locks the original 21-field evidence, vtable
  offsets, nested Paper representation, legacy recovery and asymmetric layout calculation.
- Full desktop replay passes with `TOTAL=126 FAILED=0`. After `hvigorw clean`, both `note@ohosTest`
  and `note@default` HAP builds succeed. No emulator, VM, device or Hypium is used.

## Remaining Boundary

Initial character/paragraph styles and Shape RichText still require original RichText operation
encoding and transactional replay. They remain explicitly rejected rather than silently flattened.
