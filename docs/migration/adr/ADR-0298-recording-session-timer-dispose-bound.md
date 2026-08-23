# ADR-0298: Bind Recording Session Timer to Page Disposal

Date: 2026-08-23

## Context

`scheduleRecordingSessionRefresh()` armed a 250 ms timer for active recording snapshots. `aboutToDisappear()` called `finishRecordingSession()` but did not cancel this timer. If disposal raced an active capture, the timer could invoke the session callback after release began and mutate disposed page state or schedule another refresh.

## Decision

Cancel `recordingSessionTimer` at the start of `aboutToDisappear()`, before title save, controller release, delete flush, and session finish. The existing active-session scheduling path remains unchanged.

## Consequences

Page disposal immediately stops its own polling loop. A released session cannot drive disposed UI through the deferred timer; direct controller events remain serialized by the session lifecycle as before.
