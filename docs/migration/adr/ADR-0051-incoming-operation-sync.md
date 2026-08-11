# ADR-0051: Durable incoming operation replay precedes receive acknowledgement

## Status

Accepted, 2026-08-11.

## Evidence

- Original `vt9.java` defines `OpsBundle(ops, schemaVersion)`. Original
  `zgb.java` defines `ReceiveOpsEvent(ops, expectedAckReply, schemaVersion)`,
  where `expectedAckReply` is a required string.
- Both vectors contain the same `uq9` operation table. `uq9.java` carries the
  inline operation ID, client time, server time, payload discriminator and
  payload table; there is no transport-specific reducer format.
- Original `kx.java` parses a socket byte array as `zgb`. An empty event is
  acknowledged immediately. A non-empty event is first sent into the bounded
  receive channel.
- Original `kb9.java` invokes the model callback for a coalesced list of
  `zgb` events and only after that callback returns iterates the events and
  emits each required ACK reply. Parse success alone is not an ACK boundary.
- Harmony previously had a durable `SyncedOperationInboxStore`, a complete
  supported-operation reducer and durable storage for `OPS_BUNDLE` and
  `RECEIVE_OPS_EVENT`, but no component connected them.

## Decision

- Decode the two original roots according to their exact field numbers and
  uint16 schema version. Do not introduce an endpoint, authentication token or
  guessed wire envelope.
- Preserve every nested `uq9` byte-for-byte. A copied bundle buffer changes
  only its four-byte FlatBuffer root offset to point at that nested table, so
  all existing envelope and payload validators consume the original bytes.
  Reject the vector before copying when the aggregate re-root allocation would
  exceed the existing 128 MiB incoming-batch budget.
- `IncomingOperationSyncCoordinator` serializes one note session, commits the
  decoded batch through `receiveBatch()`, and then drains `processHead()` in
  server/client order until EMPTY or a durable DEFERRED head blocks progress.
- Deliver `expectedAckReply` only after that durable boundary. A parse,
  persistence or reducer exception sends no ACK. Exact server retry is safe
  because inbox identity, metadata and bytes must all match.
- Match the original empty-event branch: validate its required reply and ACK it
  immediately without attempting to drain unrelated older inbox state.
- Replay stored `OPS_BUNDLE` and `RECEIVE_OPS_EVENT` through the same path.
  Revalidate stored length, CRC32, type and FlatBuffer root, and require the
  row schema version to equal the payload schema version. `NOTE_BUNDLE` remains
  in its dedicated page-identity/content transaction.

## Verification

- `d02-incoming-operation-sync.mjs` parses handcrafted original-layout `zgb`
  and `vt9` fixtures, re-roots their nested `uq9`, and covers ACK after drain,
  exact retry, durable deferred blocking and no ACK on failure.
- `IncomingOperationSyncCoordinator.test.ets` is registered in the Hypium
  suite and compiles in the actual `note@ohosTest` target. It covers field
  decoding, receive/process/ACK order and failure suppression.
- All desktop replays pass with `TOTAL=60 FAILED=0`. Clean `note@ohosTest` and
  `note@default` HAP builds complete successfully.

## Remaining Boundary

The coordinator is transport-independent by design. A private authenticated
socket adapter, server note/site creation and device execution against the
real service still require verified credentials and protocol evidence. Device
acceptance must also exercise reconnect during receive, duplicate delivery,
unsupported payload deferral and ACK emission after process restart.
