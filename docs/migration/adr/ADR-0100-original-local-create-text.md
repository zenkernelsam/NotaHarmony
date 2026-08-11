# ADR-0100: Persist original local Text creation

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `haa` assigns payload type 22 to `CREATE_BLOCK` and type 8 to
  `INSERT_STRING`; `zq9` maps them to `rl2` and `f46` respectively.
- `baj.d()` writes the 21-field `rl2` table. A Text CREATE carries Block type, page identity,
  origin, optional rotation/scale, size and common Block defaults, but not the RichText body.
- `kci.b()` writes `f46` with nullable location, required UTF-8 string and nullable Text Block
  identity. `f46.a()` rejects an empty string. `e4c` materializes INSERT_STRING by Unicode code
  point and derives character identities from the INSERT operation plus scalar index.
- The original creation flow receives the successful CREATE_BLOCK identity before opening its
  editor. Initial committed text therefore remains a separate RichText operation targeting the
  immutable CREATE identity.

## Decision

- Reserve one canonical original operation identity before authoring a local Text Block. Use it as
  the element identity with original defaults: 17 pt black, margins top/left 3/5 and absent
  bottom/right defaults 10/5, square corner, pixel-aligned wrap, no paper, caption, resize-to-fit
  or position lock.
- Encode type-22 as an empty Text container and the non-empty initial body as root type-8 with an
  explicit Block target. Reject malformed Unicode, empty or over-budget strings, non-finite
  geometry, shear/perspective and every state the original pair cannot represent without loss.
- Apply both payloads through production reducers and append two upload-immediate rows. CREATE is
  the element identity; INSERT_STRING receives a new identity and creates Unicode-scalar character
  identities.
- Treat both rows as transparent history companions. The existing add-element history is one user
  command; Undo/Redo uses type-25 delete/undelete and restores the same Block identity.

## Revision And Atomicity

- Both reducers materialize snapshot rows at `N+1` but share one `OriginalPageMutationBatch`.
  Neither advances the page independently in this path; the batch flushes exactly `N` to `N+1`.
- The canonical page mutation remains one step. Relaxing `toRevision = fromRevision + 1` or using
  `N+2` for one UI command is explicitly rejected.
- Page validation, both reducers and journals, revision flush, state check, snapshot/search
  reconciliation and history companion run in one transaction. Any failure rolls back everything.
- Cancelling an empty draft consumes no page mutation and requests a fresh reservation; successful
  commit rearms reservation only after the queued save flushes.

## Verification And Boundary

- `OriginalCreateTextPayloadEncoder.test.ets` covers both payload round trips, Unicode scalars,
  strict rejection and the two-record/one-flush revision batch.
- `d02-local-create-text.mjs` locks original writer evidence and replays empty CREATE_BLOCK,
  Unicode INSERT_STRING, two immediate journals, one revision, identity-preserving Undo/Redo and
  reducer/journal/history rollback.
- Production reachability exposed legacy ArkTS-incompatible dynamic style-state helpers. They now
  use named types and explicit field reconstruction, preserving true nullable-property removal
  without `delete`, structural typing or empty style runs.
- This closes only new Text creation with one initial whole-string insertion. Editing existing Text
  still needs local INSERT/REMOVE/REVIVE and style writers. Image/Math CREATE_BLOCK,
  Group-preserving clipboard/package, complete package round trip and private transport/ACK remain.
