# ADR-0099: Persist original local Group authoring and Ungroup

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `dsc` defines `GROUP=4` and `UNGROUP=5`; `ux9` and the original resources expose
  both commands in the selection menu.
- `dhb` case 4 accepts the drawn-selection model `ftc`, combines directly selected positionable
  identities (`ftc.q`) with selected Group identities (`ftc.m`), requires at least two resulting
  member units and dispatches `kk9` case 29.
- `dhb` case 5 accepts one directly selected Group (`gtc`) or the single Group carried by a drawn
  selection, then dispatches `wsc`. Ungroup removes the Group unit without deleting its leaves.
- The original operation schema represents CREATE_GROUP as payload type 20 whose field 0 is the
  complete member vector. MODIFY_GROUP is type 21 with Group identity in field 0 and the complete
  replacement member vector in field 1. The Group identity is the CREATE operation identity and its
  layer z-index is that operation's client time.

## Decision

- Add strict type-20 and type-21 FlatBuffer writers. Identities must be canonical, member vectors
  must be non-empty, unique and within the original 10,000-entry budget. The production Group
  command uses type 20; type 21 is retained and fixture-covered for a later evidence-backed member
  replacement consumer.
- Resolve local Group members exactly as original member units: remove the recursively expanded
  leaves of selected Groups from the direct entity set, then append each selected Group identity as
  one member. Missing leaves, cycles, duplicate Groups and fewer than two member units are rejected.
- Expose Group only for a valid two-or-more-unit canonical selection and Ungroup only for one active
  selected Group. Keep the selected leaves after either command; Group replaces the selected Group
  metadata with the new identity, while Ungroup clears it.
- Execute CREATE_GROUP through `OriginalShapeGroupOperationApplier`. Execute Ungroup, Undo and Redo
  by deleting or undeleting the Group identity through the existing type-25 visibility reducer.
  Members are never cascade-deleted. Existing Group layering remains the only page-order authority.

## Atomicity And Persistent History

- Flush the page save queue, acquire `editorPersistenceMutex`, verify the live original page and
  exact source order, then apply the original operation, upload-immediate journal row and Harmony
  history companion in one transaction. Any stale member, cross-page leaf, reducer defer, order
  mismatch or append failure rolls back the entire command.
- Add the strict `NGM1` companion. It stores the affected Group before/after state and both complete
  normalized page orders; it rejects changed page membership, duplicate identities and noncanonical
  z-index positions rather than silently normalizing damaged history.
- PersistentHistory treats type-20/type-21/type-25 outbound rows as transparent companions and
  restores one `GROUP_ELEMENTS` action. Undo/Redo first validates the in-memory and database source
  state, reuses the immutable CREATE member vector, applies Group visibility, verifies reducer
  layering, then appends the matching NGM1 UNDO/REDO row before committing the history stack.

## Verification

- ArkTS fixtures cover type-20/type-21 round trips and malformed members, member-unit authoring,
  NGM1 round trip and corruption rejection, persistent PUSH/UNDO/REDO restoration, and in-memory
  history accounting.
- `d02-local-group-authoring.mjs` locks the original menu branches and production wiring, then
  replays nested Group unit layering, type-20 creation, type-25 Ungroup, Undo/Redo and injected
  transaction rollback with SQLite.
- All 108 desktop Node/SQLite replays pass. Final clean HAP results are recorded in Phase 122. No
  emulator, VM, device or Hypium is used.

## Remaining Boundary

Device interaction acceptance, evidence-backed local type-21 membership editing, Group-preserving
clipboard/package export, remaining Shape registers, complete original package round trip and the
private authenticated upload/ACK transport remain subsequent Goal work.
