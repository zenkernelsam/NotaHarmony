# ADR-0080: Preserve capture when the Recording panel closes

## Status

Accepted, 2026-08-11. This corrects the panel-close portion of ADR-0076.

## Evidence

- Original 1.0.3 `i5h.h` sends `ujb.a` only when its Record control observes `pjb`, the active
  recording state; otherwise that same control sends `new tjb()` to start. This is a state toggle,
  not a panel-close callback.
- The only other original `ujb.a` call is `b49`'s equivalent active/inactive Record toggle.
  A repository-wide search finds no close callback that sends Stop.
- Original `u49` also registers `z39(xjb, 0)` as an editor-level recording command, and `z39` sends
  `new tjb()`. Recording ownership therefore outlives the visibility of one toolbox surface.

## Decision

- `NotePage.closeRecordings()` only sets `showRecordings` to false. It does not stop, save, release
  or otherwise mutate the recording session.
- Reopening the panel presents the existing session snapshot, so Pause, Resume and Stop remain
  available. Leaving the editor still calls `finishAndRelease()` and saves an active capture.
- Keep the session mutex guarantee for an explicit Stop racing an in-flight Start, but describe it
  as command serialization rather than panel-close behavior.

## Rejected Alternatives

- Stop and save when hiding the panel: this invents a lifecycle edge absent from both original Stop
  call sites and prevents users from continuing to write while recording with the toolbox hidden.
- Release capture on hide: this loses a valid recording and conflates UI visibility with editor
  ownership.
- Leave the false Phase 99 replay assertion in place: that would make a migration regression look
  intentional and block the corrected behavior.

## Verification

- `d02-recording-session-ui.mjs` now locks both original toggle paths and extracts the Harmony
  `closeRecordings()` body to prove it only hides the panel.
- The session test still verifies that an explicit Stop is serialized behind an in-flight Start.
  Editor exit and lifecycle fallback remain covered separately.
- All desktop replays pass with `TOTAL=89 FAILED=0`. After a clean, sequential `note@ohosTest` and
  `note@default` HAP builds both succeed. No device was started.
