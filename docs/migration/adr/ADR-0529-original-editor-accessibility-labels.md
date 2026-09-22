# ADR-0529 — Original editor accessibility labels

- Status: accepted
- Date: 2026-09-22
- Phase: 558

## Context

Following Phase 557 (library `cd_*` labels), the editor surface still had
glyph-only buttons with no accessible name — undo `↶`, redo `↷`, the
color-well circle, the toolbox `✕` close and per-tool `⋯` menus — while the
original exposes dedicated content descriptions for each
(`toprighttoolbar_undo_action`, `toprighttoolbar_redo_action`,
`cd_quick_tool_color`, `toolbar_more_menu`, `settings_close`,
`page_indicator`).

## Decision

Map the original `contentDescription` strings onto ArkUI
`accessibilityText` for every evidenced surface:

- Undo/redo glyph buttons → `cd_undo_action` / `cd_redo_action`
  (original values "Undo Action"/"Redo Action").
- Color-well circle → `cd_quick_tool_color` ("Color").
- Toolbar `...` overflow and per-tool `⋯` menu → `toolbar_more_menu`
  ("More options", replacing the Harmony-invented "More Tools" label).
- Toolbox settings `✕` → existing `close` string (original value "Close").
- Page indicator → `cd_page_indicator` ("%1$d of %2$d") — the original
  announces the formatted count rather than the jump action.

The Harmony-only zoom strip (`-`/`+`) also gets labels
(`zoom_out`/`zoom_in`) since unlabeled glyph buttons are an accessibility
hole; these two keys are Harmony-side additions with no original
counterpart.

## Consequences

- All glyph-only editor buttons now announce; text-labeled tool buttons
  stay self-announcing (original needed cds only because its buttons are
  icon-only — registered difference).
- `toprighttoolbar_share_action` not ported: no share surface exists.
- Phase 542's jump-to-page anchor remains valid: the dialog title still
  uses `jump_to_title`; only the indicator's cd changed.

## Verification

`d02-original-editor-accessibility-labels.mjs` (22 assertions); full
Desktop Replay suite green; `note@default` and `note@ohosTest` builds
clean.
