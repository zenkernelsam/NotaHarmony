# ADR-0055: Preserve original PDF field typed state

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload type 27 is `MODIFY_PDF_FIELD`. `ee8` contains required 64-byte `assetHash`,
  required UTF-8 `key`, value type `STRING(0)` or `BOOLEAN(1)`, nullable `valueString` and nullable
  `valueBoolean`.
- `ee8.a()` requires the selected typed value and rejects a missing value. `q0j.d()` materializes
  only the selected string or boolean type.
- `p0j.d()` temporarily enables the FlatBuffers builder `forceDefaults` flag before writing field 4.
  Therefore BOOLEAN false has an explicit field-4 vtable entry; a missing field 4 is null, not false.
- `v69` reduces the payload into the map for its asset hash using `bl2(operationId, key, value)` and
  emits `s09(assetHash, key)` as a PDF-field change. `al2` resolves each key by operation identity.
- The model map is keyed by asset hash independently of local asset metadata. An event can therefore
  be valid before the referenced PDF file or `note_asset` row is locally available.

## Decision

- Add database v54 table `original_pdf_field_state`, keyed by `(note_id, asset_hash, field_key)`.
  Store the selected typed value and winning timestamp/site, with a note-scoped unique winner
  identity. Do not add a foreign key to `note_asset`; note deletion remains the ownership boundary.
- Reuse one strict 64-byte asset-hash-to-canonical-hex helper for type 2 and type 27.
- Strictly decode UTF-8 strings with bounded byte length, non-empty keys, enum 0/1, canonical bool
  bytes and no fields above 4. STRING requires only field 3. BOOLEAN requires only an explicitly
  present field 4, including false.
- Apply `(assetHash, key)` registers by timestamp/site LWW. Exact winner retries are idempotent;
  reuse of an identity with another hash, key, type or value is a hard identity conflict; stale
  operations do not write.
- Route type 27 through standalone and NOTE_BUNDLE preflight/apply paths. NOTE_BUNDLE compares a
  deterministic length-prefixed state signature so note-level PDF field writes are reflected in its
  `applied` result without abusing page content revisions.
- Export `readOriginalPdfFieldValue` as the model boundary for a future form renderer/cache consumer.
  Do not advance page revisions: one PDF asset can back multiple pages, and the original invalidation
  identity is asset-plus-field rather than a single page.

## Verification

- ArkTS fixtures cover string, boolean true, explicitly encoded boolean false, missing hash,
  missing typed value, type/value mismatch, unknown enum/field and unified-router support.
- `d02-modify-pdf-field.mjs` covers v53 to v54 migration, all typed values, multiple keys/hashes/
  notes, stale/site tie, exact retry, identity conflicts, event-before-asset, NOTE_BUNDLE rollback,
  note cascade and migration rollback.
- All desktop replays pass with `TOTAL=64 FAILED=0`. Clean HAP build results are recorded in the
  Phase 77 report.

## Remaining Boundary

Harmony's `PdfBackgroundLoader` currently rasterizes PDF pages and has no AcroForm widget geometry,
appearance stream, overlay, focus or outbound editing path. This ADR preserves the original model
state and routing only. It does not claim visual or interactive PDF form parity until a proven PDF
form consumer and device acceptance are added.
