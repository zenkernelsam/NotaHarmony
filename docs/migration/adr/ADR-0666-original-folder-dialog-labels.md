# ADR-0666: Original folder dialog labels + selected-row a11y

- **Status**: Accepted
- **Phase**: 718
- **Closes**: `ui_folder__*` string family audit (remainder after
  ADR-0665's delete cascade)
- **Evidence**: `docs/migration/evidence/original-folder-dialog-labels-jadx-2026-09-25.md`

## Context

The `ui_folder__*` sweep after Phase 717 left three small parity gaps:

1. `ui_folder__enter_folder_name` — `gaj.java:630`/`719` selects the
   folder dialog's title/field label as `z8 ? new_folder :
   enter_folder_name`: create shows "New Folder", **rename shows
   "Enter folder name"**. Harmony's rename dialog reused the generic
   `rename` title and a `"Name"` placeholder.
2. `ui_folder__selected` — `b41.java:94`/`o94.java:171` attach the
   semantics label "Selected" to the selected folder row's indicator
   node. Harmony's `Text('✓')` indicator had no a11y text.
3. Remaining keys (`cd_confirm` "Save folder", `cd_folder_name`,
   `collapse/expand_folder`, `create_a_new_folder`,
   `decoration_color/emoji`, `delete_folder_button`,
   `name_error_message`, `unfiled`) already map to existing Harmony
   resources — verified in the evidence doc's key table.

## Decision

- Folder rename dialog title: `rename` → new `enter_folder_name`
  ("Enter folder name" / "输入文件夹名称"), matching the original's
  `z8` selection.
- `NameDialog` gains a `placeholder` prop (default `name` for the note
  rename flow); the folder dialog passes `enter_folder_name` — original
  uses the same string for the name field's label.
- The selected folder row's `✓` indicator gets
  `.accessibilityText($r('app.string.folder_selected'))`
  ("Selected"/"已选中") — the a11y node maps onto the indicator, exactly
  where the original attaches its semantics label; the row itself keeps
  announcing the folder name.

## Consequences

- Folder create shows "New Folder" title + "Enter folder name" field
  label; folder rename shows "Enter folder name" for both — verbatim
  original wording.
- Screen readers announce "Selected" on the current folder's indicator,
  matching `b41`/`o94`.
- `ui_folder__*` family fully audited (24 keys): 9-key delete matrix
  (ADR-0665), dialog/a11y labels (this ADR), remainder already covered.
- Replay: `d02-original-folder-dialog-labels.mjs` (12 pins).

## Limitations

- zh strings are faithful translations (en-only APK resources).
- No runtime a11y verification; source-pinned only.
