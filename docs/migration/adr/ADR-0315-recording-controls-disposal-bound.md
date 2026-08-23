# ADR-0315: Bind Recording Controls to Editor Disposal

Date: 2026-08-23

## Context

`pauseRecording()`, `resumeRecording()`, and `stopRecording()` invoked session operations without checking whether the editor was still alive. A queued control callback firing after disposal could drive the captured session after teardown began.

## Decision

Check `editorDisposed` at each control entry; disposed paths return without touching the session. The released controller remains authoritative.

## Consequences

Late pause/resume/stop callbacks cannot drive a released session on a disposed editor. The next editor instance starts with fresh state.
