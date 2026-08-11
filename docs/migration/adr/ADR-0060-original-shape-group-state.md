# ADR-0060: Preserve original 1.0.3 Shape and Group CRDT state

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload types 18 through 21 are `CREATE_SHAPE`, `MODIFY_SHAPE`, `CREATE_GROUP` and
  `MODIFY_GROUP` (`haa/rbb`). `v69/fsi` resolve a Shape or Group by the CREATE operation identity;
  a Shape is a page element, while a Group is a note-level identity-to-members entity.
- `ao2/le8/n5d/m5d` show three Shape definition discriminators: LINE, POLYGON and NORMAL_SHAPE.
  In original 1.0.3 the supported normal-shape reader materializes ELLIPSE. LINE preserves optional
  Bezier controls and arrow head; POLYGON preserves its bounded point vector.
- `j0/l85/k85/cm2/vd8/a1j` show that page+origin, rotation, scale, definition, tool, style,
  tape pattern, color, border width, fill color, z-index, position lock, ink effects and tint are
  independent LWW registers. `smartHighlight` and `force` belong only to CREATE.
- Type 24 `MODIFY_POSITIONS` targets Shape as well as Ink and Block, updating page+origin, rotation,
  scale and z-index with the type-24 operation identity. Group modification replaces the complete
  non-empty member set under one LWW winner; deleting a Group does not delete its members.
- The original Shape model also owns a RichText CRDT. NotaHarmony's current `ShapeElement` has no
  equivalent embedded-text model, so geometry materialization alone is not full Shape parity.

## Decision

- Add strict FlatBuffer decoders for types 18 through 21. Reject missing required fields, unknown
  fields, invalid identities, non-finite geometry, empty Shape target lists, empty Group members,
  invalid enums and over-budget vectors. Preserve uint64 z-index/effects as canonical decimal text.
- Add `original_shape_state` and `original_shape_modification`. Store immutable CREATE payload,
  resolved payload and per-field winner identities; journal type-19 identities so stale exact retry
  remains distinguishable from identity reuse with different bytes.
- Materialize LINE, POLYGON and ELLIPSE into existing Shape page snapshots. Reuse original page
  identity, element-order, z-index, visibility, deleted-page and deleted-entity machinery so moves,
  delete-before-create, hidden modification and undelete retain one entity rather than duplicate it.
- Add `original_group_state` and `original_group_modification`. Keep the complete current member list
  and one members winner. A Group remains non-rendering state and never cascades visibility to members.
- Route all four payloads through standalone and NOTE_BUNDLE preflight/apply. Extend type 24 target
  classification to Shape and reuse the caller-owned page-revision batch; type 24 deliberately does
  not write a type-19 modification journal.
- Include Shape/Group state in NOTE_BUNDLE change signatures. Raise the database to v56 in one
  historical migration containing all four tables.

## Verification

- ArkTS fixtures decode ELLIPSE CREATE, nullable rotation/color/uint64 z-index MODIFY, Group create
  and modify, malformed boundaries and all four supports/preflight routes.
- `d02-shape-group-state.mjs` executes v55 to v56 migration and rollback, Shape retry/conflict,
  independent LWW/null clear, stale/site tie, cross-page/z-index, hidden modify/undelete, Group
  whole-list LWW, type-24 Shape reuse, bundle signatures and the complete 31-type production route.
- All desktop replays pass with `TOTAL=69 FAILED=0`. After `hvigor clean`, both `note@ohosTest` and
  `note@default` assembleHap builds succeed.

## Remaining Boundary

This decision closes inbound storage and page materialization for the four Shape/Group payloads. It
does not claim embedded Shape RichText, Group selection/transform UI, outbound writers, complete
original CRDT export/import, or device pixel parity. Existing `ShapeElement` can render geometry,
color, fill and border width, while tool/style/tape/position-lock/effects are retained in original
state until consumers can implement them with original evidence.
