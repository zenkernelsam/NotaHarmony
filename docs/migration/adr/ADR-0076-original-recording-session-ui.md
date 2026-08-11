# ADR-0076: Wire the original Recording session lifecycle into the editor

## Status

Accepted, 2026-08-11; panel-close decision corrected by ADR-0080 on 2026-08-11.

## Evidence

- Original 1.0.3 `xjb` maps `tjb/ujb/rjb/sjb` to start, stop, pause and resume. `i5h` gates
  start with `fha.RECORD_AUDIO` and distinguishes "Couldn't start recording" from "Couldn't save
  recording". The earlier panel-close interpretation was incorrect: both original `ujb` call sites
  are record-button toggles, not toolbox-close callbacks.
- `wr8` builds a gain-type-one audio focus request with media usage/content type. `tr8` requests
  focus before starting the recorder; permanent or transient focus loss interrupts the recording.
- Original permission resources say "Microphone Access Required" and direct a denied user to
  application settings. The completed file continues through the Phase 98 asset/operation path.

## Decision

- Put permission, playback unload, audio-session activation, capture and persistence behind one
  `OriginalRecordingSessionController` and one mutex. The order is permission, playback unload,
  focus activation, capture start; stop reverses focus ownership before persisting the capture.
- Adapt Harmony runtime permission through `AtManager.requestPermissionsFromUser`. Adapt original
  audio focus with a media `AudioSessionManager` session using `CONCURRENCY_PAUSE_OTHERS`; a session
  deactivation event queues the same stop-and-save path as an explicit Stop command.
- Expose stable Record, Pause, Resume and Stop controls in `RecordingPanel`, plus elapsed time and
  preparing/saving states. The panel emits commands only; it owns no recorder, database or asset
  persistence dependency.
- Closing the recording panel only hides it and does not change capture state, as corrected by
  ADR-0080. Leaving the editor calls `finishAndRelease`, which saves an active recording before
  permanently releasing capture. `aboutToDisappear` is an idempotent fallback for non-toolbar exits.
- Classify permission denial, start failure and save/stop failure separately and publish each
  transition once. Permission denial uses the original explanatory dialog; start/save use the
  original failure strings.

## Rejected Alternatives

- Request permission when the editor opens: the original gates the recording action, and an eager
  prompt asks for sensitive access without user intent.
- Let the panel call `AVRecorder` or persistence directly: this splits lifecycle ownership and makes
  focus loss, close and route exit race each other.
- Abort on panel close or editor exit: editor exit must finish the capture, while panel close is not
  a recorder lifecycle command and must leave the active capture intact.
- Pause on Harmony audio-session deactivation: the original treats focus loss as interruption and
  finishes the recording, which also avoids leaving an invisible paused capture alive.

## Verification

- ArkTS tests cover denial without side effects, ordered start/pause/resume/stop/persist, focus-loss
  saving, explicit stop queued behind start, single failure publication, persistence failure and active
  finish/release.
- `d02-recording-session-ui.mjs` locks the original action, permission, focus and strings evidence as
  well as Harmony gateways, session ordering, editor exit and panel controls. Historical recording
  replays were updated only where Phase 99 intentionally replaced direct capture ownership.
- Full replay is `TOTAL=85 FAILED=0`. After `hvigor clean`, both `note@ohosTest` and `note@default`
  HAP builds succeed. No device was started.

## Remaining Boundary

Runtime permission UI, real microphone input, AAC/MPEG-4 codec behavior, audio-session interruption,
speaker/playback coexistence and panel layout still require device validation. Waveform generation,
recording-related remaining consumers and private operation upload/ACK are separate phases; none is
claimed complete here.
