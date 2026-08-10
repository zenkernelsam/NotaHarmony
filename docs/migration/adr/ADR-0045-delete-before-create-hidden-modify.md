# ADR-0045: Entity visibility is independent of CREATE arrival order

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java:38` maps `s83` to
  `DELETE_ENTITIES` (payload type 25).
- Original `s83.java` stores entity deletes and undeletes independently of the
  entity CREATE payload. `v69.java:1348-1402` applies both with the outer
  operation identity and processes deletes before undeletes, so undelete wins
  when the same entity occurs in both vectors.
- The original visibility register therefore exists logically before or after
  entity materialization. The v46 Harmony schema contradicted that property by
  making `original_entity_visibility_winner` reference
  `original_element_z_index`.

## Decision

- Database v47 rebuilds `original_entity_visibility_winner` without the entity
  foreign key. The note foreign key and `ON DELETE CASCADE` remain. Existing
  winners are copied without changing their identity or deleted value.
- `DELETE_ENTITIES` persists the LWW winner when the entity is genuinely
  absent. A tracked but unbound or structurally divergent entity still defers;
  missing CREATE is not used to hide corruption. Stale updates are no-ops and
  an equal identity with the opposite value is a conflict.
- CREATE_INK and CREATE_BLOCK read any pre-existing winner. A deleted winner
  creates the complete Ink/Block register state and z-index row with
  `visible=0`, then writes the payload directly to `original_deleted_entity`.
  It never enters a live or deleted-page active snapshot and never advances
  the page revision. An undeleted or absent winner follows the active path.
- Hidden ADD_PATH_ELEMENTS, MODIFY_INK, MODIFY_BLOCK, Text insertion,
  character visibility and RichText style operations continue updating their
  normal LWW/SeqId tables. Their materialized payload is read and written in
  `original_deleted_entity`. Page/origin and z-index changes update both the
  archive metadata and `original_element_z_index`, so a later undelete restores
  the entity on the final page and materializes the final order.
- Hidden-only changes do not alter visible page revision, search state or
  element order. Undelete is the visible change and performs those updates.
  Exact CREATE retries validate both register baselines and the unique
  active/hidden payload location.

## Verification

- `d02-delete-before-create-hidden-modify.mjs` verifies v46-to-v47 winner
  preservation, the remaining note cascade, pending delete/undelete LWW,
  hidden CREATE exact retry/conflict, hidden Ink and Text creation,
  hidden payload/page/z-index modification,
  final undelete placement, stale no-op, equal-identity conflict and injected
  transaction rollback. Static guards cover all standalone reducers reused by
  NOTE_BUNDLE.
- `OriginalEntityVisibilityState.test.ets` locks initial/newer/stale decisions,
  site-id tie breaking, exact retry and opposite-value conflict. The test is
  registered in the ArkTS test package. The stale `DatabaseHelper.test.ets`
  v45 assertion was corrected to v47 and now checks the intended foreign-key
  boundary.
- All Node/SQLite replays pass: `TOTAL=54 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

Delete-before-create and the supported hidden Ink/Block/Text mutation paths are
connected. Tape/effects, PDF background, private authentication transport and
server-side note/site creation remain separate work; D-02 is not closed.
