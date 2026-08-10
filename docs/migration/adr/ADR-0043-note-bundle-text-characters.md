# ADR-0043: NOTE_BUNDLE reuses the standalone Text character reducers

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java:20-24` maps `e46`,
  `f46`, `pub`, `qub` and `f2c` to `INSERT_CHAR`, `INSERT_STRING`,
  `REMOVE_CHAR`, `REMOVE_CHARS` and `REVIVE_CHARS` respectively.
- The standalone reducers already decode their FlatBuffer contracts, maintain
  the original SeqId character tree, apply visibility as an operation-identity
  LWW register, rematerialize RichText/style ranges, and update live or archived
  page revisions and search state.
- NOTE_BUNDLE stores the same payloads as nested tables in operation-vector
  order, so decoding them as independent root buffers would be incorrect.

## Decision

- Expose table-level decoders, preflight and apply entry points for all five
  Text character payload types. Standalone and NOTE_BUNDLE paths enter the same
  reducers after decoding.
- Preflight every nested child before bundle writes, then apply children in
  operation-vector order inside the existing inbox transaction. This permits
  an INSERT to target a Text block created earlier in the same bundle and makes
  any runtime target/state divergence roll back the entire bundle.
- Treat one INSERT operation identity as the identity of its complete scalar
  sequence. Query the whole note for persisted `(timestamp, site)` characters;
  only an exact match of block, index set, parent chain and Unicode scalars is
  an idempotent retry. Partial sequences, changed values and reuse in another
  Text block are identity conflicts.
- For REMOVE/REVIVE, an older winner remains a normal LWW no-op. An equal
  winner with the same visibility is an idempotent no-op without a revision
  increment; an equal winner with opposite visibility is an identity conflict.

## Verification

- ArkTS fixtures decode and preflight nested INSERT_STRING, REMOVE_CHARS and
  REVIVE_CHARS children after a CREATE_BLOCK child, including the Unicode
  scalars `U+0041` and `U+1F600` and the generated SeqId locations.
- `d02-note-bundle-text-characters.mjs` covers all five payload types, Unicode
  and parent chaining, exact retry, two INSERT identity conflicts, visibility
  conflict, stale no-op, archived Text, malformed zero-write, runtime-deferred
  rollback and injected all-or-nothing rollback.
- The older `d02-text-visibility.mjs` source guards now lock the strict equal
  winner branch instead of accepting the former `>= 0` overwrite rule.
- All Node/SQLite replays pass: `TOTAL=52 FAILED=0`.
- After `hvigor clean`, both `note@default` and `note@ohosTest` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

NOTE_BUNDLE character/paragraph style and clear-style children remain deferred.
Delete-before-create and hidden-entity modification, Tape/effects, PDF
background, private authentication transport and server-side note/site creation
also remain separate work; D-02 is not closed.
