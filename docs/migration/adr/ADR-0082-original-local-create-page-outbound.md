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
- A missing `nz9` background materializes the original Letter default, 215.9 x 279.4 mm. A local
  A4 page therefore must carry `nz9.sourceSize`; silently omitting it changes document geometry.
- The existing Harmony add path generated an unrelated random page ID and only journaled NPG
  history. Appending original payload bytes afterward would create a second logical page instead
  of assigning the local page the original operation identity.

## Decision

- Encode local CREATE_PAGE directly as the original FlatBuffer. Root pages omit location and
  background and retain the original Letter default. Plain non-root pages encode exact dimensions
  in `nz9.sourceSize` and anchor to the winning position of the current visible tail page.
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
- Omit an A4 background because a blank page looks similar: the original decoder defaults to
  Letter, producing a measurable cross-device geometry divergence.
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

Local MODIFY_PAGE/reorder is now implemented by ADR-0220. Legacy-note identity bootstrap, styled
paper/PDF CREATE_PAGE authoring, and private transport/ACK acceptance remain separate work. CREATE_INK may now
use canonical page identities for newly created aligned notes, but must still preallocate the ink
operation identity before replacing random stroke IDs. No device was started in this phase.

## Phase 110 Correction

The Phase 105 writer encoded the correct CREATE_PAGE/DELETE_ENTITIES payload child tables, but
passed those children directly to reducers that require a complete `uq9` operation envelope. It
therefore did not establish the claimed runtime production path. Phase 110 wraps the child in the
original seven-field operation table before reducer application and journals that same complete
operation. The identity, transaction, history and eligibility decisions above remain valid; their
production closure is verified from Phase 110 onward.
