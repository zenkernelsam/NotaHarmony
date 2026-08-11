# ADR-0070: Preserve the original three Recording playback speeds

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `wna` exposes exactly `SPEED_1_0`, `SPEED_1_5` and `SPEED_2_0`, backed by
  rates 1.0, 1.5 and 2.0. `n05.b` renders all enum values as a segmented speed control.
- `npa` handles a speed action by resolving the exact enum rate, falling back to 1.0 only for an
  unknown rate, updating player state, and applying the float to the active player.
- `uw7.G()` reapplies the stored speed immediately before starting playback. The choice therefore
  survives media-item changes and is not merely a property of one loaded Recording.
- The local Harmony SDK defines `AVPlayer.setSpeed(PlaybackSpeed)` only for prepared, playing,
  paused and completed states. It provides exact 1.0/1.5/2.0 enum modes and reports effective modes
  through `speedDone`.

## Decision

- Add a stable public three-value Recording speed enum. Reject every other value instead of exposing
  Harmony's additional modes, because those modes are absent from the target app contract.
- Let the controller own the desired speed independently of the current AVPlayer. A selection made
  while idle or loading is retained; each newly prepared player receives the selected mode before
  initial seek and autoplay. In supported active states, selection calls `setSpeed` immediately.
- Roll back the desired mode if synchronous `setSpeed` fails and publish a FAILED playback snapshot.
  Register and unregister `speedDone` with the same generation/player guards as other media events.
- Accept delayed confirmations for any of the three original modes. Rapid 1.5x then 2x selection can
  legitimately deliver the older 1.5x confirmation after desired state is already 2x; it must not
  falsely fail playback. A callback outside the original three modes is treated as a media mismatch.
- Add compact 1x/1.5x/2x segmented buttons to the cumulative playback row. The editor mirrors a mode
  only after the controller accepts it, and selected styling remains stable across Recording changes.

## Deferred

- Device tests must still verify codec support, audible rate, pitch behavior, audio focus and output
  routing. No static API call can establish those hardware/runtime properties.
- Speed preference is session state, matching the observed original player state. This phase does not
  invent durable per-note or global preference storage.

## Verification

- ArkTS tests lock the three allowed public modes and reject an unknown ordinal.
- Static replay locks SDK mode mapping, valid-state gating, prepared-before-play ordering,
  speedDone teardown, UI wiring and the original three labels.
