# ADR-0039: NOTE_BUNDLE MODIFY_INK reuses the standalone reducer

## Status

Accepted, 2026-08-11.

## Evidence

- Original `decompiled_1.0.3/sources/defpackage/zq9.java` maps `wd8` to
  `haa.MODIFY_INK`; `wd8.java` is the 19-field payload already decoded by the
  standalone type-17 reducer.
- A NOTE_BUNDLE child exposes that same payload table. Rebuilding an outer
  `uq9` envelope would introduce a second serialization contract and could
  change absent-versus-present nullable register semantics.
- The existing standalone reducer already owns center/custom/fill paths,
  fill color, style map, style/color/width, rotation/scale, page/origin,
  z-index, live/archive movement, Pencil rematerialization and page revision.

## Decision

- `OriginalModifyInkOperationApplier` exposes `preflightTable()` and
  `applyTable()`. Both decode the nested `wd8` table directly; standalone and
  bundled operations then enter the same reducer.
- NOTE_BUNDLE preflights every type-17 child before page identity or content is
  written, and applies accepted children in operation-vector order inside the
  existing bundle transaction.
- A repeated register winner is accepted only when the persisted value equals
  the incoming value. This applies to all twelve materialized register groups.
  The rule is required because the same child identity may arrive inside two
  different outer bundles; the outer inbox identity cannot prove child bytes
  are equal.
- A newer stored winner remains a normal stale no-op. Equality conflicts throw
  and roll back the complete bundle instead of silently preserving ambiguous
  state.

## Verification

- ArkTS fixture decodes and preflights a type-17 child following CREATE_INK and
  ADD_PATH_ELEMENTS in the same NOTE_BUNDLE.
- `d02-note-bundle-modify-ink.mjs` covers two target Inks, one page revision,
  exact retry, same-identity conflicts, stale/newer winners and injected
  all-or-nothing rollback. Static guards cover all twelve persisted register
  groups and the table-level bundle wiring.
- All D-02 Node/SQLite replays pass: `TOTAL=48 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` assembleHap
  builds succeed. Device Hypium was not executed.

## Remaining boundary

This does not add unsupported original Ink effects or Tape rendering. It also
does not consume NOTE_BUNDLE entity visibility, Block/Text children, archived
page bootstrap content, PDF background, private authentication transport or
server-side note/site creation. Those payloads remain explicitly deferred.
