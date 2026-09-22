# Harmony evidence — original Appearance settings

Phase 566, 2026-09-22.

## Original evidence

`r22.java` case 0 renders `feature_settings__match_system_appearance`
("Match system appearance"); `g8.java` renders
`feature_settings__dark_theme` ("Dark theme"). The pair collapses to
the `nve` appearance enum `{ MATCH_SYSTEM, LIGHT, DARK }` — MATCH_SYSTEM
means follow the OS; off, the dark-theme toggle picks LIGHT vs DARK.

`s3d.java`'s settings directory order places `appearance` before
`note_editor`.

## Harmony landing

The theme machinery already existed: `ThemeStore` resolves
`'system' | 'light' | 'dark'`, persisted as `library_prefs/theme_mode`
(`THEME_PREFERENCE_KEY`), with `LibraryPage.setThemeMode` as the
existing write path. What was missing was the Settings-page surface.

`SettingsPage.ets` gains an "Appearance" section ahead of "Note editor"
(matching `s3d` order) with two toggle rows:

- "Match system appearance": ON → `theme_mode='system'`; OFF → the
  current *resolved* appearance becomes explicit
  (`systemDark ? 'dark' : 'light'`) so toggling off doesn't flip the
  visible theme — the user's effective choice is preserved.
- "Dark theme": `theme_mode='dark'/'light'`; disabled + dimmed while
  match-system is on (the explicit choice is overridden then, matching
  the enum's single-value semantics).

Writes ride `ThemeStore.setMode` + `preferences` flush with
lifecycle-generation guards — the same path as `LibraryPage`.

## Strings

```json
appearance              "Appearance"               / "外观"
match_system_appearance "Match system appearance"  / "跟随系统外观"
dark_theme              "Dark theme"               / "深色主题"
```

(`dark_theme` was "Dark"/"深色" as a menu item; updated to the original
settings label — the library menu reads identically in context.)
