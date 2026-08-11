# ADR-0084: Batch local original Ink visibility mutations

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `s83` is DELETE_ENTITIES payload type 25. Its fields 0 and 1 are vectors of
  inline 8-byte `qo5` operation identities, exposed as entityDeletes and entityUndeletes.
- `fsi.d(List, List, List, List)` writes the complete delete and undelete lists into one FlatBuffer.
  `u5j.k/l` forward those lists without splitting them into per-entity operations.
- The whole-erase path in `lg2` converts the erased entity `Set` to one `List` and passes that list
  once to `fsi.d`; selection deletion follows the same batch model.

## Decision

- Recognize a local snapshot mutation as original entity visibility when the smaller ordered
  snapshot is an exact subsequence of the larger snapshot and every removed/restored item is a
  Stroke with a canonical `op:<timestamp>:<site>` identity. Payload changes, reorder, non-Ink
  elements, equal-size replacements and more than 10,000 targets are rejected.
- Encode all identities in one entityDeletes or entityUndeletes vector. Allocate one operation
  identity, run the existing original reducer, append one upload-immediate DELETE_ENTITIES row,
  reconcile the materialized page, and append the Harmony history companion in the same mutex and
  SQLite transaction.
- Accept both locally authored and imported/remote original Ink. `originalCreate` is local
  CREATE_INK authoring metadata, not proof that an original entity exists. Canonical identity is
  the local classifier; the reducer remains authoritative for entity existence, page binding,
  visibility winner and complete z-order.
- Rearm CREATE_INK authoring after whole erase, pure Ink selection delete, and their single or
  coalesced Undo/Redo only when every target is canonical original Ink. Partial erase, modified
  surviving paths, and mixed shape/text/image/math deletion continue to persist the v59 guard.
- Do not queue persistence or alter in-memory eligibility when an eraser path hits nothing or stale
  selection IDs remove nothing. A no-op has no original mutation and must not disable later Ink.
- A batch advances the affected page revision once, matching the original reducer's affected-page
  set behavior. Any defer, identity mismatch, append failure or companion failure rolls back all
  entity archives, winners, revision changes and operation rows.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` round-trips three deletes and two undeletes.
- `d02-local-batch-ink-visibility.mjs` locks the original list writer/call site, production batch
  wiring, one-revision behavior, Undo restoration, conservative guard and transaction rollback.
- Full replay and clean sequential HAP results are recorded in the Phase 107 report.

## Remaining Boundary

Partial erase still requires original MODIFY_INK/path semantics. ADD_PATH_ELEMENTS streaming,
transform/style MODIFY_INK, original text/shape/image/math authoring, transport ACK acceptance and
device visual/input verification remain later work. No emulator, VM or device was started.

## Phase 110 Correction

The Phase 107 batch vector and classifier were correct, but the local reducer received the
DELETE_ENTITIES child table instead of a complete operation envelope. Phase 110 supplies and
journals the complete `uq9`; only from that phase is the described batch production transaction
runnable. Existing identity, batching, revision and rollback decisions are unchanged.
