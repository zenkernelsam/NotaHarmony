# ADR-0061: Preserve original Shape RichText through the shared text CRDT

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `n5d` stores an `m4c` RichText object on every Shape. `rbb.k()` creates a Shape
  with `new m4c(null)` rather than a plain label string.
- `m5d.c()` dispatches payload types 7 through 14 to a Shape: insert character/string, remove one
  or many characters, revive characters, modify character style, modify paragraph style and clear
  style. Their `textField` identity is the Shape CREATE operation ID.
- The original Shape path does not consume type 28 `UPDATE_CHECKBOX`; that operation remains a
  Text Block paragraph behavior.
- Type 19 rebuilds Shape geometry from its resolved registers. The Shape-owned `m4c` is independent
  state and therefore must survive geometry/color/page/z-index modification.

## Decision

- Reuse the existing character SeqId, visibility LWW and style-operation reducers for both Text
  Blocks and Shapes. Do not invent a separate Shape label protocol.
- Add optional RichText and materialized character/paragraph style runs to `ShapeElement`. Optional
  fields keep pre-v57 Harmony snapshots readable as empty text; newly created original Shapes start
  with explicit empty RichText.
- Raise the database to v57. Rebuild `original_text_character` and
  `original_text_style_operation` so their owner FK references `original_element_z_index`; keep
  `original_text_checkbox_state` tied to `original_block_state`.
- Resolve a text owner only when the element kind and concrete owner state agree: TEXT requires a
  Text Block state of TEXT type, while SHAPE requires Shape state. This prevents an unrelated
  element identity from becoming a RichText owner merely because it exists in z-order state.
- Read and write Shape payloads through live, deleted-page and hidden-entity snapshot paths. Preserve
  RichText and both run arrays whenever type 19 rematerializes geometry.
- Deep-copy Shape RichText runs through geometry, history, clipboard and package paths. Validate
  Shape runs with the same Unicode code-point boundaries and style schema as Text Blocks, and include
  non-empty Shape RichText in the existing text search index.

## Verification

- `d02-shape-rich-text.mjs` executes v56 to v57 migration, old Text Block row preservation,
  transaction rollback, Shape-owned character/style rows, non-element FK rejection, owner/note
  cascade and static production contracts for insert/visibility/style, checkbox rejection,
  hidden/deleted-page handling, type-19 preservation, package validation and search.
- ArkTS tests guard DB v57/FKs and valid/invalid Shape style-run boundaries.
- All desktop replays pass with `TOTAL=70 FAILED=0`. Incremental `note@default` and
  `note@ohosTest` HAP builds succeed; clean build results are recorded in the Phase 83 report.

## Remaining Boundary

This decision closes inbound Shape RichText state, persistence, copy/package validation and search.
It does not claim visible Shape text layout, editing UI, caret/hit testing, original font/inset rules,
outbound operation writers or full CRDT export. Those consumers require further direct original-code
evidence and device/pixel verification.
