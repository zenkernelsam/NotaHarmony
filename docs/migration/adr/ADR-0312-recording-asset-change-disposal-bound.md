# ADR-0312: Bind Recording Asset Change to Editor Disposal

Date: 2026-08-23

## Context

`onRecordingAssetAvailabilityChanged()` unconditionally refreshed recordings when a matching asset change arrived. A hub event delivered after editor disposal could still drive `loadRecordings()` and publish snapshots against the disposed page.

## Decision

Check `editorDisposed` at handler entry; disposed paths return without refreshing. The hub subscription is still unsubscribed during teardown, but this guard closes the synchronous race window.

## Consequences

Late asset-change events cannot refresh a disposed editor's list or timeline. The next editor instance subscribes fresh and loads authoritative recordings normally.
