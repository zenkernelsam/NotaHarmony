# ADR-0074: Reproduce the original Recording capture foundation

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `tr8` configures Android `MediaRecorder` with audio source 6
  (`VOICE_RECOGNITION`), MPEG-4 output, AAC encoding, one channel, 44,100 Hz and 96,000 bps. It
  records `System.currentTimeMillis()` and monotonic elapsed time only after `start()` succeeds.
- `tr8` records monotonic time at pause and accumulates the paused interval after resume. `wr8.e()`
  subtracts both completed and active pause intervals from elapsed duration.
- `ky` case 11 stops the recorder, reads media duration metadata and constructs the Recording end
  time from `start + duration`. It falls back to monotonic elapsed duration when metadata cannot be
  read. `wr8.h()` releases the recorder and deletes the temporary output after prepare/start failure.

## Decision

- Add a serialized `OriginalRecordingCaptureController` with explicit idle, transitional, active,
  failed and permanently released states. Start, pause, resume, stop, abort and release share one
  `AsyncMutex`; illegal or duplicate transitions do not reach the media backend.
- Inject wall and monotonic clocks. Measure both only after successful recorder start, exclude paused
  time from the fallback, prefer validated media metadata after stop, and derive end time as the
  original `start + duration` rather than using a later wall-clock sample.
- Add a Harmony `AVRecorder` backend using the semantic equivalent of Android audio source 6,
  `AUDIO_SOURCE_TYPE_VOICE_RECOGNITION`, with AAC/MPEG-4, mono, 44,100 Hz and 96,000 bps. Write to an
  owned temporary file descriptor, extract duration through `AVMetadataExtractor`, and transfer the
  completed path only after non-empty-file validation.
- Treat recorder errors and all failed start/stop paths as terminal capture failures. Unregister the
  callback, stop/release when possible, close the descriptor and unlink incomplete output. Editor
  teardown always releases the controller.
- Declare microphone permission and its localized reason, but do not request runtime permission or
  expose Record controls in this phase. A completed file is not yet a durable Recording: asset hash,
  atomic asset storage and CREATE_RECORDING operation journaling must land before UI exposure.

## Rejected Alternatives

- Map Android source 6 to plain Harmony `MIC`: both capture microphone input, but Harmony exposes a
  voice-recognition source that preserves the original processing scenario more precisely.
- Use wall time for duration: clock changes can corrupt elapsed time and the original explicitly uses
  monotonic time as its fallback.
- Keep an invalid or empty output for later recovery: the original deletes failed temporary output,
  and an incomplete file has no valid Recording identity or asset metadata.
- Expose a Record button now: stopping currently yields only an owned temporary file. UI exposure
  before atomic asset and operation persistence would allow recordings that disappear on restart or
  never enter original CRDT history.

## Verification

- ArkTS tests cover the exact profile/source, pause exclusion, metadata preference, monotonic
  fallback, start cleanup, asynchronous recorder errors and permanent release.
- `d02-recording-capture-controller.mjs` locks the original evidence, Harmony lifecycle, permission
  declaration and the deliberate absence of a start call from `NotePage`.
- Full replay and clean HAP results are recorded in the Phase 97 report. No device was started.

## Remaining Boundary

The next phase must atomically move the completed file into asset storage, calculate its AssetHash,
encode/apply CREATE_RECORDING and append the exact payload to the operation log with rollback cleanup.
Runtime permission, Record/pause/resume/stop UI, audio focus/interruption behavior, internal-device
capture and device codec/audio validation remain separate boundaries.
