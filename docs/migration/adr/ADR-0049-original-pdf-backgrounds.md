# ADR-0049: Restore original PDF backgrounds and independent pageInAsset state

## Status

Accepted, 2026-08-11.

## Evidence

- Original `sw9.java` exposes required `wa0` metadata, `xw9` layout behavior,
  total page count, pages consumed, page offset and an eight-byte crop-box
  vector. Its defaults are layout value 2, page counts 1 and offset 0.
- Original `wa0.java` requires the asset hash, file name and MIME fields. Its
  validator rejects an unsigned zero file size and empty file name or MIME.
  `xw9.java` fixes the wire values at 0, 1 and 2.
- Original `ddg.java:95-122` requires positive total/consumed counts, one crop
  box per consumed page and an unsigned `offset + consumed <= total` range.
- Original `wz9.java` stores background and pageInAsset in separate CRDT
  registers. CREATE construction in `v69.java` initializes each page from
  `pdf.pageOffset + pageIndex`; pages without a PDF still receive their own
  sequence index. `wz9.u()` resolves the register and slices a page to one
  consumed PDF page.
- Original `ya0.java` resolves a missing page PDF through the note background.
  Renderer-facing `gba/hba/ko8` state groups work by asset, resolved page index
  and rotation. No renderer-side use of the layout enum was found, so enum
  names alone are not evidence for a new Harmony crop algorithm.

## Decision

- Page background schema v2 preserves the complete PDF asset: eight uint64
  hash words, file metadata, layout enum, total/consumed counts, offset, crop
  boxes and the resolved page index. The shared asset decoder is also used by
  IMAGE blocks so the 64-byte hash contract has one implementation.
- Database v51 adds an independent `original_page_in_asset_winner` and
  materialized page/checkpoint/archive columns. v50 stores backfill every
  original identity from its sequence index and create-time operation ID;
  local Harmony pages remain null. Missing create-time background winners are
  also restored so later LWW comparisons are deterministic.
- CREATE_PAGE initializes background and pageInAsset winners independently.
  MODIFY_PAGE updates pageInAsset only when its PDF setter wins that register;
  setting paper or null never clears it. NOTE_BUNDLE replays the same two LWW
  streams and materializes note-level PDF fallback only after metadata replay.
- PDF references use the existing canonical 64-byte storage hash while still
  accepting the legacy colon key. Metadata conflicts and incompatible local
  paths defer the enclosing synced transaction without partial page writes.
- Harmony PDF rendering uses `@kit.PDFKit`, verifies metadata and document page
  count, renders the resolved page to PixelMap/ImageBitmap, and releases the
  document and pixel resources. Editor and thumbnail paths share the loader;
  generation guards discard late page results and asset arrival refreshes a
  pending PDF. A failed PDF keeps the normal paper fallback and does not block
  opening the note.
- `.note` packages now carry both IMAGE and PDF binaries through a shared
  original-asset path. `originalPageInAsset` is optional for old packages;
  import recovers it from an old effective PDF background when absent. NPG3
  preserves it in local page undo/redo history while NPG1/NPG2 remain readable.
- Layout behavior is stored losslessly but is not reinterpreted from enum names.
  Rendering follows the proven page size, margins and cardinal rotation data.

## Verification

- Real ArkTS FlatBuffer fixtures cover CREATE_PAGE, MODIFY_PAGE and
  SET_METADATA PDF values, including a 64-byte hash, uint64 max word, two crop
  boxes and multi-page offsets.
- `d02-pdf-background.mjs` covers v50-to-v51 live/archive backfill, local null
  state, background-winner repair, independent pageInAsset LWW, identity
  conflict and migration rollback. All desktop replays pass with
  `TOTAL=58 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` assembleHap
  builds completed with `BUILD SUCCESSFUL`. No emulator, device or Hypium
  execution was performed.

## Remaining Boundary

Device acceptance must compare real PDF pixels for all four rotations,
non-zero margins, mixed crop boxes, missing/pending/corrupt assets, rapid page
switching and thumbnail refresh. Layout enum behavior stays evidence-gated
until an original runtime comparison proves additional rendering semantics.
