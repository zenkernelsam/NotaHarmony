# ADR-0082: Give locally created pages original sequence identities

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `haa` assigns payload type 3 to CREATE_PAGE. `ln2` reads four fields:
  nullable `cxc location`, nullable `nz9 background`, uint32 `pageCount` defaulting to 1, and
  bookmark enum defaulting to UNBOOKMARKED.
- Original `haj.a/c()` writes the same four fields. `cxc` is the 12-byte inline SeqId layout
  `site:uint16, padding, timestamp:uint32, index:uint32`.
- Original page identity is `(CREATE_PAGE.timestamp, siteId, indexWithinPayload)`. A later page
  insertion references a position SeqId, not a storage UUID or `page_index`.
- A missing page-level `nz9` leaves the page register null. Its effective value resolves through the
  note `pageBackgroundRegister`, whose terminal null fallback is Letter 215.9 x 279.4 mm. A normal
  local A4 note therefore writes A4 through `SET_METADATA`, not by freezing A4 into every CREATE_PAGE.
- The existing Harmony add path generated an unrelated random page ID and only journaled NPG
  history. Appending original payload bytes afterward would create a second logical page instead
  of assigning the local page the original operation identity.

## Decision

- Encode local CREATE_PAGE directly as the original FlatBuffer. Normal authoring pages omit the
  page-level background and inherit the current note winner; root pages omit location, while
  appended pages anchor to the winning position of the current visible tail page. Explicit
  per-page backgrounds remain for imported/protocol operations that actually carry that setter.
- Allocate the operation identity before materialization and let
  `OriginalCreatePageOperationApplier` create the canonical storage page ID. Return that assigned
  ID to `NotePage` and rewrite the in-memory AddPage action before it enters Undo history.
- Run page creation, reducer application, outbound append and local history companion in one SQLite
  transaction under the shared editor persistence mutex. A reducer defer or append failure rolls
  back the identity clock, page/order rows, operation log and history row together.
- Use original DELETE_ENTITIES page vectors for delete and undelete. ADD_PAGE undo/redo and
  DELETE_PAGE undo/redo therefore retain the same page sequence identity and reuse the reducer's
  complete page/content/search archive rather than creating a replacement page.
- Keep the NPG structure mutation only as a local persistent-history companion. Known original
  outbound companion rows are transparent to `PersistentHistory`; they must not act as legacy
  barriers that clear the user's recoverable Undo stack.
- Importers call a distinct materialization entry point and never emit fresh original CREATE_PAGE
  operations for pages already represented by an imported package.
- Enter the original path only when every live page has an original identity and stored visible
  order equals original CRDT visible order. Mixed legacy/reordered notes retain the prior local path
  until their identity/order operations are migrated; the app must not guess an anchor.

## Rejected Alternatives

- Reuse the caller's random page ID as the original identity: storage IDs are not wire identities,
  and CREATE_INK would still be unable to reference the page SeqId.
- Anchor with the largest `page_index` identity: after MODIFY_POSITIONS the winning position can
  differ from the page's stable identity.
- Omit both note-level A4 metadata and page-level background: only then does the terminal Letter
  fallback apply, producing a measurable cross-device geometry divergence. A normal new page
  should omit its own background only after the note-level A4 winner exists.
- Run original CREATE_PAGE for import loops: this would upload duplicate authoring operations and
  replace package page IDs.
- Treat original companion rows as untracked legacy edits: recording/page outbound traffic would
  repeatedly erase persistent Undo history.

## Verification

- `OriginalCreatePagePayloadEncoder.test.ets` covers implicit Letter defaults, located A4
  `sourceSize`, and page delete/undelete vector round trips.
- `PersistentHistory.test.ets` locks original outbound companion transparency.
- `d02-local-create-page-outbound.mjs` checks original `ln2/haj/cxc` evidence, production wiring,
  moved-tail winner anchoring, canonical identity, delete/undelete and injected rollback.
- All desktop replays pass with `TOTAL=91 FAILED=0`. Clean sequential HAP build results are recorded
  in the Phase 105 report.

## Remaining Boundary

Local MODIFY_PAGE/reorder is now implemented by ADR-0220, and local note paper settings plus normal
CREATE_PAGE inheritance are implemented by ADR-0221. Legacy-note identity bootstrap, explicit
page-level styled/PDF CREATE_PAGE authoring, and private transport/ACK acceptance remain separate work. CREATE_INK may now
use canonical page identities for newly created aligned notes, but must still preallocate the ink
operation identity before replacing random stroke IDs. No device was started in this phase.

## Phase 110 Correction

The Phase 105 writer encoded the correct CREATE_PAGE/DELETE_ENTITIES payload child tables, but
passed those children directly to reducers that require a complete `uq9` operation envelope. It
therefore did not establish the claimed runtime production path. Phase 110 wraps the child in the
original seven-field operation table before reducer application and journals that same complete
operation. The identity, transaction, history and eligibility decisions above remain valid; their
production closure is verified from Phase 110 onward.

## Phase 244 Correction

The Phase 105 decision treated a missing CREATE_PAGE background as always selecting Letter. That is
only the terminal fallback when the note register is null. Original paper UI updates the note via
`SET_METADATA.pageBackground`; ordinary pages keep a null page register and inherit it. Phase 244
therefore changed local normal CREATE_PAGE to omit `nz9`, let the production reducer materialize the
current effective note dimensions, and retain `background_json = NULL` for future inheritance.

## Phase 246 Correction

Phase 105 also assumed ordinary blank-note creation used one implicit page. `id7.d()` plus APK DEX now
prove that the original bootstrap emits an ordered combined `SET_METADATA` followed by one
`CREATE_PAGE(location=null, background=null, pageCount=2)`. Phase 246 therefore keeps the decisions
above for interactive one-page additions, but supersedes the initial-note special case: both initial
pages share one CREATE_PAGE identity with payload indexes 0 and 1, inherit the note winner, and are
committed atomically before the editor opens. See ADR-0223.
