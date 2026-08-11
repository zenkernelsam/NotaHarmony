# ADR-0057: Coalesce original peer interactions outside the durable model

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload type 29 is `PEER_INTERACTION` and is transient by default. Its root field-6
  interaction ID is the operation's own ID.
- `yda` payload field 0 is an optional inline cursor point, fields 1 and 2 currently have no writer
  or consumer, field 3 is the selected entity operation-ID vector, field 4 is the tool enum, field 5
  is an optional `qqe` text selection, and field 6 is `recordingInProgress`.
- `qqe` fields 0 and 1 are optional inline `cxc` sequence IDs. The generated tool reader maps an
  unknown enum byte to `POINTER`; the generated boolean reader treats every non-zero byte as true.
- Before durable `v69` model replay, original `mzc` extracts all type-29 operations, ignores the
  local site, clears its per-batch temporary map and retains only the last raw operation for each
  remote site. If conversion of that last raw operation fails, the site receives no update for the
  batch; an earlier valid operation is not restored.
- For an existing peer, a null cursor in the winning payload inherits the cursor from before the
  batch. Peer state is memory-only. The original branch catches malformed conversion and continues
  unrelated durable model replay.

## Decision

- Add a strict type-29 decoder. Require root field-6 metadata to match the root operation ID; reject
  reserved payload fields, unknown extensions, invalid identities and non-finite cursor values.
  Bound the selected-ID vector at 10,000 entries and preserve original Set deduplication, unknown
  tool fallback and non-zero boolean behavior.
- Add a note/site-scoped `OriginalPeerInteractionStore` with defensive copies and old-cursor
  inheritance. Ignore the validated local site and intentionally provide no database or restart
  restoration path.
- Coalesce the complete incoming batch before durable reducer replay: retain the last raw type-29
  operation per remote site and decode only that operation. A malformed winner increments the
  discarded count, leaves prior peer state unchanged and does not fall back within the batch.
- Keep type 29 in the durable inbox as a consumed zero-model-write operation. This preserves raw-byte
  retry identity, ordering and server-time cursor progress. Malformed peer UI data is discarded as in
  `mzc`, rather than becoming a deferred head that blocks later durable operations.
- Validate `localSiteId` when the production coordinator is created. Keep NOTE_BUNDLE transient
  rejection because bootstrap/history replay must not restore ephemeral presence.

## Verification

- ArkTS fixtures cover the complete payload, duplicate selected IDs, generated-reader fallbacks,
  malformed metadata/reserved/unknown fields, note/site isolation, local-site exclusion, defensive
  storage, pre-batch cursor inheritance, same-site last-wins, malformed-last discard and zero model
  writes.
- `d02-peer-interaction.mjs` covers batch semantics, restart loss, inbox/cursor continuation, source
  routing guards and the unchanged NOTE_BUNDLE boundary.
- All desktop replays pass with `TOTAL=66 FAILED=0`. Clean HAP build results are recorded in the
  Phase 79 report.

## Remaining Boundary

This decision supplies production decoding, batching and pending peer state, but not a complete
collaboration-presence UI. The original roster/display-name/color consumer and its 45-second presence
and 10-second recording expiry behavior still require a later evidence-backed integration. No claim
is made that remote cursors or recording indicators are already rendered.
