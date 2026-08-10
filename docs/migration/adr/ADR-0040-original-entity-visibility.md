# ADR-0040: Preserve original entity visibility independently from page storage

## Status

Accepted, 2026-08-11.

## Evidence

- Original `s83.java` stores entity deletes and undeletes in fields 0 and 1 as
  8-byte `qo5` vectors. Fields 2 and 3 are separate 12-byte page sequence
  vectors. `zq9.java` maps `s83` to payload type 25 `DELETE_ENTITIES`.
- Original `v69.java:1348-1402` sends the outer operation identity and each
  entity identity to the visibility register. It applies entity deletes with
  `Boolean.TRUE` before entity undeletes with `Boolean.FALSE`, so undelete wins
  when an entity occurs in both vectors of one payload.
- `lv2.I/J` consume entity vectors directly. `icj.b/c` convert only the page
  vectors, so page and entity identities cannot share a decoder.

## Decision

- Decode and validate both entity vectors, preserve their identities, and use
  an independent LWW winner per `(note, entity timestamp, entity site)`.
  Repeated winners must have the same visibility value; older winners are
  stale no-ops.
- Keep `original_element_z_index` rows while an entity is hidden. A `visible`
  flag excludes hidden rows from target and order materialization, while Ink
  and Block state remains attached through its existing foreign key.
- Move the materialized payload between the live/deleted-page snapshot and
  `original_deleted_entity`. This works whether the containing page is live or
  archived. Rebuild visible element order, advance a page revision once per
  affected page, and invalidate that page's complete search materialization.
- Preflight page visibility before any entity write in a standalone mixed
  payload. The inbox commits a deferred result, so returning deferred after a
  partial entity mutation would corrupt storage. Any divergence detected after
  mutation throws and rolls back the enclosing transaction.
- Rebuild `original_element_z_index` in schema v46. The previous canonical
  `kind BETWEEN 1 AND 3` constraint rejected IMAGE and MATH kinds 4 and 5 even
  though their reducers were already live; the Node replay's earlier loose
  schema had hidden this production-only failure.
- NOTE_BUNDLE type 25 preflights the real child table and applies entity
  visibility inside the existing all-or-nothing bundle transaction. Page
  visibility remains owned by the bootstrap page-history reducer.

## Verification

- ArkTS fixtures assert both decoded entity identities and preflight a real
  type-25 NOTE_BUNDLE child.
- `d02-note-bundle-entity-visibility.mjs` executes the production v46 DDL and
  covers v45 migration foreign keys, IMAGE/MATH kinds, live and archived
  delete/undelete, same-payload precedence, stale and conflicting winners,
  one revision for two same-page entities, search invalidation, preserved Ink
  and Block state, deferred zero-write and injected rollback.
- All Node/SQLite replays pass: `TOTAL=49 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

Delete-before-create still defers because no entity identity row exists yet.
Operations that modify a hidden entity also defer rather than mutate its
archived payload. Tape/effects, NOTE_BUNDLE Block/Text children, PDF background,
private authentication transport and server-side note/site creation remain
separate work; this phase does not claim the complete entity CRDT is closed.
