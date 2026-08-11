# ADR-0104: Preserve non-empty whitespace RichText commits

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `f46.a()` rejects INSERT_STRING only when `k().length() == 0`, with the explicit
  error `Cannot insert empty string`. It does not trim the value.
- `s5j.i()` selects the single-code-point INSERT payload when the Java string contains one Unicode
  scalar and otherwise delegates the unchanged string to `kci.b()` for INSERT_STRING. A space,
  newline, non-breaking space or ideographic space is therefore ordinary RichText content.
- Existing Phase 124/125 reducers already operate on Unicode scalars and can persist those values;
  the divergence was solely the editor's early `text.trim().length === 0` cancellation gate.

## Decision

- Cancel a Text commit only when `text.length === 0`. Preserve every non-empty string byte-for-byte,
  including whitespace-only content, for both initial local Text creation and edits to an existing
  original Text Block.
- Do not infer the lifecycle of a genuinely empty existing Block. The empty string retains the
  current cancellation behavior until original UI evidence proves whether blur deletes the Block
  through type 25 or preserves an empty container.

## Commit Failure Semantics

- `TextBlockOverlay.onCommit` returns `Promise<boolean>`. The Done handler clears its local draft
  only after a successful commit.
- `NoteCanvasView` forwards the real `onTextCommit()` result and converts an exception into `false`
  after logging it. CRDT preview rejection, page-generation races and persistence errors therefore
  leave the visible draft available for retry or cancellation.
- Cancel remains an explicit destructive editor action and may clear its local draft immediately.

## Verification And Boundary

- `d02-text-whitespace-commit.mjs` locks the original empty-only validation, production no-trim
  gate, space/tab/newline/NBSP/ideographic-space acceptance and success-only draft clearing.
- Full replay and clean sequential HAP results are recorded in the Phase 127 report.
- This phase does not add a formatting surface, alter search folding of whitespace-only documents,
  or decide empty-Block deletion semantics.

## Phase 128 Correction

Original `awb` replacement evidence subsequently proved the existing-Block case: replacing the
whole range with an empty string emits REMOVE_CHAR(S), skips insertion and preserves the Block.
Phase 128 therefore narrows this ADR's empty-string cancellation rule to newly created Text only.
