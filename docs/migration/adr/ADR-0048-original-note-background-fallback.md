# ADR-0048: Restore original note background fallback and nullable page registers

## Status

Accepted, 2026-08-11.

## Evidence

- Original `l2d.java` defines SET_METADATA field 0 as title and field 1 as
  SetPageBackground. `m2d.java` proves that a present wrapper with no nested
  value is an explicit null assignment, not an absent mutation.
- Original `v69.java:1161-1194` sends title and note background to independent
  registers. `fqb.java` and `so5.java` replace a value only for a strictly
  greater unsigned `(timestamp, site)` identity.
- Original `a79.java:63-67,107-110` resolves a null note background to an
  opaque white 612x792 point page with no margins. Page registers remain
  nullable and resolve through that note register.
- Original `ya0.java` also resolves missing page PDF state through note-level
  PDF state. `sw9.java` and `ge8.java` prove that PDF state is a structured
  asset/page-consumption model, not a boolean background flag.

## Decision

- Database v50 rebuilds `original_page_background_winner` so its complete
  background tuple may be null, and adds independent note background and note
  title winner tables. Existing v49 non-null page winners are copied intact.
- SET_METADATA accepts the original title/background combination while other
  metadata fields remain deferred atomically (the field 2～7 part of this Phase 70
  boundary is superseded by ADR-0248/Phase 270). Title and background each use
  their own LWW comparison; stale values are no-ops and equal identities with
  different complete values are conflicts. Non-empty titles update both
  `note_meta` and the title search row.
- A note background update rematerializes only original pages whose page-level
  `background_json` is null, including archived pages. Their page register
  stays null. An explicit null note value resolves to the original 612x792
  opaque-white default.
- MODIFY_PAGE now persists an explicit null as a winning page-register tuple
  and materializes the current note fallback. NOTE_BUNDLE replays metadata and
  content before final page-background materialization so a clear in the same
  bundle cannot resolve through an obsolete fallback.
- Renderer, editor invalidation, thumbnails and revision signatures resolve
  page background through the note fallback. Harmony packages contain no
  original CRDT history, so export writes the resolved appearance to preserve
  the visible result on re-import.

## Verification

- `d02-note-background-fallback.mjs` covers v49-to-v50 preservation, note LWW,
  stale updates, nullable page winners, the 612x792 default and static
  renderer/export/bundle contracts.
- ArkTS tests compile real FlatBuffer fixtures for background value, explicit
  null and combined title/background SET_METADATA payloads, plus schema and
  fallback model assertions.
- All Node/SQLite replays pass with `TOTAL=57 FAILED=0`. After `hvigor clean`,
  both `note@ohosTest` and `note@default` assembleHap builds succeed. Device
  Hypium was not executed.

## Phase 244 local-outbound closure

ADR-0221 now routes the active paper size/template/orientation UI through original payload type 1
`SET_METADATA.pageBackground`. The local writer preserves the present-wrapper/null-value distinction, calls the same
production reducer, rematerializes only page-register-null pages, and appends the upload row plus durable-history companion
atomically. Durable history stores both the effective Letter fallback and the exact nullable register value, so Undo from a
previous null winner emits `SetPageBackground(null)` exactly as original `vnf` does.

Normal local `CREATE_PAGE` now leaves its page background null and materializes from the current note winner. This preserves
future inheritance instead of copying the current note background into a page-level register. Full evidence and the local
transaction decision are recorded in ADR-0221 and
`docs/migration/evidence/original-local-set-metadata-background-outbound-jadx-2026-08-16.md`.

## Remaining boundary

At the time this ADR was first accepted, an explicit null title was still deferred because Harmony stored a
non-null materialized title and the original display fallback had not yet been
proved. That historical boundary is superseded by ADR-0249/Phase 271, which closes the title register/wire/history
chain while retaining the non-null materialized projection. ADR-0248/Phase 270 has closed inbound decode, validation, independent
LWW persistence and validated readback for handwriting language, text alignment,
default font family/size, layout mode and block wrapping; these fields no longer
remain generically deferred. Their Harmony UI/renderer/recognition consumers,
local outbound writers, round-trip and device behavior remain open. Note/page PDF
decode, fallback, asset loading and local paper-setting preservation are implemented;
their remaining boundary is device pixel comparison and multi-device sync.

## Phase 245 local-title outbound closure

ADR-0222 now routes local title editing through original payload type 1 `SET_METADATA.title`. The writer emits
`l2d.field0 → z2d.field0` while leaving `l2d.field1` absent; the reducer consequently treats title and background as
independent field patches and no longer defers a normal title-only operation or mistakes the absent background field for an
explicit-null reset. The same transaction updates the title winner, `note_meta`, title search row, monotonic `updated_at`,
upload row and NTL1 durable-history companion.

At the time of Phase 245, an explicit-null title wrapper remained deferred: the proven editor path converted exact empty
input to `New Note` and never emitted null. Phase 271 supersedes that boundary for inbound, persistence, outbound Undo/Redo
and durable history; the editor's concrete empty-submit policy remains unchanged. The separate new-note bootstrap path can
still combine title and background, but its full creation ordering remains a follow-up boundary rather than part of ADR-0222.

## Phase 270 additional metadata inbound closure

ADR-0248 now decodes SET_METADATA fields 2～7 with their original presence rules and persists each field in an independent
v65 winner table. Handwriting preserves wrapper-present/null-value, scalar false/zero values preserve vtable presence, stale
fields are no-ops and a mixed operation advances `structure_revision` only once. Same-identity/different-value remains a
Harmony integrity conflict.

Phase 270 also moves note-level PDF asset merging after all identity decisions and executes it only when the background
register wins. This prevents a stale PDF patch or a later metadata conflict from attaching an asset before the inbox commits
its deferred state. The six values now have validated SQL readback; Phase 272 adds original local outbound and atomic upload,
and Phase 273 adds NMD1 durable history with source-checked Undo/Redo. PAGELESS layout, line alignment, handwriting provider,
default-font inheritance and wrap behavior remain follow-up consumer work.

## Phase 271 explicit-null title closure

ADR-0249 now preserves the original title register's wrapper-present/inner-null state. The v66 title winner table is
nullable, the reducer writes null winners and projects them to an empty non-null `note_meta`/search value, and NTL2
history preserves nullable before/after values while continuing to decode NTL1. This closes the title register/wire/history
gap without changing the six Phase 270 consumer boundaries or the combined new-note bootstrap ordering boundary.
