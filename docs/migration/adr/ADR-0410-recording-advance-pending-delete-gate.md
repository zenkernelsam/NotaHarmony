# ADR-0410: Recording advance pending-delete gate

## Status

Accepted (2026-08-25)

## Context

`rebuildRecordingTimeline()` excludes recordings requested for deletion so seek locations, cumulative duration, and automatic next-selection use only visible recordings. However, a recording can enter the pending-delete set after its COMPLETED snapshot arrives. The asynchronous completion continuation then selected the next timeline entry and loaded it even though the just-completed recording was already invisible in the UI.

## Decision

After the disposal gate and before selecting a successor from the current timeline, reject advancement when the completed recording ID is present in `pendingRecordingDeleteIds`. Each completion event still owns its own counter release through the existing caller `finally`.

## Consequences

Delete requests win over an auto-advance race regardless of whether the delete listener published first or later. Visible playback state remains idle rather than jumping to a hidden timeline successor. Normal auto-advance and user-seek invalidation semantics are unchanged.
