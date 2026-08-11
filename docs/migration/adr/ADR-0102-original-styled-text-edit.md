# ADR-0102: Preserve original RichText styles during local character edits

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `m4c` materializes character formatting with stable `SeqId` boundaries. Range
  endpoints explicitly use `BEFORE`, `AFTER` and `END_OF_DOC`; `x01/ra` additionally define
  `START_OF_DOC`. These boundaries are not equivalent to mutable string offsets.
- Original character operations remain the Phase 124 type 7/8/9/10/11 sequence mutations.
  Existing type 12/13/14 style operations and type 15 checkbox registers continue to refer to
  character identities even when those characters become hidden.
- Original sequence sibling order compares timestamps with Java signed-int semantics. A guessed
  high timestamp can therefore move an insertion to the opposite side of a boundary after
  `0x7fffffff`; preview must use the identity that the local operation clock will allocate.

## Decision

- Simulate the Phase 124 remove/revive/insert plan on a cloned complete character tree, including
  hidden identities, then rematerialize character and paragraph runs through the existing original
  style authority. Offset shifting is not permitted.
- Predict the insertion identity from `note_sync_metadata.max_op_timestamp/editor_site_id`, adding
  one timestamp for each preceding non-empty REMOVE and REVIVE batch. Clock exhaustion or malformed
  metadata rejects the preview.
- `StrokePersistence.previewOriginalTextEdit()` flushes earlier page saves and executes under the
  editor persistence mutex. It requires a byte-exact current Text snapshot, a live original Block,
  matching CRDT text, matching materialized before-runs and valid style/checkbox state. It performs
  no durable write.
- The save classifier repeats the same checks inside the transaction and requires its previewed
  final runs to equal the queued snapshot byte-for-byte. Production reducers and the final complete
  snapshot comparison remain authoritative.

## Editor And Lifecycle

- `TextBlockTool.updateText()` accepts both exact run collections as one paired argument and deep
  clones them. The non-original plain-text path still has no span authoring UI and may clear runs;
  an original edit never takes that fallback after preview failure.
- Existing original Text commit waits for the persistence preview before replacing the element or
  pushing history. Failure leaves the editor state untouched. Page flush reports failure rather
  than navigating away as if the draft had committed.
- Duplicate commits are blocked while preview is in flight. Component disappearance keeps render
  resources alive until the final asynchronous commit settles, while normal callbacks observe and
  log rejected promises.

## Verification And Boundary

- ArkTS fixtures cover insertion inside a style range, exact `BEFORE`/`AFTER` behavior,
  `START_OF_DOC`/`END_OF_DOC`, deletion across hidden boundaries, identity-preserving revive,
  paragraph checkbox attachment, operation-clock offset/exhaustion and detached run ownership.
- `d02-local-styled-text-edit.mjs` replays styled insert/delete/revive, paragraph checkbox state,
  one-revision commits and transaction rollback, and locks the production UI/persistence wiring.
- This phase preserves existing original character/paragraph styles during character edits. It
  does not emit type 12/13/14 from a local formatting surface and does not claim full RichText
  authoring, layout parity or device acceptance.
