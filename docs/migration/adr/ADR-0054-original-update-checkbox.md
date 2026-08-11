# ADR-0054: Preserve original location-keyed checkbox state

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload type 28 is `UPDATE_CHECKBOX`. `mqf` contains a TextField identity, a stable
  RichText location and a boolean value. `lti` writes those as fields 0, 1 and 2; false is the
  FlatBuffer default and therefore does not require an explicit field-2 vtable entry.
- `e4c` converts the payload to `bl2(operationId, location, Boolean)`. The operation identity is the
  LWW event identity, while the stable location is the RichText map key.
- `v69` first resolves the payload TextField and then reduces the event inside that RichText model.
  A missing target is retryable/deferred, not a successful no-op.
- `he8` explicitly marks the old paragraph `isChecked` field as deprecated and directs writers to
  UpdateCheckbox. `lj3` also shows that checkbox state may exist while the current decorator is not
  a checkbox; state and paragraph decorator style are independent.

## Decision

- Add database v53 table `original_text_checkbox_state`. Its primary key is note, Text Block and
  stable character location. Each row stores the boolean and its winning timestamp/site; a unique
  note-scoped winner identity prevents one operation identity from being reused for another key.
- Strictly decode required inline TextField and location structs. Accept an absent boolean field as
  explicit false, but reject non-canonical bool bytes and unknown payload fields.
- Resolve both TextField and location before mutation. They must identify the same existing Text
  Block, including archived pages and hidden entities. Missing or cross-Block references defer with
  zero writes.
- Apply the register by timestamp/site LWW. Exact winner retries are idempotent; reusing a persisted
  identity with another Block, location or value is an identity conflict; stale values do not write.
- Keep checkbox state independent from paragraph style. Materialization emits `isChecked` only when
  the location currently has checkbox decorator style 3. A non-checkbox style retains the durable
  state without changing snapshot or page revision, so changing the decorator back restores it.
- Every INSERT/REMOVE/REVIVE and character/paragraph style materialization reads checkbox state.
  Hidden characters retain the register and recover it when revived.
- ADR-0123 supersedes the temporary U+2610/U+2611 rendering: checkbox decorator 3 now uses the
  original vector circle/check geometry, fixed marker column and shared draw/hit center.
- Route type 28 through standalone and NOTE_BUNDLE paths. Existing outer transactions and transient
  guards remain authoritative.

## Verification

- ArkTS fixtures cover checked true, omitted/default false, missing required target, unknown fields
  and unified-router support.
- `d02-update-checkbox.mjs` covers v52 to v53 migration, toggle, stale/site tie, exact retry,
  identity conflicts, missing/cross-Block zero-write, state retention outside checkbox style,
  visibility remove/revive, cascade, migration rollback, renderer and NOTE_BUNDLE routing.
- All desktop replays pass with `TOTAL=63 FAILED=0`. Clean HAP build results are recorded in the
  Phase 76 report.

## Remaining Boundary

ADR-0121 later adds the local outbound writer and persistent history path after tracing the original
`fm7/wh/gv0/u5j` toggle chain. Checkbox marker hit testing and interaction UI remain separate, and
device font-glyph/touch behavior still require later device acceptance.
