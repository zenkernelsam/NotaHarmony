# Harmony evidence — original note-view immersive toggles

Phase 561, 2026-09-22.

## Original evidence

`r22.java` renders the note-editor settings section; cases 3 and 4 mount:

- `feature_settings__hide_status_bar` — "Hide status bar in note view"
- `feature_settings__hide_navigation_bar` — "Hide navigation bar in note
  view"

Both are note-view-scoped immersive toggles. The runtime application
(`WindowInsets`/`systemUiVisibility` handling) lives in native/obfuscated
code — no decompiled consumer is visible. The portable contract is the
pair of persisted toggles + note-view-scoped application.

## Harmony landing

- `EditorSettingsStore.ets`: `hideStatusBar`/`hideNavigationBar` pref keys
  in `noteEditorSettings`; interface widened with the four methods; both
  ride a shared `getBooleanPref`/`saveBooleanPref` helper preserving the
  mutex + flush-failure rollback semantics. Defaults `false` (no original
  truth table — registered).
- `SettingsPage.ets`: two more toggle rows under "Note editor", each with
  the established optimistic-update + rollback + lifecycle-generation
  guard (`setHideStatusBarEnabled`/`setHideNavigationBarEnabled`).
- `NotePage.ets`: `applyHideSystemBarsSetting()` in `aboutToAppear` reads
  both prefs and calls `window.setSpecificSystemBarEnabled` — `'status'`
  for the status bar; `'navigation'` + `'navigationIndicator'` for the
  nav bar (three-button vs gesture variants degrade independently).
  `aboutToDisappear` restores all bars that were hidden; guarded by a
  dedicated `systemBarsGeneration`.

## Strings

```json
hide_status_bar      "Hide status bar in note view"      / "在笔记页面隐藏状态栏"
hide_navigation_bar  "Hide navigation bar in note view"  / "在笔记页面隐藏导航条"
```

EN values verbatim from `strings.xml`.

## Adaptations registered

- Original defaults not evidenced — assumed off (opt-in immersive
  behavior).
- HarmonyOS distinguishes `navigation` (three-button) and
  `navigationIndicator` (gesture); both are toggled for the single
  original switch, each failing independently.
- Application is per-window via `setSpecificSystemBarEnabled`; bars
  restore when leaving the editor even if a later apply fails.

## Verification

`d02-original-hide-system-bars.mjs` — 27 assertions covering strings,
store keys/interface/rollback, page state + toggle wiring + guards, and
the appear/disappear application contract for all bar kinds.
