# ADR-0077: Present original Recording rows independently of stored names

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `hkb` assigns each visible Recording a one-based list index. With no segments it
  exposes the Recording start and full effective duration; with segments it uses the first segment
  start and `end-start` duration.
- Original `n05` renders the title from `Recording %1$s`, not from the Recording `name` field or
  asset file name. It formats duration as `h m s`, `m s` or `s`, then combines it with a locale
  medium date and short time through `%1$s %2$s, %3$s`.
- Search of the 1.0.3 production recorder found no amplitude sampling or waveform-generation path.
  The only `getMaxAmplitude` result belongs to an unrelated Samsung wrapper, so a waveform is not
  accepted as evidence-backed scope.

## Decision

- Keep the stored original Recording `name` unchanged for wire and reducer fidelity, but never use
  it as the user-facing list title. Render localized `Recording N` from the current visible order.
- Centralize original duration and start selection in `OriginalRecordingPresentation`. Reuse the
  already verified first-segment effective-duration rule and parse decimal epoch milliseconds only
  when they fit the safe JavaScript Date range.
- For READY assets render exact original duration units, locale medium date and locale short time.
  For PENDING, MISSING or FAILED assets retain the more actionable local asset-state message.
- If legacy/corrupt time data cannot be represented as a Date, fall back to the asset file name for
  the subtitle without hiding or disabling an otherwise playable row.

## Rejected Alternatives

- Show `recording.name`: local captures intentionally store their temporary file name, and original
  presentation proves that internal value is not the row title.
- Use operation identity or asset creation time for the date: original `hkb.j` uses Recording start
  or first segment start.
- Always show the original subtitle for unavailable assets: Harmony must still explain why a row
  cannot play while its asset is downloading, missing or failed.
- Add a decorative waveform: there is no production evidence or amplitude data contract to support
  a faithful implementation.

## Verification

- ArkTS tests lock all three duration forms, first-segment start/duration selection and unsafe date
  rejection.
- `d02-recording-list-presentation.mjs` locks `hkb/n05` evidence, resources, presentation wiring and
  the absence of stored-name title rendering.
- Full replay is `TOTAL=86 FAILED=0`. After `hvigor clean`, `note@ohosTest` and `note@default` HAP
  builds both succeed. No device was started.

## Remaining Boundary

Locale output and row layout require device inspection across Chinese/English and narrow screens.
Device audio behavior from Phase 99 and private synchronization remain outstanding. Waveform work
should be reopened only if further original evidence establishes an actual data source and behavior.
