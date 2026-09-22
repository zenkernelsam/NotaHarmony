# ADR-0533 — Original note-view night mode

- Status: accepted
- Date: 2026-09-22
- Phase: 562

## Context

The original's note-editor settings include "Note view night mode" with
the caption "View your notes (paper and ink) with a dark appearance"
(`r22` case 1). The Harmony port already had a `ThemeStore` with
`LightTheme`/`DarkTheme` tokens, and `PaperRenderer` darkens paper via
`theme.paperBackground`/`theme.paperLineColor` — but there was no
note-view-scoped override independent of the system/app theme.

## Decision

Port the toggle on the Phase 560–561 settings infrastructure:

- A new pref (`noteViewNightMode`) in `EditorSettingsStore`, riding the
  shared `getBooleanPref`/`saveBooleanPref` helper.
- A toggle row in `SettingsPage` under "Note editor" showing title +
  caption, with optimistic update + rollback + lifecycle-generation
  guard.
- `NotePage` loads the pref in `aboutToAppear` into
  `@State noteViewNightMode` (generation-invalidated); `resolveTokens()`
  resolves `'dark'` when on — darkening editor chrome — and the state
  flows to `NoteCanvasView` as a `@Prop` that both darkens canvas tokens
  (same resolution path, so paper+ink follow `DarkTheme`) and triggers
  a full `renderFrame(true)` on change.

## Consequences

- Note view can darken paper, ink, and chrome per the original's
  note-view-scoped semantics without touching the global theme.
- Original default is not evidenced; assumed off (opt-in).
- The override is applied at token resolution (`'dark'` instead of the
  stored theme mode), so all existing theme consumers — chrome, canvas
  frame, paper renderer — darken uniformly.
- The test fake implements the widened `EditorSettingsRepository`.

## Verification

`d02-original-note-view-night-mode.mjs` (26 assertions); full Desktop
Replay suite green; `note@default` and `note@ohosTest` builds clean.
