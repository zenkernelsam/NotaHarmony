# ADR-0318: Recording toggle disposal bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony recording playback toggle lifecycle

## Context

`toggleRecording()` is the last recording control entry that did not check `editorDisposed`. A queued UI callback after teardown could load a new item or drive play/pause against an already-released playback controller.

## Decision

- Check `editorDisposed` at function entry; disposed editors never resolve recordings or touch the playback controller.
- Durable recording data remains authoritative for the next editor instance.

## Consequences

The recording control surface now has complete disposal coverage. Real playback race behavior remains device acceptance work. No emulator, virtual machine, physical device, or Hypium is started.
