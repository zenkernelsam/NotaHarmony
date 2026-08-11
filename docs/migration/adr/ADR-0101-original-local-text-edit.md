# ADR-0101: Persist original edits to existing Text Blocks

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `s5j.i()` selects type 7 `INSERT_CHAR` for exactly one Unicode code point and
  type 8 `INSERT_STRING` otherwise. Both carry a nullable character location and the target Text
  Block identity.
- `u5j.F()` resolves the removed range to character sequence identities, uses type 9
  `REMOVE_CHAR` for one identity and type 10 `REMOVE_CHARS` for several. `u5j.G()` writes type 11
  `REVIVE_CHARS` for Undo/Redo visibility restoration.
- `tej/pub` encode one inline character identity plus Text Block; `vej/qub/f2c` encode a non-empty
  vector of 12-byte character identities plus Text Block. Visibility is an LWW register on the
  existing character identity, not physical deletion or reinsertion.
- Text auto-size is the type-19 `MODIFY_BLOCK` field-6 size register. Width and height are float32
  values and belong to the same user edit transaction.

## Decision

- Classify only one byte-exact existing Text payload change with stable element/Block identity,
  canonical live original state and matching CRDT character materialization. Until local style
  writers exist, both before and after character/paragraph style runs must be empty.
- Derive one contiguous replacement from the longest common Unicode-scalar prefix and suffix.
  Remove old identities with type 9/10. Insert one scalar with type 7 and several with type 8,
  anchored to the visible character immediately before the replacement or to root.
- Before inserting, search hidden characters for a set whose revival materializes the exact target
  text. Undo/Redo therefore removes the current replacement and emits type 11 for the prior
  identities instead of creating duplicate identities.
- Encode changed Text size through type-19 field 6 only when the editor snapshot is exactly
  reproducible after float32 conversion. Otherwise reject the original classification and retain
  the compatibility persistence path rather than commit a divergent original operation.

## Revision, History And Atomicity

- REMOVE, REVIVE/INSERT and optional size use separate original operation identities and
  upload-immediate journals, but share one `OriginalPageMutationBatch`. Every row materializes the
  final `N+1` snapshot and the page advances exactly once.
- `ORIGINAL_TEXT_VISIBILITY` and `ORIGINAL_INSERT_TEXT` are transparent persistent-history
  companions. The canonical page mutation remains one user action; grouped Undo/Redo re-enters the
  same strict classifier and preserves character identities.
- Reducers, journals, revision flush, final reducer-state comparison, snapshot/search
  reconciliation and history companion execute inside the existing page-save transaction. Any
  malformed state, deferred reducer or injected failure rolls back all character, Block, journal
  and revision changes.

## Verification And Boundary

- `OriginalTextMutationPayloadEncoder.test.ets` covers type 7/8 selection, type 9/10/11 payloads,
  Unicode scalars, size field 6 and identity-preserving replacement Undo/Redo planning.
- `d02-local-text-edit.mjs` locks the original writers and production wiring, then replays replace,
  supplementary-plane insertion, optional size, one revision, revive-based Undo/Redo and atomic
  failure rollback in SQLite.
- This ADR closes unstyled existing Text character edits. Styled Text authoring, character and
  paragraph style writers, full original layout behavior, IMAGE captions, clipboard/package
  preservation, authenticated transport/ACK and device acceptance remain separate work.
