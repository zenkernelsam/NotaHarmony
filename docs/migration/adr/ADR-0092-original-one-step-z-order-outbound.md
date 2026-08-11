# ADR-0092: Persist selection layer steps as original py case-26 MODIFY_POSITIONS

## Status

Accepted, 2026-08-11. This closes the one-step layer boundary left by ADR-0089 through ADR-0091
and corrects the production menu wiring that previously treated Bring forward/Send backward as
bring-to-front/send-to-back.

## Original Evidence

- Original 1.0.3 `dhb` keeps all four commands distinct. Cases 6 and 7 submit `py(..., 26)`, while
  cases 8 and 9 submit `cfc(9/8)` for the two absolute commands.
- `zh9.p` collapses active top-level Groups into `ssc` units, records selected ungrouped entities and
  selected unit IDs, sorts by unsigned zIndex, invokes the command, wraps the returned rows through
  `x0j.a(list, true)`, and durably submits them with `xsc.i`.
- `py` case 26 examines the original sorted units one by one. A selected ungrouped unit only acts
  when its immediate neighbor in the requested direction exists and is not selected. Adjacent
  selected entities therefore do not move as one contiguous block.
- Against an ungrouped neighbor, `py` swaps their two zIndex values. Against a Group neighbor, it
  changes only the selected entity to `group.zIndex + 1` or `max(group.zIndex - 1, 0)`. A selected
  Group is deliberately immovable and blocks a selected ungrouped entity from crossing it.
- Every returned row is the same type-24 `MODIFY_POSITIONS` row used by the existing local writer.

## Problem

Harmony displayed Bring forward and Send backward, but `reorderSelected()` called
`movePageElementRefs`, which removed the whole selection and appended or prepended it. It then sent
`BRING_FRONT/SEND_BACK` to persistence. A single menu press therefore jumped objects to an absolute
edge, diverging from both the original interaction and its sparse uint64 register updates.

A flat one-index swap would still be wrong when the neighbor is a Group: the original crosses the
complete top-level Group unit without splitting its leaves. Moving a selected Group would also be
wrong because `py` explicitly excludes Group units from mutation.

## Decision

- Add a strict layer-unit resolver over the loaded original Group graph. It follows the newest parent
  identity to the top Group, rejects cycles, duplicate entities and non-contiguous Group leaves, and
  keeps each Group's current internal leaf order intact.
- Add `movePageElementRefsOneStep`. It evaluates boundaries against the unchanged source unit list,
  swaps only selected-unselected neighbor pairs, crosses a Group as one unit, treats selected Groups
  and grouped leaves as immovable, and reindexes the resulting Harmony order without changing any
  element payload.
- The selection menu now passes `BRING_FORWARD/SEND_BACKWARD` plus direct ungrouped entity IDs and
  selected Group IDs. Boundary no-ops do not create history or persistence work.
- Extend the strict type-24 classifier with the exact `py` algorithm. Ungrouped neighbors exchange
  zIndex values; Group neighbors only rewrite the selected entity. The projected original unit sort
  must exactly equal the editor snapshot or the classifier rejects the operation.
- Reuse the durable v60 `original_local_z_order_history`. PUSH records exact changed before/after
  vectors in the editor transaction; restart-safe Undo/Redo validates source values before emitting
  the inverse/forward type-24 operation. Journal, reducer, snapshot and history failures roll back
  together.
- Keep the absolute `BRING_FRONT/SEND_BACK` algorithms for non-menu callers and historical evidence;
  one-step and absolute commands are distinct enum values and verification paths.

## Rejected Alternatives

- Keep the absolute reorder under one-step labels: this is the user-visible bug being fixed.
- Move a contiguous selection block by one unit: `py` evaluates each selected entity against the
  original adjacent unit, so adjacent selected entities can be separated by the crossed neighbor.
- Swap flattened Group leaves: this breaks the original top-level Group z-order authority.
- Recompute Undo values from array indices: sparse uint64 values and Group-neighbor arithmetic are
  not recoverable from a flattened index after restart.

## Verification

- `d02-local-z-order-one-step.mjs` locks `dhb/zh9/py` evidence, production wiring, multi-selection,
  adjacent selections, Group crossing, selected-Group no-op, boundary no-op, restart Undo/Redo,
  source-state conflict and transaction rollback.
- ArkTS tests cover the pure mixed-element one-step order, Group-unit crossing, selected Group and
  grouped-leaf no-op, nested top-Group materialization, non-contiguous leaves and cyclic state.
- Full replay and clean sequential HAP results are recorded in the Phase 115 report.

## Remaining Boundary

No emulator, VM, device or Hypium was run. Device verification still needs sparse/mixed pages,
adjacent and disjoint multi-selection, Group neighbors, repeated forward/backward steps, boundaries,
restart, Undo/Redo and remote replay. Group authoring, crop editing UI, remaining entity outbound,
private authenticated upload/ACK and centralized device acceptance remain separate work.
