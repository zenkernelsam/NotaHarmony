# ADR-0058: Validate and consume original 1.0.3 comment payloads without inventing a model

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload types 30 and 31 are `CREATE_COMMENT` (`tl2`) and `MODIFY_COMMENT` (`ud8`).
  `wq9/fsi.P` classify both as durable rather than transient.
- `tl2/daj/z5c.t/im` define four create-anchor union variants: a canvas page/point struct, a
  text-field/selection table, a deduplicated entity-ID collection, and a reply-root struct. Create
  validation requires a non-`NONE` anchor and non-empty text.
- `ud8/k0j` require a comment operation ID and at least one of an optional direct canvas anchor,
  nullable `SetString` text, or nullable `SetBool` resolved setter. A present setter whose inner field
  is absent represents an explicit null; the generated boolean reader treats every non-zero byte as
  true.
- The original 1.0.3 `v69` reducer has no type-30 or type-31 model branch. Both fall through the
  generic dependency path, while `fsi.F` and `fsi.K` explicitly return empty dependencies/targets
  for both types. There is no `tl2/ud8` consumer outside schema readers/writers and union dispatch.
  Valid comment payloads are therefore consumed without creating or modifying durable model state.

## Decision

- Add strict decoders for both schemas. Preserve all four create-anchor variants, validate identities,
  sequence IDs, finite canvas coordinates and UTF-8, bound operation-sized text and entity vectors,
  deduplicate entity anchors like the original set builder, reject unknown fields and require the
  original semantic invariants.
- Add a bounded indirect-inline-struct reader to the shared FlatBuffer reader. This is needed because
  create canvas/reply union values are uoffsets to structs, while modify canvas anchor is a direct
  inline struct; treating both layouts as tables or as the same struct placement is incorrect.
- Route valid standalone types 30/31 through the durable inbox as applied zero-model-write operations.
  Malformed comments remain deferred and block the ordered head, unlike the original peer-presence
  branch that explicitly catches and discards malformed conversion.
- Let NOTE_BUNDLE strictly preflight both comment tables and then perform the same zero-model-write
  consumption inside its transaction. Do not add a database migration, comment table, CRDT register,
  renderer or UI that the target original version does not have.

## Verification

- ArkTS fixtures cover canvas, text, entity and reply anchors, entity deduplication, nullable setters,
  non-zero boolean behavior, required comment ID, empty create text, unknown union/fields, missing
  changes, non-finite canvas points, zero writes and malformed deferred behavior.
- `d02-comment-schema-noop.mjs` locks the schema, ordered inbox continuation, original zero-model
  reducer boundary and NOTE_BUNDLE preflight/no-op route.
- All desktop replays pass with `TOTAL=67 FAILED=0`. Clean HAP results are recorded in the Phase 80
  report.

## Remaining Boundary

This decision reaches parity with the inspected original 1.0.3 behavior; it does not claim a visible
comment feature. A future implementation of comment storage, CRDT conflict handling or UI requires
evidence from an original version that actually contains such a consumer and must not be inferred
from these currently dormant protocol schemas.
