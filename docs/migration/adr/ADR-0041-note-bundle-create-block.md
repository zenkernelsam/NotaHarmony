# ADR-0041: NOTE_BUNDLE CREATE_BLOCK reuses the standalone reducer

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java:35` maps the `rl2`
  payload table to `haa.CREATE_BLOCK`.
- Original `v69.java:1584-1615` reads that same `rl2` table from an operation
  and constructs TEXT, IMAGE or MATH according to its block type. It does not
  define a second block-create contract for NOTE_BUNDLE children.
- The standalone reducer already materializes all three block types on live or
  archived pages, including z-order, page revision, search invalidation and
  IMAGE asset references.

## Decision

- Expose `decodeOriginalCreateBlockTable()`, `preflightTable()` and
  `applyTable()`. Standalone and NOTE_BUNDLE paths decode the same nested
  `rl2` table and enter one reducer; no synthetic outer `uq9` envelope is
  created.
- Preflight every type-22 child and its page sequence before page bootstrap or
  content writes. Apply accepted children in operation-vector order inside the
  existing all-or-nothing NOTE_BUNDLE transaction. A block may target the
  bundle's final archived page because the standalone reducer owns archived
  snapshot materialization.
- Treat a repeated CREATE identity as idempotent only when the persisted CREATE
  baseline, exactly one live/archived/hidden payload, and any IMAGE asset
  metadata/reference all match. Partial state or a different baseline is an
  identity conflict and rolls back the bundle.
- Compare immutable `create_z_index`, not the current z-index register. A later
  valid MODIFY_BLOCK may change current ordering; retrying the original CREATE
  must neither reject nor overwrite that winning modification.
- Close the CREATE baseline result set before querying materialized payload or
  asset state, avoiding nested asynchronous RDB queries with a live cursor.

## Verification

- ArkTS fixtures decode and preflight a real type-22 TEXT child table in a
  NOTE_BUNDLE.
- `d02-note-bundle-create-block.mjs` covers TEXT, IMAGE and MATH in one bundle,
  PENDING IMAGE asset registration, z-order, page revisions, archived-page
  creation, exact retry, identity conflicts, retry after a z-index modification,
  partial-state rejection, invalid preflight zero-write and injected rollback.
- All Node/SQLite replays pass: `TOTAL=50 FAILED=0`.
- After `hvigor clean`, both `note@default` and `note@ohosTest` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

ADR-0050 later found that this phase's standalone reducer was archive-capable,
but NOTE_BUNDLE bootstrap had not created the production archive container.
ADR-0050 supplies that missing binding/materialization step and the production-
shaped replay; the archived-page claim above must be read together with it.

NOTE_BUNDLE MODIFY_BLOCK and Text character/style children remain deferred.
Delete-before-create and modification of hidden entities also remain deferred.
Tape/effects, PDF background, private authentication transport and server-side
note/site creation are separate work; this phase does not close D-02.
