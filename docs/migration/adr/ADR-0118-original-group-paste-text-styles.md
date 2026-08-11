# ADR-0118: Preserve original Text styles in Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `cie.u()` creates the copied Text Block first, selects that new Block as the
  operation target, and then calls `m4c.u()` for non-empty RichText.
- `m4c.u()` inserts the string, maps every old Unicode code point to the newly inserted sequence
  identity, and emits character and paragraph style operations over those new identities.
- Character style ranges use `BEFORE` and `END_OF_DOC` boundaries. Paragraph style ranges use
  sequence identities with an omitted end for the document tail. Checkbox state is not a
  `MODIFY_PARAGRAPH_STYLE` field in the supported schema; it belongs to type-28 UpdateCheckbox.

## Decision

- Encode every non-empty character style run as original type-12 `MODIFY_STYLE`, and every
  non-checkbox paragraph style run as type-13 `MODIFY_PARAGRAPH_STYLE`, after type-8
  `INSERT_STRING` has assigned the new sequence identities.
- Index by Unicode code point, not UTF-16 code unit. Use the INSERT_STRING operation identity plus
  each run offset as the original sequence identity and preserve the original end-of-document
  boundary convention.
- Strictly validate ranges, UTF-8 strings, booleans, enum domains, canonical signed ARGB colors and
  exact float32 values before persistence. Reject `isChecked` until a separate type-28 copy path is
  proven from the original implementation.
- Apply CREATE_BLOCK, INSERT_STRING, all style operations, CREATE_GROUP and NCP1 in the existing
  single transaction. Style reducers share the page revision batch, while each wire operation owns
  an independent operation identity and upload-immediate journal row.
- Read the canonical Text from the reducer snapshot after replay and require its materialized style
  runs to equal the clipboard source. Any encoding, reduction, grouping or history divergence rolls
  the entire Paste back.

## Rejected Alternatives

- Copy style arrays only into the Harmony snapshot: original peers and later CRDT operations would
  never observe those styles.
- Address ranges by UTF-16 offset: characters outside the BMP would shift every later SeqId.
- Encode checkbox state in the deprecated paragraph field: the 1.0.3 protocol has a dedicated
  UpdateCheckbox operation and the paragraph decoder deliberately rejects that field.
- Accept lossy float or unsigned color aliases: reducer materialization would no longer be byte
  identical to the source snapshot even though the visual value might appear similar.

## Verification

- `OriginalRichTextStylePayloadEncoder.test.ets` wraps and decodes type-12/type-13 payloads, checks
  Unicode identities, `END_OF_DOC`, strings, colors, exact float32 and explicit false values, then
  feeds the decoded operations through `materializeOriginalTextStyles()` and compares both run
  collections with the source.
- The same fixture rejects empty, overlapping and out-of-bounds ranges, empty attributes, invalid
  enums, lossy float32, non-canonical colors, malformed Unicode and checkbox state.
- `d02-original-group-paste-text-styles.mjs` locks original evidence, production wiring, canonical
  replay, single-revision batching and rollback gates. Full build and replay results are recorded in
  the Phase 141 report.

## Remaining Boundary

Initial checkbox state still requires a separately proven type-28 UpdateCheckbox copy sequence.
Shape-owned RichText remains outside this Text Block phase.
