# ADR-0113: Preserve Shape fill and lock in original Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `laj.m()` serializes the 18-field `ao2` CREATE_SHAPE table. It writes an optional
  Color at field 11 and writes `positionLocked` at field 15 with the FlatBuffer default `false`.
- `ao2.a()` accepts an absent fill for an unfilled Shape but rejects a present Color whose alpha is
  zero: `fillColor: nil` is the only valid representation of no fill.
- The original Shape state (`n5d`) retains fill and position lock as independent registers. Group
  Paste therefore has to copy their resolved values into the new CREATE_SHAPE rather than dropping
  them or reconstructing them later with unrelated operations.

## Decision

- Extend the existing strict type-18 encoder instead of introducing another payload path. Field 11
  uses the same inline BGRA Color layout as field 9; field 15 is emitted only for `true`, preserving
  the original default for false and legacy snapshots where the optional Harmony property is absent.
- Increase the root object from 80 to 84 bytes so the field-15 byte is part of the table. Keep the
  existing field-14 force slot at offset 76 and use offsets 56 and 80 for fill and lock respectively.
- Accept signed or unsigned 32-bit ARGB fill values only when alpha is non-zero. Continue rejecting
  Shape RichText, unsupported definitions/transforms, variable-width style and all other states that
  cannot yet be represented exactly by the production CREATE path.
- Reuse the production CREATE_SHAPE decoder in tests. A filled and locked Shape must round-trip with
  its exact ARGB value and lock bit, while a zero-alpha fill must fail before persistence begins.

## Rejected Alternatives

- Strip fill or lock during Group Paste: that changes visible content and selection behavior and is
  not equivalent to the original copy operation.
- Emit CREATE_SHAPE followed by MODIFY_SHAPE: the initial entity would temporarily have the wrong
  state and would add operations that original `laj.m()` can already represent atomically.
- Treat transparent fill as unfilled: original `ao2` explicitly rejects that encoding; silently
  normalizing it would hide corrupt or semantically ambiguous state.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` round-trips field 11 and field 15 through the production
  decoder and asserts transparent-fill rejection.
- `d02-original-group-paste-shape-state.mjs` locks the original writer/validator evidence, encoder and
  decoder offsets, Group Paste production call, RichText gate and fixture coverage.
- Full desktop replay passes with `TOTAL=122 FAILED=0`. After `hvigorw clean`, both `note@ohosTest`
  and `note@default` HAP builds succeed. No emulator, VM, device or Hypium is used.

## Remaining Boundary

Shape RichText still requires original text operation production and remains explicitly rejected.
Image/Math CREATE_BLOCK, Styled or empty Text creation, and non-similarity Shape transforms also
remain outside the current Group Paste production capability.
