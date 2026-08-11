# ADR-0105: Preserve empty existing Text Blocks and compatibility editing

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `awb.o()` implements range replacement by first emitting `u5j.F(...)` for every
  selected character. It emits `s5j.i(...)` only when the replacement string length is greater than
  zero.
- An empty replacement therefore produces REMOVE_CHAR or REMOVE_CHARS and no insertion. The Text
  Block identity is not included in `u5j.k/l` DELETE_ENTITIES and remains present with empty
  RichText.
- A newly created empty Text is different: the CREATE flow needs a non-empty INSERT payload, whose
  original validator rejects an empty string. Cancelling that uncommitted editor remains correct.

## Decision

- Apply empty-string cancellation only when `editingOriginalTextBlock === null`, which identifies
  the uncommitted creation flow. Existing Text Blocks, including canonical original Blocks, may be
  committed with an empty body.
- Canonical `op:<timestamp>:<site>` Text identities continue through the strict CRDT preview. Empty
  after-text must materialize as visibility removal of all live character identities, with no
  insertion, and then persist through the existing type 9/10 writer.
- A canonical identity whose original state cannot be proven remains rejected. Do not downgrade it
  to a compatibility snapshot because that would hide protocol/state corruption.

## Compatibility Regression

- Phase 125 routed every existing Text through original preview. Older Harmony-created or imported
  compatibility Text uses opaque IDs and has no `original_block_state`, so those elements became
  uneditable.
- Existing Text whose ID cannot decode as an original operation identity now uses the prior plain
  `TextBlockTool.updateText()` and snapshot persistence path, including normal REPLACE_ELEMENT
  Undo/Redo. Its lack of original style authoring remains explicit; changed compatibility text may
  clear imported runs as before Phase 125.

## Verification And Boundary

- The ArkTS fixture proves `ABC -> ""` removes all three identities, inserts/revives none and
  materializes no residual style runs.
- `d02-empty-existing-text.mjs` locks original remove-before-conditional-insert evidence, new-empty
  cancellation, existing-empty CRDT routing, opaque compatibility editing and canonical preview
  protection. Full replay and clean HAP results are recorded in the Phase 128 report.
- This does not make opaque compatibility edits sync-compatible with original private operations;
  it restores local behavior without weakening canonical state validation.
