# ADR-0663: Original import-sheet arrange mode (w8/te4)

- **Status**: Accepted
- **Phase**: 715
- **Depends on**: ADR-0629 (import details sheet `zvh.a`/`ou5`)

## Context

The original `zvh.a` import-details sheet has an arrange mode that
Harmony's `ImportDetailsSheet` (Phase 662) did not port:

- `w8.java:155` — header button toggles `arrange` ↔ `done` (`z11`
  arranging state), entering/leaving reorder mode.
- `te4.java:76-77` — in arrange mode each file row carries
  `ui_fileimport__move_up`/`move_down` accessibility-labeled move
  actions (`oe4` handler swaps neighbors; the drag handle `z5c.H`
  exposes them to TalkBack).
- Reordering applies before materialization: `rv5` note creation order,
  `sv5`/`qv5` page-append order both follow list order.

## Decision

Port as a bounded equivalent:

1. `ImportDetailsSheet` gains `@State orderedFiles` (a copy of `files`)
   and `@State arranging`. All iteration (`ForEach`, title drafts,
   `confirm`) runs on `orderedFiles`.
2. Header shows a text toggle (`Arrange`/`Done`, reusing the existing
   `done` string) only when `orderedFiles.length > 1` — reordering a
   single file is meaningless.
3. In arrange mode each row shows ↑/↓ buttons with
   `import_move_up`/`import_move_down` accessibility text (ArkUI
   equivalent of the TalkBack move actions; a visible control is
   required since ArkUI rows lack drag-reorder). Boundary moves are
   disabled. The per-file title input hides while arranging (the row's
   accessory slot is occupied by move controls, mirroring `te4`'s
   arrange-mode row composition).
4. `ImportPlan` gains `orderedUris?: string[]`; `dispatchImportPlan`
   prefers it when present and length-equal to the picker set (guards
   out-of-band plans), keeping all three destination branches ordered.
   Callers that omit `orderedUris` keep picker order — backward
   compatible.

## Consequences

- Multi-file imports can be reordered before materialization in all
  three destinations (separate/single/existing).
- Title drafts follow their file when moved (index-aligned swap).
- No drag gesture — buttons only; a future enhancement could add
  drag-reorder without contract change.
