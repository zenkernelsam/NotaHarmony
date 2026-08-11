# ADR-0050: NOTE_BUNDLE preserves content on final archived pages

## Status

Accepted, 2026-08-11. This corrects the archived-page boundary recorded in
ADR-0037 and the incomplete production claim in ADR-0041.

## Evidence

- Original `uae.java` exposes an `r29` NOTE_BUNDLE as one operation iterator.
  `gr7.java` decodes that bundle and passes it to the same model reducer.
- Original `zq9.java` maps `dm2` to `CREATE_INK`, `rl2` to `CREATE_BLOCK` and
  `s83` to `DELETE_ENTITIES` without defining snapshot-only child variants.
- Original `v69.java:1247-1262` consumes type-15 `dm2` through the normal Ink
  reducer, while `v69.java:1584-1615` consumes type-22 `rl2` through the normal
  TEXT/IMAGE/MATH block reducer. Final page visibility does not discard those
  child objects from the CRDT model.
- Harmony's standalone Ink and Block reducers already support
  `original_deleted_page_element`. The missing piece was the NOTE_BUNDLE
  bootstrap: it left every final tombstone as `visible=0,page_id=NULL`, so no
  archived target existed for either reducer.

## Decision

- Preflight all bundle content before writes as before. Collect page identities
  referenced by accepted CREATE_INK/CREATE_BLOCK targets and explicit
  MODIFY_INK/MODIFY_BLOCK page origins. A destination absent from bundle page
  history is deferred before any write.
- A final deleted page receives a deterministic `encodeOriginalPageStorageId`
  and an `original_deleted_page` container only when accepted content targets
  it. A tombstone with no content remains unbound and does not become a fake
  blank page.
- Insert the archived container before replaying content. Ink and Block then
  enter their existing standalone reducers, which own z-order, archived
  snapshots, revision advancement, search invalidation and exact retry.
- Apply SET_METADATA and child operations in vector order, then materialize the
  final page background to either `page_info` or `original_deleted_page`.
  A nullable page background therefore resolves against the winning note-level
  fallback without losing archived content.
- Idempotent bundle replay now expects exactly the set of content-bearing
  archives and verifies each stable page mapping. Missing, extra or mismatched
  archives remain identity conflicts and roll back the whole deferred bundle.

## Verification

- `d02-note-bundle-archived-content.mjs` covers a live page, an archived page
  containing Ink and Text Block, and an unbound empty tombstone in one model.
  It verifies deterministic page IDs, archived z-order, cross-page move,
  source/destination revisions, final background, restore, and injected full
  rollback.
- All desktop replays pass with `TOTAL=59 FAILED=0`.
- `note@default` and the actual `note@ohosTest` HAP both complete ArkTS
  compilation and packaging with `BUILD SUCCESSFUL`. No emulator, device or
  Hypium execution was performed.

## Remaining Boundary

Device acceptance must replay a real bundle containing a deleted page with
Ink, Text, IMAGE and MATH, then undelete it and compare content, background,
search, z-order and restart persistence with the original. Private authenticated
transport and server note/site creation remain separate D-02 work.
