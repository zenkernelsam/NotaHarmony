# ADR-0667: `ui_text__` tail — link-sheet title, language-menu title, Add Text label; kbd-shortcut boundary

- **Status**: Accepted (mixed port + fail-closed registrations)
- **Phase**: 719
- **Closes**: `ui_text__*` family audit (74 keys)
- **Evidence**: `docs/migration/evidence/original-ui-text-tail-jadx-2026-09-25.md`

## Context

The `ui_text__*` sweep found the core surface (formatting, lists,
alignment, links, font styles/size/line-spacing, 27-language code
picker) already ported across the ink/text-toolbar phases. Six tail
items remained:

| Item | Original site | Disposition |
|---|---|---|
| `add_text` | `fie.java:19` — text-tool item label `yz.j("Add Text")` | **Ported**: `toolTypeLabel` default + toolbar add-menu entry |
| `insert_hyperlink`/`edit_hyperlink` | `bn5.java:127` — link dialog title by `en5.c` (has-link) | **Ported**: `linkSheetIsEdit` + sheet title |
| `programming_language` | `i8j.java:42` — code-language menu title | **Ported**: `bindMenu` `MenuOptions.title` |
| `fontsize` | `whh.java:289` — contentDescription on the value's chevron (opens a size list) | **Boundary**: Harmony's `kre` port is deliberately ±1pt steppers (ADR-0648/R-31); no chevron affordance exists to carry the label |
| `undefined_format`/`hr4` | `ir4.java:11`, `br2` — toolbar format button shows the *current* named style, "Format" when mixed | **Boundary**: Harmony presets write `{bold,fontSize}` atoms — no named-style field exists to read back a label; porting would require a model extension, out of string-parity scope |
| `kbd_shortcut_*` ×12 + group | `hke.java` registry → `kmi` `KeyboardShortcutGroup` (Android `onProvideKeyboardShortcuts` system help sheet) | **Fail-closed**: HarmonyOS has no system shortcut-help surface. The *shortcuts themselves* are ported (Ctrl+B/I/U/A/Home/End/D/Esc — checklist R-32); only the platform help-sheet labels are absent |

## Decision

1. Text tool item label → `add_text` ("Add Text"/"添加文本") in
   `toolTypeLabel` (settings list + toolbar button) and the toolbar
   overflow add-text menu entry — the original's single label source
   (`fie`) feeds all item surfaces.
2. Link sheet gains a title: `linkSheetIsEdit = linkUrlAt(s,e).length>0`
   at `openLinkSheet` → `edit_hyperlink` vs `insert_hyperlink` title
   row, verbatim strings.
3. Code-language `bindMenu` gets `{ title: programming_language }`.
4. `fontsize` (both locales) is added for completeness but the chevron
   node it described has no Harmony counterpart — documented boundary.
5. `undefined_format` + `kbd_shortcut_*` registered fail-closed per the
   table — no invented surfaces.

## Consequences

- Link sheet now distinguishes insert vs edit exactly like the
  original's `en5.c` title.
- Code-language menu shows the original "Programming language" header.
- Text tool label reads "Add Text" everywhere the item label surfaces.
- `ui_text__*` family fully audited.
- Replay: `d02-original-ui-text-tail-labels.mjs` (22 pins).

## Limitations

- zh strings are faithful translations (en-only APK resources).
- `MenuOptions.title` requires API ≥12 — project targets API 21.
