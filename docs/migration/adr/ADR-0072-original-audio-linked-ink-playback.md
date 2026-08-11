# ADR-0072: Reproduce original AudioLinked Ink playback in the editor renderer

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `dm2.j()` reads nullable uint32 CREATE_INK field 15 as `audioDuration`.
  `s06.c()` uses `operation.audioTime ?? operation.clientTime`; `s06.m()` returns start plus the
  unsigned duration when present.
- `s1j.b()` implements three visible states with unsigned comparisons: before start is Unbegun,
  between start/end is Animating with a clamped fraction, and at/after end is Complete. An end below
  start violates the invariant and completes instead of attempting wrapped animation.
- `p16.a()` disables the effect without a current audio time or when the Ink start belongs to none
  of the visible Recording segments. Unbegun and Animating both use alpha 0.3; Complete uses normal
  rendering. `vv7.S()` proves segment membership is inclusive.
- `i16/e16/p16.r()` render the complete Ink at reduced alpha, then overlay the completed prefix at
  normal alpha. Pencil uses `splatCount * progress`; ordinary Ink uses a path-length prefix through
  `PathMeasure.getSegment`, not a raw point-count prefix.
- Harmony's completed-stroke bitmap cannot change with playback time. The existing unified ordered
  renderer can draw all element kinds directly while preserving z-order, so it is the correct
  dynamic path during audio playback.

## Decision

- Decode field 15 as nullable uint32 and remove the previous
  `CREATE_INK_AUDIO_DURATION_UNSUPPORTED` gate. Materialize decimal-string effective audio start and
  nullable duration on `StrokeElementData`; preserve both through ADD_PATH_ELEMENTS, MODIFY_INK,
  erasing, selection transforms, clipboard and editor snapshots.
- Keep absolute audio timestamps as canonical decimal strings. Map the active player's local
  position onto the selected Recording's first effective segment without converting the absolute
  bounds to JavaScript numbers. Build the eligibility list from every visible Recording segment,
  falling back to immutable recording bounds when its segment list is empty.
- Implement the original Disabled/Unbegun/Animating/Complete projection as a pure function. Use
  inclusive segment membership, alpha 0.3, nullable duration semantics and the original invalid-end
  completion rule.
- During a valid audio playback context, force the canvas through the existing unified ordered
  renderer instead of the completed bitmap. Draw Unbegun Ink once at alpha 0.3. Draw Animating Ink
  completely at alpha 0.3 and overlay its prefix at normal alpha. Complete and unrelated Ink remain
  normal.
- Truncate Pencil by deterministic splat count. Truncate ordinary polyline/Bezier Ink by geometric
  length; split the terminal cubic with de Casteljau interpolation and preserve path attributes for
  variable-width rendering. Explicit fill/custom paths are present in the faded complete pass; the
  normal-alpha reveal follows the original center-path-derived prefix.
- Hydrate old stroke JSON that predates this ADR from Phase 94's applied-only timing table. This is
  lossless: earlier code deferred every CREATE_INK that had field 15, so a historically materialized
  Ink can legitimately lack duration but cannot have had a discarded non-null duration.

## Rejected Alternatives

- Rebuild the completed bitmap on every player callback: this causes repeated bitmap transfers and
  still complicates mixed element z-order.
- Reveal by source point count: point spacing is nonuniform and visibly diverges from the original
  path-length behavior.
- Convert uint64 absolute timestamps to `number`: valid original times above 2^53 would alias.
- Apply playback alpha to every page Ink without a Recording-segment guard: the original explicitly
  disables unrelated entities.

## Verification

- ArkTS tests cover uint64-near-maximum state transitions, segment exclusion, wrapped-end invariant,
  absolute player-time mapping, Pencil splat truncation and ordinary geometric truncation.
- CREATE_INK fixtures cover field-15 uint32 max and prove the former deferred gate is removed.
- `d02-audio-linked-ink-playback.mjs` locks data propagation, state constants, dynamic ordered-layer
  wiring, legacy timing hydration and renderer composition.
- Full desktop replay and clean HAP build results are recorded in the Phase 95 report.

## Remaining Boundary

No emulator or device was started. Actual AV decode, callback cadence, animation smoothness and
pixel comparison with Android remain device acceptance work. Waveform rendering, recording capture,
audio focus/output routing and outbound Recording mutations are separate contracts.

ADR-0073 closes the local Recording delete/Undo lifecycle and exact payload journal; private server
transport remains separate. Original 1.0.3 exposes no Recording rename command in this toolbox.
