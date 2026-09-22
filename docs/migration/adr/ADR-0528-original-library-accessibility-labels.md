# ADR-0528 — Original library accessibility labels (`cd_*`)

- Status: accepted
- Date: 2026-09-22
- Phase: 557

## Context

The original library surface exposes four dedicated content descriptions
(`feature_library__cd_add_note`, `cd_open_note_action`,
`cd_open_note_titled`, `cd_sort`). The Harmony port had accessibility labels
on some indicators (favorite, recordings, folder expand/collapse, view-mode
toggle) but the two primary actions — creating and opening a note — had no
labels, and the sort control used the generic `sort` string rather than the
original's "Sort notes".

## Decision

Map the original `contentDescription` strings onto ArkUI
`.accessibilityText`, attached to the same components that own the click
handlers:

- Create speed-dial FAB → `cd_add_note` ("Add note").
- `NoteCard` and `NoteListRow` containers → `cd_open_note_titled` with the
  note title, falling back to `cd_open_note` when the title is empty.
- Sort field-label button → `cd_sort` ("Sort notes").

Labels are placed on the click-target containers, not on decorative
children, matching the original single-description-per-card semantics.

## Consequences

- Screen-reader users get action-oriented announcements matching the
  original wording.
- Grid and list layouts announce identically.
- The direction arrow button retains its own `sort` label (original groups
  both under the sort control; the arrow is a Harmony-added convenience).
- The `cancelButton` inside the search field cannot carry a separate label
  (platform API gap) — registered difference.

## Verification

`d02-original-library-accessibility-labels.mjs` (19 assertions);
full Desktop Replay suite green; `note@default` and `note@ohosTest` HAP
builds clean.
