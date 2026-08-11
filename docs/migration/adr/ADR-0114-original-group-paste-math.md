# ADR-0114: Preserve Math blocks in original Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `baj.d()` writes the 21-field `rl2` CREATE_BLOCK table. Math uses block type 2,
  field 13 for the required LaTeX string, field 14 for the required Color, and field 20 for the
  common `positionLocked` value.
- `rl2.a()` rejects a Math block unless both LaTeX and Color are present, and rejects those fields on
  non-Math blocks. Common page/origin, rotation, scale, size, corner, wrapping and caption fields are
  shared with Text and Image.
- The existing Harmony `OriginalCreateBlockOperationApplier` already materializes Math as a distinct
  block, preserves its two baseline values and common geometry, and participates in the shared page
  revision batch and Group layering.

## Decision

- Add a strict local Math CREATE_BLOCK encoder to the existing block encoder module. It writes the
  original field numbers and defaults, validates UTF-8 round-trip and the 1 MiB decoder limit, and
  accepts only finite, decomposable rotation/scale/translation matrices without shear or perspective.
- Preserve empty LaTeX as a present empty string. This is distinct from a missing field and matches
  the original validator and Math state fallback semantics.
- Group Paste preflight now counts Math as a leaf, verifies its type-22 payload, and admits it into the
  same bottom-up Group graph. Image remains explicitly rejected until its asset-reference and local
  file availability transaction is implemented.
- The paste transaction allocates one entity identity, applies Math CREATE_BLOCK through the production
  decoder/reducer in the shared revision batch, appends the upload-immediate operation, then creates
  Groups and one NCP1 history companion in the existing transaction.
- Rebuild the returned Math element from the decoded wire payload. This makes float32 geometry,
  snapshot bytes, original state tables, NCP1 and the live UI use one canonical value instead of the
  higher-precision clipboard preview.

## Rejected Alternatives

- Paste Math as Text: raw LaTeX is not the rendered formula object and would destroy its CRDT type.
- Add Math after committing Groups: that would violate the single atomic user action and leave Group
  membership referencing an entity that may not exist.
- Open Image at the same time: Image CREATE_BLOCK also mutates asset references and can require a local
  binary transfer; Math does not justify weakening those separate invariants.

## Verification

- ArkTS fixtures round-trip rotation, non-uniform scale, LaTeX, signed ARGB, corner, wrap, caption and
  lock through the production CREATE_BLOCK decoder, reject shear, accept a Math Group plan and continue
  rejecting Image.
- `d02-original-group-paste-math.mjs` locks original field evidence, encoder/reducer wiring, canonical
  UI result and all-or-nothing Math/Group/NCP1 behavior.
- Full desktop replay passes with `TOTAL=123 FAILED=0`. After `hvigorw clean`, both `note@ohosTest`
  and `note@default` HAP builds succeed. No emulator, VM, device or Hypium is used.

## Remaining Boundary

Image CREATE_BLOCK, Styled and empty Text, and Shape RichText remain explicit Group Paste gates. Math
pixel rendering still has the engine limitation recorded by ADR-0036; this phase preserves the original
data object and does not claim to solve that separate renderer dependency.
