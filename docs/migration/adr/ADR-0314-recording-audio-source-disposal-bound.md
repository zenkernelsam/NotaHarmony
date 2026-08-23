# ADR-0314: Bind Audio Source Selection to Editor Disposal

Date: 2026-08-23

## Context

`startRecording()` awaited the audio-source dialog and then started the session on the chosen source without checking whether the editor was still alive. If the user dismissed navigation while the dialog was open, a later dialog response could start recording on a disposed editor.

## Decision

Check `editorDisposed` before each `session.start()` after the dialog resolves; disposed paths return without starting capture. The no-dialog direct-start path is unchanged because it has no await boundary between check and start.

## Consequences

A late audio-source selection cannot start recording on a disposed editor. The released controller remains authoritative; the next editor instance starts with fresh session state.
