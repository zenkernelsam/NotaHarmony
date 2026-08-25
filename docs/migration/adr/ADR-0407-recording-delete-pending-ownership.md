# ADR-0407: Recording delete pending ownership

## Status

Accepted (2026-08-25)

## Context

`OriginalRecordingDeleteController` owns pending undo state and publishes snapshots through its listener. `NotePage.commitRecordingDeletes()` still ended with `pendingRecordingDeleteIds = []` after an awaited store delete and recording reload. If the user requested deletion of recording B while recording A's commit was awaiting, the controller published `[B]`, and A's later continuation erased B from that UI projection even though controller cleanup had not yet run.

## Decision

Remove the blanket reset from the commit continuation. Pending-delete UI projection is owned only by the controller listener. The controller remains responsible for removing committed IDs in its own `finally`, splicing its own commit record, and publishing the authoritative list after cleanup.

## Consequences

Concurrent delete requests preserve their pending visibility until each owning commit settles. Disposal guards on reload and listener writes remain unchanged, and failure publication continues through the existing failure listener.
