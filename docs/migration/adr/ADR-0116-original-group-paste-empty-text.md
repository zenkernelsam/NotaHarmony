# ADR-0116: Preserve empty Text blocks in original Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 type-22 CREATE_BLOCK has no text-content field. A TEXT block is valid with only the
  required page, origin and size plus common block state; RichText is a separate CRDT entity.
- Original `f46.a()` rejects a type-8 INSERT_STRING whose string length is zero. Therefore an empty
  Text block is represented by CREATE_BLOCK alone, not by a fabricated empty INSERT_STRING.
- This is consistent with original replacement behavior recorded by ADR-0105: removing every
  character preserves the Text block identity with empty RichText.

## Decision

- Admit an empty Text leaf during Group Paste preflight after validating its CREATE_BLOCK. Validate
  and write initial INSERT_STRING only when `richText.length > 0`; whitespace-only content remains
  non-empty and is preserved exactly.
- Empty and non-empty Text share the same page-order identity, revision batch, Group graph and NCP1
  transaction. Empty Text simply allocates no second insertion identity and writes no type-8 journal
  row. Failure in CREATE_BLOCK, Group or NCP1 still rolls back the complete action.
- Rebuild every pasted plain Text from the decoded CREATE_BLOCK payload, not the higher-precision
  clipboard preview. Canonical Text uses `textOrigin=(0,0)` with the decoded world origin and float32
  geometry, while retaining the new local creation metadata and exact RichText string.

## Rejected Alternatives

- Encode an empty INSERT_STRING: both the original validator and Harmony's strict writer reject it.
- Drop empty Text from the Group: that changes member identities, layout and later edit behavior.
- Keep the preview geometry in the final snapshot: this can diverge from the float32 CREATE baseline
  used by later original MODIFY_BLOCK operations.

## Verification

- `StrokePersistence.test.ets` admits an empty Text alongside Image and Math in a valid Group plan.
- `d02-original-group-paste-empty-text.mjs` locks CREATE-only empty behavior, conditional non-empty
  INSERT_STRING, canonical materialization and rollback.
- Full desktop replay passes with `TOTAL=125 FAILED=0`. After `hvigorw clean`, both `note@ohosTest`
  and `note@default` HAP builds succeed. No emulator, VM, device or Hypium is used.

## Remaining Boundary

Text common Block state and character/paragraph style replay remain gated by the strict local encoder,
and Shape RichText remains unsupported in Group Paste. These require their original CREATE/MODIFY and
RichText operation sequences rather than snapshot substitution.
