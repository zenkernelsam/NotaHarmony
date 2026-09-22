# Harmony evidence — original library accessibility labels (`feature_library__cd_*`)

Phase 557, 2026-09-22.

## Original evidence

`decompiled_1.0.3` resources define dedicated content descriptions for the
library surface:

| Resource key | Original value | Role |
|---|---|---|
| `feature_library__cd_add_note` | `Add note` | Library create FAB / new-note affordance |
| `feature_library__cd_open_note_action` | `Open note` | Note card/row open action (untitled) |
| `feature_library__cd_open_note_titled` | `Open note %1$s` | Note card/row open action (titled) |
| `feature_library__cd_sort` | `Sort notes` | Sort control |

The originals are `contentDescription` strings — they announce the *action* the
control performs, not the visible text. In the original, the note card is a
single clickable surface, so one description ("Open note %1$s") covers the
whole card rather than a nested icon.

## Harmony landing

`note/src/main/ets/ui/library/LibraryPage.ets`:

- **Create FAB** (speed-dial root `+`/`×` button): added
  `.accessibilityText($r('app.string.cd_add_note'))`.
- **NoteCard** (grid layout): added `.accessibilityText` on the same `Column`
  that owns `.onClick` — `cd_open_note_titled` with `note.title` when the
  title is non-empty, else `cd_open_note`.
- **NoteListRow** (Phase 547 `ie7` LIST layout): identical label on the row's
  click-target `Row`, keeping grid/list accessibility parity.
- **Sort field button** (sidebar header chip opening the field/direction
  menu): `.accessibilityText($r('app.string.cd_sort'))` replaces the generic
  `sort` label. The separate ↑/↓ direction button keeps its own label.

## Strings

Added to `base` (EN = original wording) and `zh_CN`:

```json
cd_add_note         "Add note"        / "添加笔记"
cd_open_note        "Open note"       / "打开笔记"
cd_open_note_titled "Open note %1$s"  / "打开笔记 %1$s"
cd_sort             "Sort notes"      / "排序笔记"
```

## Adaptations registered

- ArkUI `.accessibilityText` is the `contentDescription` equivalent; labels
  sit on the click-target container so nested children (title text, folder
  chip, indicators) do not produce duplicate action announcements.
- The search `cancelButton` (Phase 555) has no separate accessibility hook —
  already registered as a platform difference in that phase's docs.
- Empty-title notes fall back to `cd_open_note`; in practice the repo always
  persists a non-empty title (default note name), so the fallback is
  defensive parity with the original's two resource variants.

## Verification

`d02-original-library-accessibility-labels.mjs` — 19 assertions: bilingual
string values, FAB/card/row/sort label wiring, format-arg usage, and that
labels precede the guarded `onClick` handlers.
