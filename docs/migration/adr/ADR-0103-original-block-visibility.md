# ADR-0103: Persist original Block visibility through DELETE_ENTITIES

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `u5j.k/l` forwards entity delete and undelete lists to
  `fsi.d(List, List, List, List)`. The resulting `s83` payload has entity and page vectors, but no
  discriminator limiting entity visibility to Ink or Shape.
- `zq9` maps `s83` to payload type 25 `DELETE_ENTITIES`. Text, Image and Math are Blocks with the
  same immutable CREATE operation identity used by the entity vector.
- A new Text is created as an empty type-22 Block followed by RichText operations. Undoing that
  user command must hide the Block identity; redoing it must undelete the same identity rather than
  create a replacement Block.

## Decision

- Extend local entity-visibility classification from Stroke/Shape to all five materialized page
  kinds: Stroke, Text, Shape, Image and Math. A single ordered snapshot delta may contain any mix of
  those kinds and is encoded as one type-25 vector.
- Decode every snapshot payload before accepting it. Its persisted union kind and embedded data ID
  must match the snapshot row kind and element ID exactly.
- Preflight the real authoritative child state. Stroke requires `original_ink_state`, Shape requires
  `original_shape_state`, and Text/Image/Math require `original_block_state` with the matching
  `OriginalBlockType`. Every child is joined through the same `original_element_z_index` identity
  and expected page-element kind.
- Keep the original reducer authoritative for visibility winners, archives and z-order. Journal one
  upload-immediate operation and advance each affected page once. Reducer output must match both the
  requested identity order and every requested payload byte before snapshot/history reconciliation.

## Editor And History

- Whole-object erasing and selection deletion may preserve original eligibility for canonical
  Text/Image/Math together with Ink/Shape. Partial Ink erasure remains ineligible because it is not
  an entity visibility operation.
- Persistent Undo/Redo classification accepts Block-bearing `ERASE_ELEMENTS` and
  `DELETE_ELEMENTS`, Text `DELETE_ELEMENT`, and the `ADD_ELEMENT` action emitted by a newly created
  original Text. The existing method name remains unchanged to avoid unrelated history churn, but
  its semantic domain is now original page entities.
- Any missing/mismatched child state, kind, Block type, identity, reducer payload or order rejects
  the optimized path. The surrounding transaction then rolls back instead of allowing a damaged
  history snapshot to overwrite canonical materialization.

## Verification And Boundary

- `d02-local-block-visibility.mjs` replays one mixed Stroke/Shape/Text/Image/Math type-25 batch,
  delete and undelete, one-revision commits, immediate journal rows, Block type checks, payload
  mismatch rejection, new-Text Undo/Redo wiring and transaction rollback.
- The earlier CREATE_SHAPE replay now asserts the five-kind whole-eraser invariant instead of the
  obsolete Block exclusion. Full replay and clean sequential HAP results are recorded in the Phase
  126 report.
- This decision does not guess empty-editor lifecycle semantics. Whitespace is valid RichText;
  whether a truly empty existing Text editor deletes the Block or preserves an empty container
  remains subject to separate original UI evidence.
