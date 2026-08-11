# ADR-0062: Resolve original Group membership before selection transforms

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `gtc` represents a selected Group with a Group identity, selected leaf identities,
  bounds and rotation. `cqc` carries the Group identity, member set and aggregate bounds.
- `xtc` passes directly hit positionables through `fu1.c()` before constructing the selection.
  Therefore Group is selection metadata, not a drawable page element.
- `fu1.c()` maps every member to its newest containing Group using `so5.a()` operation-identity
  ordering, walks through nested Groups to the top ancestor and recursively expands that Group to
  positionable leaves. Tombstoned Groups are excluded from the model lookup.
- `lg2.c()` recursively discovers nested Groups for copy and treats an identity that is neither a
  Group nor an available positionable as invalid. It does not manufacture a complete Group from a
  partial member set.
- Original Shape `n5d.t()` exposes the `positionLocked` register. A locked Shape must not become a
  selectable leaf merely because its geometry intersects a rectangle or lasso.

## Decision

- Load current Group member lists from `original_group_state`, filter Groups whose canonical
  visibility winner is deleted and preserve operation identities as encoded element IDs.
- Resolve a direct hit to the newest containing Group, then walk to its top ancestor and recursively
  expand nested Groups. Deduplicate leaves while retaining deterministic source order.
- Require every expanded leaf to be available on the current page and supported by the editor.
  Missing, cyclic, cross-page, locked or currently unsupported leaves invalidate the expansion;
  selection falls back to the directly hit entity instead of applying a partial Group transform.
- Persist the selected top Group IDs in `SelectionState` across drag completion. This is required
  metadata for later Group-aware copy and ungroup writers; retaining it does not itself claim those
  outbound operations are implemented.
- Materialize Shape `positionLocked` from CREATE/MODIFY resolved state, preserve it in Shape clones
  and validate its optional boolean package representation. Legacy and locally detected Shapes with
  no field remain unlocked.

## Verification

- `OriginalGroupSelection.test.ets` covers latest-containing/site tie behavior, top-level nested
  expansion and missing/cyclic fallback. `SelectionTool.test.ets` covers Group leaf expansion and
  locked Shape exclusion.
- `d02-group-selection-consumer.mjs` executes the matching resolver cases, validates tombstoned Group
  filtering with SQLite and locks the production loading, selection, canvas and Shape materialization
  wiring.
- All desktop replays pass with `TOTAL=71 FAILED=0`. After `hvigor clean`, both `note@ohosTest` and
  `note@default` HAP builds succeed; no device or Hypium execution was performed.

## Remaining Boundary

This decision originally closed Group-aware selection and transform for stroke, Shape, Text Block
and Image leaves while a Group containing Math used the safe no-partial-expansion fallback. ADR-0063
supersedes that temporary boundary by completing the Math editor lifecycle and making Math an
available Group leaf. Group CREATE/MODIFY/ungroup outbound writers, Group-preserving copy/paste/export
and complete private-package CRDT export remain separate work.
