# ADR-0003: Page coordinate space and completed-layer cache

## Status

Accepted on 2026-08-09.

## Context

M2-R-03 requires one coordinate model for paper, completed ink, live ink, text, input, selection, and dirty regions. An earlier repair already changed the completed layer from viewport size to page size. Replacing it again with a tile model before proving a failure would introduce a second coordinate system and obscure the remaining renderer defects.

Notability 1.0.3 `c5g.d()` applies scroll translation and zoom once around page-space ink rendering. The Harmony implementation follows the same structural rule: persisted geometry remains in page coordinates and the main canvas owns the only viewport translation and scale.

## Decision

Keep the page origin at `(0,0)` and define page units as `3.78` units per millimetre. `CanvasViewport` is the only screen/page mapping:

```text
screen = page * zoom + scroll
page   = (screen - scroll) / zoom
```

`PaperRenderer`, `StrokeLayerManager.completedLayer`, live strokes, text blocks, selection geometry, eraser input, and dirty rectangles all consume page coordinates. `NoteCanvasView.renderFrame()` applies `translate(scroll)` and `scale(zoom)` once before drawing those consumers. The completed layer never stores viewport translation or zoom.

Keep one full-page completed OffscreenCanvas for the current standard-size page. Reject non-finite, non-positive, or oversized page metadata before repository writes, after repository reads, and again before canvas allocation. The static budget is 2048 pixels per side and 2,000,000 pixels in total. It includes every currently exposed paper size: A3 is the largest area at `1123 x 1588 = 1,783,324` pixels, while Tabloid has the longest side at 1633 pixels. The independent side cap also rejects corrupt, extremely narrow pages whose area alone would look acceptable but whose texture dimension would be unsafe.

One RGBA page surface is therefore at most 7.63 MiB. The normal completed layer plus its drawImage-compatible ImageBitmap is at most 15.26 MiB. A masked-stroke rebuild can transiently add one isolated layer and one transferred bitmap, making the page-cache-specific upper bound about 30.52 MiB. Main-canvas buffers, the pencil scratch surface, and platform-internal copies are separate and require device profiling.

Page size or orientation changes rebuild only the page cache. They do not call `centerPaperInViewport()`, so the user's zoom and scroll remain unchanged. Switching to another page intentionally recentres that page in the current implementation.

## Consequences

- Zoom and pan cannot change persisted geometry or completed-layer coordinates.
- Content outside the current screen viewport but inside the page remains in the full-page cache and reappears when panned into view.
- Stroke transforms are applied while drawing and their transformed bounds remain page-space bounds for selection and dirty tracking.
- Corrupt page dimensions now fail page loading explicitly instead of attempting an unbounded OffscreenCanvas allocation.
- The current paper-size product surface does not support arbitrary custom dimensions above the cache budget.
- No tile cache is introduced in M2-R-03. A tile decision requires device evidence that standard pages exceed memory or canvas limits.
- Device validation is still required at 25%, 100%, and 400% zoom, under large pan offsets, after rotation, and across ten-minute writing/memory runs.
