# Harmony evidence — original editor accessibility labels

Phase 558, 2026-09-22.

## Original evidence

`decompiled_1.0.3` `strings.xml` carries dedicated content descriptions for
the editor chrome:

| Resource key | Original value | Surface |
|---|---|---|
| `feature_note__toprighttoolbar_undo_action` | `Undo Action` | Top-right undo button |
| `feature_note__toprighttoolbar_redo_action` | `Redo Action` | Top-right redo button |
| `feature_note__cd_quick_tool_color` | `Color` | Quick-tool color well |
| `feature_note__toolbar_more_menu` | `More options` | Toolbar overflow menu |
| `feature_note_toolbox__settings_close` | `Close` | Toolbox settings close |
| `feature_note__page_indicator` | `%1$d of %2$d` | Page indicator cd |

The originals are icon-button `contentDescription`s — the icon glyph carries
no text, so the description is the only accessible name.

## Harmony landing

- `EditorToolbar.ets`: glyph-only undo `↶` / redo `↷` buttons gain
  `cd_undo_action` / `cd_redo_action`; the label-free color-circle button
  gains `cd_quick_tool_color`; the `...` overflow swaps `more_tools`
  ("More Tools") for `toolbar_more_menu` ("More options" — original value).
- `PageManagerBar.ets`: the page indicator's `accessibilityText` switches
  from `jump_to_title` to `cd_page_indicator` (`"%1$d of %2$d"`, both args
  passed) — matching the original where the indicator's description is the
  formatted count, not the jump action.
- `ToolboxSettingsDialog.ets`: the `✕` close button gains `close`
  (original `settings_close` = "Close"); the per-tool `⋯` menu button gains
  `toolbar_more_menu`.
- `NoteCanvasView.ets`: zoom `-`/`+` gain `zoom_out`/`zoom_in`
  (Harmony-side labels — the T-034 zoom strip is an adaptation-layer
  control with no original cd evidence).

## Strings

Added to `base` (EN = original wording) and `zh_CN`:

```json
cd_undo_action      "Undo Action"    / "撤销操作"
cd_redo_action      "Redo Action"    / "重做操作"
cd_quick_tool_color "Color"          / "颜色"
cd_page_indicator   "%1$d of %2$d"   / "第 %1$d 页，共 %2$d 页"
toolbar_more_menu   "More options"   / "更多选项"
zoom_in / zoom_out  "Zoom in/out"    / "放大/缩小"   (Harmony-side)
```

## Adaptations registered

- Tool buttons already render text labels (`toolTypeLabel`) so they are
  self-announcing; the original's `cd_quick_tool_{pen,pencil,highlighter,
  eraser}` are needed only because the original uses icon-only buttons.
  Harmony keeps text buttons — registered difference, no label added.
- `toprighttoolbar_share_action` has no portable trigger: the Harmony
  editor has no share button.
- Page indicator keeps the same element; only its announced text changes
  ("N of M" instead of "Jump to page"). The tap-to-jump behavior and the
  dialog title (`jump_to_title`) are unchanged.

## Verification

`d02-original-editor-accessibility-labels.mjs` — 22 assertions covering
bilingual values, every label site, format-arg usage, and the
`more_tools`→`toolbar_more_menu` replacement.
