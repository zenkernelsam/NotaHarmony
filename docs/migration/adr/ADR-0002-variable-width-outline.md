# ADR-0002: Variable-width outline fidelity

## Status

Accepted on 2026-08-09.

## Context

Notability 1.0.3 builds variable-width outlines on bezierkit paths and performs internal-arc handling. The current HarmonyOS port offsets raw polyline samples, uses a synthetic sharp-corner midpoint, and previously had rotated round caps and a fixed-direction degenerate normal.

The audit requires a choice among adaptive dense sampling, a reliable curve-offset dependency, or accepting the mismatch. There is no verified ArkTS curve-offset library in the current dependency graph, and adding an unverified native geometry dependency would expand persistence, ABI, and packaging risk.

## Decision

Use the already fitted cubic centerline as the source of truth, flatten it adaptively by curvature and local width, then construct scaled circular outer joins and round caps. Preserve the original fast path for a fully degenerate point as a circle. The implementation is shared by live bounds and persisted-stroke rendering; both infer each cubic's width anchors monotonically from the persisted centerline because `CubicSourceRange` is intentionally not added to the storage format.

The implemented port tolerances are a `0.2` document-unit cubic flatness limit, a width-sensitive tangent step clamped to `0.04..0.3` radians, a `0.15` document-unit arc error, a recursion limit of 10, and a four-radius inside-miter limit. These values are bounded implementation assumptions, not constants recovered from Notability 1.0.3. Outside turns use circular arcs at the local half-width; inside turns use the adjacent offset-line intersection and fall back to a bevel when parallel or excessive. Cusps use bounded opposing semicircles.

This is an explicit approximation of the original bezierkit implementation, not a claim of source-level equivalence. Thresholds without a 1.0.3 counterpart remain documented as port assumptions.

## Consequences

- Curved strokes become independent of raw input sampling density.
- Join and cap radius scale with local stroke width.
- The old raw-polyline normal averaging, fixed corner threshold, and synthetic expanded midpoint are removed.
- Corrupt non-finite cubic geometry falls back to finite persisted centerline samples.
- No new native or third-party runtime dependency is introduced.
- Pixel comparison against the original remains a device validation item.
- Self-crossing centerlines remain finite and bounded, but this approximation does not claim bezierkit-equivalent Boolean removal of every local outline overlap.
- A later proven bezier offset library can replace the sampler behind the same outline contract.
