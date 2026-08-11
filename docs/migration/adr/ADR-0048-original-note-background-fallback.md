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
  metadata fields remain deferred atomically. Title and background each use
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

## Remaining boundary

An explicit null title is still deferred because Harmony currently stores a
non-null materialized title and the original display fallback has not yet been
proved. SET_METADATA fields for handwriting language, text alignment, default
font, layout mode and block wrapping also remain deferred. Full PDF background
support is the next independent D-02 batch: it must preserve asset metadata,
layout behavior, total and consumed page counts, page offset and per-page crop
boxes before note/page PDF fallback can be declared compatible.
