# ADR-0668: `ui_tools__` tail — width resource label, select-mode a11y; toolbox MEDIA/RECORD boundary

- **Status**: Accepted (mixed port + boundary registrations)
- **Phase**: 720
- **Closes**: `ui_tools__*` family audit (45 keys)
- **Evidence**: `docs/migration/evidence/original-ui-tools-tail-jadx-2026-09-25.md`

## Context

The `ui_tools__*` sweep: tool names, laser tails, eraser modes, color
picker entries, record controls, tape actions were all ported in earlier
phases. The tail items:

| Item | Original site | Disposition |
|---|---|---|
| `width` = "Width: %1$d" | `yed.java` ×4 — width-slider readout | **Ported**: `WidthSlider` `'Width: '+N` literal → `ui_tools_width` resource with `Math.round` int arg (original `y0(f)` yields int) |
| `select_box_label`/`select_rect_mode`, `select_freehand_label`/`select_freehand_mode` | `jfh.java:39-53` — two-icon mode buttons ("Box"/"Free" + "Rectangle/Freehand selection" a11y) | **Partial port**: Harmony's single toggle keeps its Freehand/Rectangle labels; the mode a11y descriptions now ride the button (`accessibilityText` = current mode's original string) |
| `media`, `record` (toolbox tools) | `a6f.MEDIA`(6)/`RECORD`(7), `rz1.q()` default preset, `y5f` → `x4f`/`e5f` states, `x82.r` labels "Media"/"Record" | **Boundary**: the original ships toolbox *canvas tools* for media insertion and audio recording. Harmony delivers both via the toolbar add-menu and the recordings panel — there is no canvas-tool activation surface. Registering the difference; a real tool port would be a feature-sized effort (canvas interaction mode + tool-state plumbing), not a string phase |
| `stroke`/`fill`/`no_fill` | `hx1.java` (STROKE/FILL property tabs), `r22` | **Boundary**: the shape-edit property sheet with stroke/fill pickers isn't ported; `fillColor` round-trips at the data layer (shape detection) |
| `color_options`/`open_color_wheel`/`recent_colors` | `o4j` chevron a11y, `rw1` recents icon label, `r22` wheel icon | **Covered/boundary**: eyedropper, `add_a_color`, recents dot row are ported; the original's icon-node a11y labels have no counterpart nodes |
| `pointer`/`ruler`/`zoom` | `a6f.Q/T/U` | Already registered (ADR-0644 presence/collab boundary, ruler hidden in original, ZOOM flag) |

## Decision

1. `ui_tools_width` resource ("Width: %d"/"宽度：%d") replaces the
   `WidthSlider` literal, formatted via `Math.round` per the original's
   integer format.
2. The selection-mode toggle carries `select_rect_mode` /
   `select_freehand_mode` a11y text describing the *current* mode —
   the original labels each of its two mode icons; the single-toggle
   form is retained (functional equivalent, documented deviation from
   the two-icon radio).
3. MEDIA/RECORD toolbox tools and the shape property-sheet labels
   registered as boundaries — no canvas media/record tool surface and
   no shape-style sheet exist to carry them.

## Consequences

- `ui_tools__*` family fully audited.
- Width readout is now localizable and verbatim "Width: N".
- Selection-mode toggle announces the active mode to screen readers.
- Replay: `d02-original-ui-tools-tail.mjs` (12 pins).

## Limitations

- No runtime a11y verification (no device session).
- MEDIA/RECORD toolbox tools remain an intentional structural
  difference; if a future phase ports toolbox canvas tools, this ADR's
  boundary note should be revisited.
