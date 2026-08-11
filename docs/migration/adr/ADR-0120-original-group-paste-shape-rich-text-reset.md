# ADR-0120: Reset Shape-owned RichText during original Group Paste

## Status

Accepted, 2026-08-12.

## Evidence

- Original 1.0.3 `cie.u()` creates a Text Block, sets it as the RichText target, calls `m4c.u()` and
  then clears the target. That explicit call emits the copied text and style operations.
- Original `n5d.u()` creates a Shape through `laj.a()` and immediately returns it. The method never
  reads `this.s`, never calls `m4c.u()` and therefore emits no type 7-14 RichText operations.
- `rbb.k()` materializes every CREATE_SHAPE with `new m4c(null)`. A pasted Shape consequently owns
  valid but empty RichText, irrespective of the source Shape's hidden RichText state.
- Shape RichText remains real inbound CRDT state under ADR-0061. Its absence from copy production is
  an original behavior, not evidence that the state should be removed from the model.

## Decision

- Admit a Shape with non-empty RichText or style runs into original Group Paste preflight.
- Clone the source, then set `richText` to an empty string and both style-run arrays to empty before
  validating or emitting CREATE_SHAPE. Do not mutate the clipboard source.
- Use the same reset helper in preflight and transaction production. Return the reset Shape to the
  editor/history so the in-memory result agrees with the reducer's CREATE_SHAPE snapshot.
- Do not emit INSERT/REMOVE/style operations for the new Shape and do not reject the whole Group.

## Rejected Alternatives

- Preserve Shape RichText through type 7-14: this would invent operations absent from `n5d.u()` and
  produce state the original pasted Shape does not have.
- Keep the existing rejection gate: the original copies the Shape successfully, so rejecting the
  complete Group is observably stricter.
- Clear only the returned UI object: preflight and durable production must share one canonical input
  or failures and snapshots can diverge.

## Verification

- `d02-original-group-paste-shape-rich-text-reset.mjs` compares `cie.u()`, `n5d.u()` and `rbb.k()`,
  locks the absence of Shape text-copy operations and checks the production reset path.
- `StrokePersistence.test.ets` covers non-empty text plus character/paragraph runs, verifies the
  reset result and source immutability, and admits that Shape through full Group Paste validation.
- Full replay and clean HAP results are recorded in the Phase 143 report. No device is used.

## Remaining Boundary

This decision only covers original clipboard production. Inbound Shape RichText replay, package
round-trip and search remain preserved by ADR-0061, while ADR-0064 keeps the state non-visual for the
1.0.3 consumer. Non-similarity Shape transforms remain an independent CREATE_SHAPE limitation.
