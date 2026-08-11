# ADR-0090: Materialize original Group layering as z-order units

## Status

Accepted, 2026-08-11. This supersedes ADR-0089's temporary active-Group fallback while retaining
its durable type-24 history design for ungrouped entities.

## Original Evidence

- Original 1.0.3 `l85` initializes `GroupImpl.e` from `uq9.k()`: a Group's immutable initial
  zIndex is the CREATE_GROUP operation clientTime.
- `vnd.compareTo` uses `und(GroupLayering)` zIndex and Group identity as the primary ordering key,
  then the leaf entity zIndex and identity inside one Group. Nested members therefore inherit the
  top Group unit, while retaining their own internal order.
- `zh9` deduplicates page units by Group-or-entity ID and builds `selectedUngroupedEntities` only
  from `!ssc.c` rows. `cfc` cases 8/9 inspect all units but only emit `w0j` type-24 rows for
  ungrouped entities. A pure Group front/back command is a no-op; a mixed selection changes only
  selected ungrouped entities. Case 8 also refuses to shift an unselected Group even when it
  occupies a low collision slot.

## Problem

The Phase 82 reducer persisted Group membership but discarded the Group CREATE clientTime. Page
`element_order` was still materialized by sorting every leaf's own zIndex, so Group members could be
split around unrelated elements after create, modify, visibility changes, page moves or restart.
Phase 112 consequently rejected every page containing an active Group and the UI incorrectly moved
all expanded Group leaves for front/back commands.

The synced inbox commits an applier-returned `deferredReason`. A Group-order check performed after
writing CREATE_INK/CREATE_BLOCK state would therefore commit a partial reducer application instead
of rolling it back.

## Decision

- Database v61 adds nullable, canonical uint64 TEXT `original_group_state.z_index`. New Groups store
  `operation.clientTime`; migration backfills old rows only from the matching payload-20 row in
  `original_applied_operation_time`. A legacy row without exact timing remains null and blocks
  Group-aware ordering instead of inventing a value.
- `OriginalGroupLayering` is the single ordering authority. It loads active Groups, chooses the
  newest parent identity when malformed/concurrent membership gives a member multiple parents,
  walks nested membership to the top unit, rejects cycles/invalid identities/null Group zIndex, and
  sorts Group units before sorting their leaf entities.
- CREATE Ink/Block/Shape, MODIFY Ink/Block/Shape and entity visibility materialize page order through
  that authority. CREATE/MODIFY_GROUP and Group delete/undelete refresh all affected original pages.
  Live search state is invalidated and archived indexed revisions are cleared only when order changes.
- CREATE Ink/Block/Shape computes and validates the complete Group-aware target order before any
  reducer or asset-reference write that could return deferred. Later divergence throws, allowing the
  surrounding inbox transaction to roll back.
- The local z-order classifier now represents original Group units explicitly. `cfc` maximum,
  minimum, saturating subtraction, selected-unit exclusion and the `!unit.group` shift guard are
  reproduced while type-24 history still records only changed entity zIndex values.
- The editor recursively separates selected Group leaves from directly selected entities. Pure
  Group front/back returns without history or persistence. A mixed command reorders only direct
  entities and passes selected Group IDs so `cfc` can treat them as selected immutable units.

## Rejected Alternatives

- Use the minimum, maximum or average member zIndex as Group zIndex: none matches `l85.e` and each
  changes ordering after member edits.
- Give every Group leaf the Group zIndex: this loses the original secondary leaf ordering.
- Modify Group zIndex through type 24: `zh9` excludes Group rows and `cfc` explicitly guards Group
  shifts, so such an operation has no original writer.
- Commit reducer state and defer only page ordering: inbox deferred results commit, producing a
  non-idempotent partial apply.

## Verification

- `d02-original-group-layering.mjs` locks `l85/vnd/und/zh9/ssc/cfc` evidence and exercises Group
  continuity, nesting, newest-parent selection, visibility, cycles, missing zIndex, pure/mixed cfc
  behavior, preflight wiring and v60-to-v61 backfill.
- `d02-local-z-order-outbound.mjs` now verifies the Group-aware Phase 112 classifier boundary.
- Full replay and clean sequential HAP results are recorded in the Phase 113 report.

## Remaining Boundary

Group authoring commands, identity-preserving Group copy/export, one-step layer movement, remaining
entity outbound writers, complete `.note` CRDT round-trip, authenticated transport/ACK and device
verification remain separate work. No emulator, VM, device or Hypium run is part of this decision.
