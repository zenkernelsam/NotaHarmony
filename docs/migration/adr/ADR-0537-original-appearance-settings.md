# ADR-0537 — Original Appearance settings section

- Status: accepted
- Date: 2026-09-22
- Phase: 566

## Context

The original's settings include an Appearance section pairing "Match
system appearance" (`r22` case 0) with "Dark theme" (`g8`), collapsing
to `nve` {MATCH_SYSTEM, LIGHT, DARK}. Harmony already had the full
machinery — `ThemeStore` modes, `library_prefs/theme_mode` persistence,
and a library menu with follow-system/light/dark — but no settings-page
surface for it.

## Decision

Add an "Appearance" section to `SettingsPage` (before "Note editor",
matching `s3d`'s directory order) with two rows:

- "Match system appearance" — ON writes `'system'`; OFF preserves the
  current *resolved* appearance as the explicit mode
  (`systemDark ? 'dark' : 'light'`) so the visible theme doesn't jump.
- "Dark theme" — writes `'dark'`/`'light'`; disabled while match-system
  is on since the explicit choice is overridden then.

Persistence reuses the existing `library_prefs/theme_mode` +
`ThemeStore.setMode` path with lifecycle-generation/disposal guards —
identical semantics to the library menu.

## Consequences

- Theme mode is now user-visible in settings, matching the original.
- `dark_theme` string value updated to the original label "Dark theme"
  ("深色主题"); the library menu reads the same key and remains correct.
- The original's sub-screen navigation structure isn't reproduced — the
  rows live inline in SettingsPage (consistent with the port's merged
  settings surface).
- No new datastore keys: `theme_mode` already existed.

## Verification

`d02-original-appearance-settings.mjs` (22 assertions); full Desktop
Replay suite green; `note@default` and `note@ohosTest` builds clean.
