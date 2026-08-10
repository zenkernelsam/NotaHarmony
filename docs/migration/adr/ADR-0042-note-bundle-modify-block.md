# ADR-0042: NOTE_BUNDLE MODIFY_BLOCK reuses the standalone reducer

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java:36` maps `td8` to
  `haa.MODIFY_BLOCK`.
- Original `td8.java` exposes one 18-field contract for Block identities,
  common registers, and mutually exclusive Math, Image or Text properties.
  Its validator rejects an empty target vector and mixed type-specific groups.
- The standalone reducer already owns all sixteen persisted register groups,
  TEXT/IMAGE/MATH type gates, live/archive movement, z-order, page revision and
  search invalidation.

## Decision

- Expose `decodeOriginalModifyBlockTable()`, `preflightTable()` and
  `applyTable()`. Both standalone and NOTE_BUNDLE paths decode the nested `td8`
  table and enter the same reducer.
- Preflight geometry and mutually exclusive type-specific groups before any
  bundle page or content write. Apply valid type-23 children in operation-vector
  order inside the existing NOTE_BUNDLE transaction.
- For all sixteen persisted registers, an equal winner identity is idempotent
  only when its value equals the incoming value. A different value is an
  identity conflict and rolls back the complete bundle; an older identity
  remains a normal LWW no-op.
- Once syntactic preflight has passed and bundle writes have begun, a reducer
  may not return deferred and allow earlier page/content changes to commit.
  Convert any runtime content divergence to an exception so the inbox rolls
  back page bootstrap and every preceding child together.

## Verification

- ArkTS fixtures decode and preflight a type-23 child that targets a preceding
  type-22 block in the same NOTE_BUNDLE.
- `d02-note-bundle-modify-block.mjs` covers common multi-target updates, TEXT,
  IMAGE and MATH registers, live and archived revisions, exact retry, identity
  conflict, stale no-op, invalid zero-write, runtime-deferred rollback and
  injected all-or-nothing rollback. Static guards cover all sixteen winner
  groups and production bundle wiring.
- All Node/SQLite replays pass: `TOTAL=51 FAILED=0`.
- After `hvigor clean`, both `note@default` and `note@ohosTest` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

NOTE_BUNDLE character insertion/removal/revival and character/paragraph style
children remain deferred. Delete-before-create and hidden-entity modification,
Tape/effects, PDF background, private authentication transport and server-side
note/site creation also remain separate work; D-02 is not closed.
