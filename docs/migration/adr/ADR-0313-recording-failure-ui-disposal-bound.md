# ADR-0313: Bind Recording Failure UI to Editor Disposal

Date: 2026-08-23

## Context

`showRecordingFailure()` unconditionally showed permission dialogs and toasts. A failure delivered after editor disposal could still display UI against the removed page.

## Decision

Check `editorDisposed` at handler entry; disposed paths return without showing dialogs or toasts. The session failure sequence remains owned by the snapshot path.

## Consequences

Late recording failures cannot show UI on a disposed editor. The next editor instance starts with fresh failure state.
