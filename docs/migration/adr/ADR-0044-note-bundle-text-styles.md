# ADR-0044: NOTE_BUNDLE reuses the standalone RichText style reducer

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java:25-27` maps `me8`,
  `he8` and `io1` to `MODIFY_STYLE`, `MODIFY_PARAGRAPH_STYLE` and
  `CLEAR_STYLE`.
- Original `me8`, `he8` and `io1` define the same character boundaries,
  paragraph SeqId ranges, nullable setter wrappers, Text block identity and
  clear-style scope already consumed by the standalone reducer.
- The standalone reducer persists each child operation, folds operations by
  unsigned operation identity, keeps boundaries stable across later character
  insertion, and rematerializes live or archived Text style runs.

## Decision

- Expose `decodeOriginalRichTextStyleTable()`, `preflightTable()` and
  `applyTable()`. Both standalone and NOTE_BUNDLE paths decode nested type
  12-14 tables and enter the same reducer.
- Preflight all nested style tables before bundle writes and apply them in
  operation-vector order inside the inbox transaction. A style child may
  therefore target characters and a Text block created by preceding children
  in the same bundle. Runtime target, boundary or materialized-state divergence
  rolls back the complete bundle.
- Treat `(noteId, child timestamp, child site)` as one immutable style operation
  identity. An exact retry must match the Text block, character/paragraph and
  clear flags, both boundaries and every nullable style attribute. Exact retry
  is a no-op; any difference, including reuse in another Text block, is an
  identity conflict.
- Preserve recognized operations even when their current materialized style is
  unchanged, because a later character insertion can enter their stable range.
  Such an operation is persisted without incrementing the page revision.
  Original code-only/unrecognized payloads remain the documented skip path,
  but cannot reuse an identity already owned by a persisted recognized style.

## Verification

- The ArkTS NOTE_BUNDLE fixture appends nested MODIFY_STYLE,
  MODIFY_PARAGRAPH_STYLE and CLEAR_STYLE after CREATE_BLOCK and INSERT_STRING.
  It verifies `(80,8,index)` boundaries, `(60,6)` Text identity, character and
  paragraph attributes, clear scope and table-level preflight.
- `d02-note-bundle-text-styles.mjs` covers all three types, three visible
  revisions, exact retry, changed-attribute and cross-Block conflicts, a
  no-effect operation that remains persisted, unrecognized skip, archived
  Text, malformed zero-write, runtime-deferred rollback and injected complete
  rollback.
- All Node/SQLite replays pass: `TOTAL=53 FAILED=0`.
- After `hvigor clean`, both `note@default` and `note@ohosTest` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

NOTE_BUNDLE Text character and style payloads are now connected. Delete-before-
create and hidden-entity modification, Tape/effects, PDF background, private
authentication transport and server-side note/site creation remain separate
work; D-02 is not closed.
