# ADR-0119: Match original checkbox reset during Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `cie.u()` creates the Text Block, selects it as the RichText target and invokes
  `m4c.u()`. There is no additional checkbox-copy operation before the target is cleared.
- `m4c` stores paragraph/character style spans in `l/h` and the independent location-keyed checkbox
  map in `m`. The complete `m4c.u()` copy method maps characters and style spans but never reads
  `this.m`.
- The apparent `n4c.o()` branch in `m4c.u()` reads `d3c`, whose value and `toString()` identify it as
  Link. It is unrelated to checkbox state.
- `he8` explicitly deprecates paragraph `isChecked` in favor of UpdateCheckbox, while the copy path
  emits no UpdateCheckbox payload. A copied CHECK_BOX decorator therefore has no checkbox register
  and renders unchecked.

## Decision

- Preserve every ordinary paragraph style field, including CHECK_BOX `decoratorStyle=3`, but omit
  materialized `isChecked` when producing Group Paste type-13 operations.
- Do not invent type-28 operations for checked source rows. This intentionally follows original
  1.0.3 even though it means a checked item becomes unchecked in its copy.
- Coalesce adjacent paragraph runs after removing `isChecked`. Materialization can split otherwise
  identical decorator runs solely because their location-keyed checkbox values differ; once those
  values are omitted, the original style span is continuous.
- Compare reducer canonical output against the checkbox-stripped and coalesced expectation. The
  source clipboard object remains unchanged; only the newly created Text follows original reset
  behavior.

## Rejected Alternatives

- Emit type-28 for every source `isChecked`: this improves state preservation but contradicts the
  observed 1.0.3 copy operation sequence.
- Keep rejecting Text containing `isChecked`: original 1.0.3 allows the copy and merely resets its
  independent checkbox state.
- Encode deprecated `isChecked` inside type-13: the original validator rejects that payload and
  directs writers to UpdateCheckbox.
- Retain adjacent runs after stripping state: reducer materialization would merge them, causing the
  canonical snapshot check to reject an otherwise faithful copy.

## Verification

- `OriginalRichTextStylePayloadEncoder.test.ets` copies adjacent checked/unchecked source runs,
  emits one paragraph style operation and materializes one CHECK_BOX decorator run with no
  `isChecked` property.
- `d02-original-group-paste-checkbox-reset.mjs` extracts the complete `m4c.u()` method, proves it
  does not read `this.m` or emit UpdateCheckbox, identifies `d3c` as Link and checks Harmony's
  stripping/coalescing path.
- Full replay and clean HAP results are recorded in the Phase 142 report.

## Remaining Boundary

This decision concerns copy/paste fidelity only. Local user checkbox toggling still needs its own
original type-28 outbound interaction path; remote type-28 replay remains implemented by ADR-0054.
Shape-owned RichText copy is still separate.
