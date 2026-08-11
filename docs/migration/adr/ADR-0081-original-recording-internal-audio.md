# ADR-0081: Match the original internal-audio recording source

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `bkb` defines exactly two recording sources: `MIC` (`Microphone`) and
  `DEVICE_ONLY` (`Internal Audio`).
- Original `xjb.i()` starts `MIC` directly when Android `AudioManager.isMusicActive()` is false.
  When music is active it opens the source chooser instead of silently changing the source.
- Original `vp8.a()` returns false. Its pause and resume implementations only log
  `Pause/Resume not supported for internal audio recorder`, so internal capture must not expose a
  working Pause command.
- Original `AudioCaptureService` obtains a `MediaProjection`, configures
  `AudioPlaybackCaptureConfiguration.addMatchingUsage(1)`, and records 44.1 kHz mono PCM before
  producing the recording asset.
- The installed Harmony SDK provides `OH_AVScreenCapture` with `OH_ALL_PLAYBACK`, file capture,
  AAC-LC/MPEG-4 audio output, privacy-authorization state callbacks, and terminal stop callbacks.
  It does not provide pause/resume for this capture path.

## Decision

- Query `STREAM_USAGE_MUSIC` before a recording start. Start the microphone source directly when
  it is inactive; otherwise present `Microphone` and `Internal Audio` as the two original choices.
- Route both sources through one capture controller. Microphone capture retains runtime microphone
  permission, media focus, and pause/resume. Internal capture requests neither microphone
  permission nor audio focus and reports `supportsPause() === false`.
- Implement internal capture with a small native `libnota_recording.so` bridge over
  `OH_AVScreenCapture`: `OH_CAPTURE_FILE`, `OH_ALL_PLAYBACK`, AAC-LC, MPEG-4 audio, 44.1 kHz,
  mono, 96 kbps, and an owned `fd://` temporary M4A destination.
- Treat authorization cancellation as start failure. Treat system/user/call/user-switch terminal
  states after start as interruptions that flow through the existing stop, validate, hash, persist,
  and CREATE_RECORDING path. Do not discard a valid capture merely because the system stopped it.
- Keep native ownership singleton and reject a second active internal capture. Ignore callbacks from
  a capture that is no longer current, suppress the expected terminal callback during an explicit
  stop, and distinguish an already externally stopped capture from one that still needs native stop.
- Include `STARTING` in interruption handling. A STARTED callback immediately followed by a system
  stop must queue stop/save behind the in-flight start instead of leaving the UI in a false recording
  state.

## Rejected Alternatives

- Always use the microphone: this omits a reachable original source and changes behavior while
  system music is active.
- Always show the source chooser: the original bypasses it when no music is active.
- Capture playback through the microphone or request microphone permission for internal audio:
  this changes both privacy semantics and the captured signal.
- Emulate Pause by ending and restarting screen capture: the original explicitly reports that
  internal pause/resume is unsupported, and segment stitching would invent unverified behavior.
- Abort on a system terminal callback: this can delete a valid recording that the original lifecycle
  expects to stop and save.

## Verification

- Recording-specific desktop replays pass, including
  `recordingInternalAudio=music-gated-source-native-m4a-no-mic-no-focus-no-pause-save-on-stop`.
- ArkTS session tests cover source routing, absence of microphone permission/audio focus, disabled
  Pause, normal system interruption, and interruption immediately after native start.
- All desktop replays pass with `TOTAL=90 FAILED=0`. After a clean, sequential `note@ohosTest` and
  `note@default` HAP builds both succeed; only the project's existing warnings remain.
- No emulator, virtual machine, device, or device Hypium run was used. The privacy dialog, actual
  playback capture, generated M4A playback, notification/system indicator, and each terminal system
  state remain explicit device acceptance items.
