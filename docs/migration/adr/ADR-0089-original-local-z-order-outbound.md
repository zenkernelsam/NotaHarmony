# ADR-0089: Persist local front/back selection order as original MODIFY_POSITIONS

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `dhb` routes its four layer commands separately. Cases 6/7 call `py(..., 26)`
  for one-step movement, while cases 8/9 call `cfc(9/8)` for bring-to-front/send-to-back. Harmony's
  exposed commands and `movePageElementRefs` implement the latter pair.
- `zh9.p` materializes page units, resolves selected ungrouped entities, sorts the resulting
  `ZIndexData` by unsigned uint64 zIndex and passes the rows returned by `cfc` through
  `x0j.a(list, true)` and durable `xsc.i` submission.
- `cfc` case 9 assigns selected units, in their existing relative order, consecutive zIndex values
  starting at `max + 1`. Case 8 assigns them from the current minimum and only shifts unselected
  low units whose unsigned zIndex would collide with the new selected interval. Both paths emit
  type-24 rows through `w0j`.
- A Group is one z-order unit in the original model. Its members cannot be reordered as independent
  leaves without implementing the Group writer and identity rules.

## Problem

Harmony already moved selected element references to the front or back of its page array, but the
save fell through to a private page snapshot. Existing original `original_element_z_index` winners
were not updated, so reopening or synchronizing could restore the old order. Undo/Redo also lacked
the exact uint64 values needed to reverse the original operation: an array index is not equivalent
to a potentially sparse original zIndex.

The original case-8 algorithm can update unselected low units as well as the selection. Recomputing
Undo from the current array would therefore lose the exact before values and would be unsafe after
a restart or concurrent/source-state divergence.

## Decision

- Extend the strict type-24 outbound classifier with a pure reorder path. Page identity must still
  align with the original page; member set and every persisted element payload must be byte-for-byte
  unchanged, and the target Harmony order must exactly equal the requested front/back result.
- Reproduce `cfc(9/8)` using decimal-string uint64 arithmetic. Bring-to-front starts after the
  unsigned maximum. Send-to-back starts at the unsigned minimum and shifts only conflicting low
  unselected entries. Overflow, duplicate or missing selection IDs, selecting the whole page and
  any unexpected target order use the existing private fallback.
- Reject pages containing an active original Group whose members intersect the page. This is an
  intentional fidelity boundary: treating leaves as independent units would not match original
  Group ordering. Group z-order remains coupled to later Group outbound work.
- Add database v60 table `original_local_z_order_history`, keyed by `(note_id, action_id)`, storing
  the exact changed target/value vectors before and after the PUSH. It is written after successful
  reducer application in the same transaction and retains the newest 512 mappings per note.
- PUSH verifies the current original order against the before snapshot, generates the mapping and
  emits one complete local type-24 `uq9`. UNDO requires current values to equal `after` and applies
  `before`; REDO requires `before` and applies `after`. The projected original sort order must equal
  the editor target on every path. Missing, corrupt or conflicting mappings conservatively fall back.
- The editor passes a copied command/selection hint only for the initial reorder. Undo/Redo recover
  the same action identity from durable history and read the v60 mapping, so the operation remains
  reversible after restart. Canonical reorder actions keep original CREATE_INK authoring eligible.

## Rejected Alternatives

- Persist array indices as zIndex: this destroys sparse uint64 values and does not implement original
  case 8.
- Renumber the entire page: the original only rewrites selected units plus low conflicting entries;
  broad renumbering creates unnecessary LWW winners.
- Recompute reverse values during Undo: exact pre-operation values are no longer derivable after the
  forward reducer or a restart.
- Reorder Group leaves independently: original commands operate on Group units, so this would be a
  different behavior rather than a partial implementation.

## Verification

- `d02-local-z-order-outbound.mjs` locks `dhb/cfc/zh9/py/x0j/w0j` evidence and production wiring.
  It covers front/back relative order, sparse values, uint64 overflow, Group fallback, persistent
  PUSH/UNDO/REDO mapping, source-state conflict and injected transaction rollback.
- Database tests statically include v60 migration and DDL in the ArkTS test graph.
- Full replay and clean sequential HAP results are recorded in the Phase 112 report.

## Remaining Boundary

This decision covers ungrouped same-page bring-to-front/send-to-back. One-step layer movement,
Group CREATE/MODIFY/ungroup and Group-unit ordering, reflection/Flip, other entity outbound,
authenticated upload/ACK, transient collaboration and device verification remain separate work. No
emulator, VM, device or Hypium run is part of this decision.
