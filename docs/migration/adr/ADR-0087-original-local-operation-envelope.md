# ADR-0087: Preserve complete original local operation envelopes

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `zq9.e` writes the seven-field `uq9` operation: required operation identity,
  clientTime, nullable serverTime, nullable audioTime, payload discriminator, payload table and
  nullable transient-interaction metadata. `zq9.a` creates a local operation with serverTime absent,
  not an explicit zero, because no server has accepted it yet.
- `uq9.q` follows field 5 to the typed payload table. A standalone `ln2`, `dm2`, `gd`, `wd8`, `s83`
  or `yn2` root buffer is therefore not interchangeable with a complete operation.
- `wq9` classifies payload types 26 and 29 as transient by default and treats an explicit
  `_inProgressTransientId` as part of the same transient interaction. `kt1.d` starts Ink with a
  transient CREATE_INK; `kt1.c` emits actual/estimated ADD_PATH_ELEMENTS against that active Ink.
- `oqi.a` creates TRANSIENT_INTERACTION_ENDED for an interaction identity. The normal finish chain
  later builds a complete durable CREATE_INK and appends transient cleanup; transient path chunks
  do not become durable model journal entries.

## Problem

Phases 98-109 introduced correct original payload encoders, but several local producers assigned
the payload child buffer directly to `StoredSyncedOperation.rawOperation`. Production decoders call
`readOriginalPayloadTable`, which expects field 4/5 of a complete `uq9`, so page and Ink reducers
deferred before their claimed journal transactions. Any child table already present in a local
original operation row would also be unreadable by later envelope consumers.

## Decision

- Add one complete-operation encoder. It copies the payload root buffer without rewriting its
  table or vtable and points outer field 5 directly at the copied child table. It validates operation
  identity, unsigned times, discriminator range, payload root and transient identity before writing.
- Distinguish a generic original operation envelope from a synced envelope. Local outbound bytes
  omit nullable serverTime exactly like `zq9.a`; incoming synced validation continues to require the
  field and rejects unsynchronized local bytes at the transport-independent inbox boundary.
- Page CREATE/visibility, Ink CREATE/visibility/style and Recording CREATE/delete now apply and
  journal the same complete operation bytes. Payload child bytes remain an internal encoder result,
  never an `operation_log.payload` value.
- At database initialization, before operation audio-time backfill, scan only local
  CREATE_RECORDING. Phase 98 could materialize that payload directly and then journal its child;
  the later page/Ink reducers deferred before append, so no other legacy child row can have
  committed. Validate a candidate child with the CREATE_RECORDING schema decoder before wrapping.
  A valid complete envelope must agree with row identity, clientTime, payload type, nullable
  audioTime and absent/zero serverTime. Metadata conflict or concurrent disappearance aborts the
  surrounding initialization transaction. Read and close the cursor before updating its source table.
- Add original type-16 ADD_PATH_ELEMENTS and type-26 interaction-end payload writers. Path appends
  use version 0 attributed BITS_32 elements and never include MOVE; actual and estimated are
  independently nullable but not both absent. These writers do not by themselves claim real-time
  collaboration: Harmony has no authenticated transient sink/transport contract yet, and writing
  preview chunks into the durable operation log would contradict the original finish lifecycle.

## Rejected Alternatives

- Teach every reducer to accept both a payload child and a complete operation: that hides malformed
  journal data and makes metadata/typed payload consistency unverifiable.
- Store the child but reconstruct an envelope only during upload: restart, audio-time readers and
  any local replay still see invalid data, while nullable transient/audio metadata can be lost.
- Write an explicit local serverTime of zero: original `zq9.a` omits the nullable field; zero is a
  decoded default, not proof of server acceptance.
- Persist transient ADD_PATH_ELEMENTS in `operation_log`: original normal completion replaces the
  preview with a full durable CREATE_INK and separately ends the interaction.

## Verification

- ArkTS tests round-trip complete page, Ink, delete, modify, type-16 actual/estimated and line-only
  appends, durable/transient metadata, and type-26 replacement identity through production decoders.
- `d02-local-operation-envelope.mjs` independently parses root/vtable/payload pointers and simulates
  child repair, complete-envelope idempotency, audioTime preservation and metadata conflict refusal.
- Full replay and clean sequential HAP results are recorded in the Phase 110 report.

## Remaining Boundary

No authenticated transient sink, upload adapter or ACK consumer exists yet. Touch move/up/cancel
must be connected only after that ownership contract is explicit. Local center-path replacement,
selected Ink color/width, Shape/Group outbound, remaining format work and device verification also
remain separate phases. No emulator, VM, device or Hypium run is part of this decision.
