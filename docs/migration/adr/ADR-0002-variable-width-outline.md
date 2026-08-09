# ADR-0002: Variable-width outline fidelity

## Status

Accepted on 2026-08-09.

## Context

Notability 1.0.3 builds variable-width outlines on bezierkit paths and performs internal-arc handling. The current HarmonyOS port offsets raw polyline samples, uses a synthetic sharp-corner midpoint, and previously had rotated round caps and a fixed-direction degenerate normal.

The audit requires a choice among adaptive dense sampling, a reliable curve-offset dependency, or accepting the mismatch. There is no verified ArkTS curve-offset library in the current dependency graph, and adding an unverified native geometry dependency would expand persistence, ABI, and packaging risk.

## Decision

Use the already fitted cubic centerline as the source of truth, flatten it adaptively by curvature and local width, then construct scaled circular outer joins and round caps. Preserve the original fast path for a fully degenerate point as a circle. Replace the current synthetic sharp-corner midpoint only after the adaptive sampler and join tests are in place.

This is an explicit approximation of the original bezierkit implementation, not a claim of source-level equivalence. Thresholds without a 1.0.3 counterpart remain documented as port assumptions.

## Consequences

- Curved strokes become independent of raw input sampling density.
- Join and cap radius scale with local stroke width.
- No new native or third-party runtime dependency is introduced.
- Pixel comparison against the original remains a device validation item.
- A later proven bezier offset library can replace the sampler behind the same outline contract.
