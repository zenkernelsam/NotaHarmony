# ADR-0068: Expose Recording playback through the editor toolbox

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `n05.a/c` renders a Recordings toolbox section with a bounded scrolling list.
  Every `hkb` row has a play control, resolved name and duration/date metadata. The current row is
  highlighted when playback state is PLAYING and its index matches `kpa.e`.
- `f74` case 1 defines the row action: tapping the current recording invokes the shared play/pause
  toggle; tapping another row selects that recording index. `kpa` exposes playback status, current
  index, cumulative current/total time and boundary times as UI state.
- Phase 88-90 now provide visible Recording materialization, exact local-byte validation and a
  generation-guarded one-recording AVPlayer. Before this phase none was referenced by production UI,
  so the Harmony compiler did not include the complete Recording path in the default module graph.

## Decision

- Add a dedicated `RecordingPanel` below the editor toolbar. Keep it a bounded 220vp work surface,
  not a modal or marketing-style card. It lists every visible Recording, highlights the selected
  item, disables MISSING/PENDING/FAILED assets, and exposes familiar play/pause and close symbols with
  accessibility labels.
- Follow the original row action: another row loads and autoplays; the playing row pauses; a selected
  ready/paused/completed row resumes; a failed selected row retries through the loader.
- Bind the slider to the AVPlayer snapshot and permit seek only in SDK-supported prepared/playing/
  paused/completed states. Display stable elapsed/total formatting including hours.
- `NotePage` owns the store and controller. Load Recording state only after DB initialization,
  subscribe to `AssetAvailabilityHub` so late audio arrival refreshes availability, unsubscribe on
  teardown, and release the controller from both explicit leave and component disappearance paths.
  Guard overlapping initial/asset-arrival queries with a load generation so stale PENDING results
  cannot overwrite a newer READY snapshot.
- Keep Recording load failure isolated from note/page loading. A malformed Recording row may empty
  the panel and report an error, but must not disable editing or overwrite note content.
- Do not add capture, deletion, rename, playback speed, cross-recording automatic advance, waveform
  or audio-ink sync until their outbound/lifecycle contracts are implemented.

## Consumer-discovered fix

Production reachability exposed two latent compile defects: `ErrorCallback` was not a valid visible
field type in the module context, and `OriginalRecordingOperation` rethrew an arbitrary catch value,
which ArkTS forbids. The callback now uses an explicit `BusinessError` function type; unexpected
operation failures are wrapped in `Error` after preserving `RecordingDeferredError` semantics.

## Verification

- ArkTS tests cover deterministic duration formatting. Static replay covers production imports,
  original row-toggle behavior, late-asset refresh, teardown release, state-gated seek and the newly
  reachable rethrow fix.
- Device playback, layout pixels and audio focus remain explicit acceptance items.
