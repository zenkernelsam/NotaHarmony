# Harmony evidence — original note-view night mode

Phase 562, 2026-09-22.

## Original evidence

`r22.java` renders the note-editor settings section; case 1 mounts a
toggle row:

- `feature_settings__note_view_night_mode` — "Note view night mode"
- `feature_settings__note_view_night_mode_caption` — "View your notes
  (paper and ink) with a dark appearance"

The caption makes the semantics explicit: the dark appearance applies
to **paper and ink inside the note view**, not the app-wide theme.
The runtime consumer lives in native/obfuscated code — no decompiled
application site is visible; the portable contract is the persisted
toggle + note-view-scoped dark appearance for paper and ink.

## Harmony landing

- `EditorSettingsStore.ets`: `noteViewNightMode` pref key in
  `noteEditorSettings`; `getNoteViewNightMode`/`saveNoteViewNightMode`
  ride the shared `getBooleanPref`/`saveBooleanPref` helper (mutex +
  flush-failure rollback preserved). Default `false` (no original truth
  table — registered).
- `SettingsPage.ets`: toggle row under "Note editor" rendering both the
  title and the original caption; same optimistic-update + rollback +
  lifecycle-generation guard (`setNoteViewNightModeEnabled`).
- `NotePage.ets`: `@State noteViewNightMode` loaded in `aboutToAppear`
  via `applyNoteViewNightModeSetting()` (dedicated `nightModeGeneration`
  invalidation in `aboutToDisappear`). `resolveTokens()` returns
  `DarkTheme` tokens when the pref is on — darkening the editor chrome —
  and the state is passed to the canvas as `nightMode`.
- `NoteCanvasView.ets`: `@Prop @Watch('onNightModeChange') nightMode`;
  `resolveTokens()` resolves `'dark'` when set; the paper render path
  already routes through `resolveTokens()` so `PaperRenderer` consumes
  `theme.paperBackground`/`theme.paperLineColor` dark values. The
  watcher triggers `renderFrame(true)` for a full paper+ink redraw.

## Strings

```json
note_view_night_mode          "Note view night mode"   / "笔记页面夜间模式"
note_view_night_mode_caption  "View your notes (paper and ink) with a
                               dark appearance"        / "以深色外观查看笔记（纸张与墨迹）"
```
