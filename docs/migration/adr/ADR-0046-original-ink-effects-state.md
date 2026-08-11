# ADR-0046: Preserve original Ink effects as independent CRDT state

## Status

Accepted, 2026-08-11.

## Evidence

- Original `dm2.java` stores CREATE_INK effects and tinted values in fields 18
  and 19. `wd8.java` stores MODIFY_INK effects and tinted setters in fields 17
  and 18.
- Original `q06.java:591-592` applies MODIFY effects and tinted through two
  independent LWW registers. They must not be validated as one atomic pair.
- Original `k06.java:19-21` defines `RAINBOW=1` and `GLITTER=2`; the wire value
  remains a uint64 bitmask, so unknown future bits must survive unchanged.
- Original `s06.java` materializes the bitmask, tinted flag and phase. `l06.java`
  names the phase as `phaseOffsetPx`; its source is the first current style-map
  entry's `backingDashPhase`.
- The decompiled Java layer does not contain an equivalent RAINBOW/GLITTER
  shader. Final coloring is delegated to the original WetMirror/native brush
  engine. Inventing a Harmony gradient or particle shader would not be an
  evidence-based port.

## Decision

- Database v48 adds the CREATE baseline and independent value/winner/presence
  columns for effects and tinted. uint64 values are canonical decimal strings,
  preserving all 64 bits beyond JavaScript's safe integer range. Fresh schema
  checks register presence/value consistency; migrated rows default to
  effects=0, tinted=true, and application reads reject inconsistent registers.
- `RenderSpec` carries optional `inkEffects`, `inkEffectsTinted` and
  `inkEffectPhase`. Persistence, package validation, clipboard cloning and the
  editor's Undo/persistent-history snapshot clone retain them. Optional fields
  keep pre-v48 snapshots readable.
- CREATE_INK accepts nonzero effects only for Pen and Highlighter, rejects
  effects=0 with tinted=false, and stores baseline plus materialized metadata.
  Exact retry verifies the CREATE baseline and the unique live/archived/hidden
  payload against the current winning effects, tinted and style-map phase. A
  retry arriving after a legitimate MODIFY remains idempotent.
- MODIFY_INK decodes fields 17 and 18 as independent registers. Stale values are
  no-ops, timestamp ties use site id, and equal identity with a different value
  is a conflict. A legal operation order may materialize effects=0 and
  tinted=false, so CREATE's pair validation is intentionally not reused.
- Style-map replacement updates the materialized effect phase. An explicit
  phase inconsistent with the old style-map is rejected as divergent; an
  absent phase from a pre-v48 payload is allowed once and then materialized.
- Hidden entities use the same reducer and update their archived payload without
  advancing visible page revision. Tape field 16 remains explicitly deferred.
- This phase does not claim visual RAINBOW/GLITTER equivalence. It completes the
  lossless data, CRDT and restart boundary needed by a future equivalent brush
  engine without substituting an approximate shader.

## Verification

- `d02-original-ink-effects.mjs` covers real FlatBuffer fields 18/19 and 17/18,
  uint64 max, RAINBOW/GLITTER/combined and unknown bits, v47-to-v48 defaults,
  CREATE retry/conflict and tool validation, independent LWW registers, site
  tie breaking, stale no-op, legal effects=0/tinted=false, hidden mutation,
  style phase, Tape defer, multi-Ink atomicity and transaction rollback.
- `NotePackageSpec.test.ets`, `StrokeClipboard.test.ets` and
  `StrokePersistence.test.ets` cover uint64 validation and effects metadata
  round-trip/copy behavior. `DatabaseHelper.test.ets` locks v48 schema and
  migration fields. Device Hypium was not executed.
- All Node/SQLite replays pass: `TOTAL=55 FAILED=0`.
- Incremental `note@ohosTest` and `note@default` assembleHap builds succeed.
  Final clean builds are recorded in the phase report.

## Remaining boundary

Tape has a complete original Java Canvas renderer in `qfe.java` and nine wire
patterns in `ife.java`; it is the next model/persistence/renderer batch. PDF
background, private authentication transport and server-side note/site creation
also remain separate work. D-02 is not closed.
