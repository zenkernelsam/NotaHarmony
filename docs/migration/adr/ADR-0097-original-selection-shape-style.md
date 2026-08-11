# ADR-0097: Persist and render selected Shape style

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `u5j.x` accepts an optional `t16` InkStyle for existing Shapes and delegates to
  `a1j.a`; `a1j` writes that value at field 8 of the 17-field `le8` MODIFY_SHAPE payload.
- `le8.a()` rejects `VARIABLE_WIDTH` with `Shapes cannot use variable width ink`. FIXED_WIDTH,
  DASH and DOTS remain valid Shape styles. This is the same invariant enforced by CREATE_SHAPE.
- The already recovered original fixed-width renderer uses dash lengths `2w/1w`, dot lengths
  `0.001w/2w`, BUTT caps for DASH, ROUND caps for DOTS and MITER joins for DOTS.

## Decision

- Extend the strict type-19 render-register encoder with optional field 8 style. Only integer styles
  1 through 3 are accepted; style 0 is rejected before a canonical operation can be selected.
- The Shape render classifier treats `originalStyle` as a writable register. It compares each target's
  current resolved state with the before-style, not the requested after-style, then batches by the
  complete final style/color/width/fill tuple. This preserves forward and reverse Undo preconditions.
- Selection FIXED/DASH/DOTS commands update both Ink and Shape in one existing history action. TAPER
  continues to update eligible Ink only. A selection containing Shape or Pencil disables the TAPER
  button so an invalid Shape command cannot appear to succeed.
- `ShapeCanvasRenderer` applies the proven fixed-width DASH/DOTS spacing and cap/join behavior.
  Missing legacy style renders as fixed width and every draw explicitly resets the dash array.

## Atomicity And Compatibility

- Type-17 Ink and type-19 Shape batches still share one transaction, one page revision batch and one
  Harmony history companion. Reducer, journal, snapshot reconciliation or history failure rolls back
  the whole mixed selection command.
- Every Shape target must exist in `original_shape_state`; production preflight checks tool and the
  current before-style against `resolved_payload`. Local lookalike IDs and stale Undo sources fall
  back to compatibility persistence rather than emitting a false original operation.

## Verification

- ArkTS payload fixtures round-trip type-19 field 8 and reject style 0. Classifier fixtures verify
  forward expected-style 1 -> DASH 2 and reverse expected-style 2 -> FIXED 1.
- Renderer fixtures exercise DASH and DOTS pixel gaps with the same width ratios used by Ink.
- `d02-local-modify-shape-style.mjs` locks original evidence, selection/UI wiring, state preflight,
  renderer behavior, history and rollback. Full replay and clean build results are in Phase 120.
- No emulator, VM, device or Hypium is used.

## Remaining Boundary

Shape tool/tape/effects/lock/definition-specific authoring, local Group authoring, full original CRDT
package round-trip, private authenticated upload/ACK and device acceptance remain subsequent Goal work.
