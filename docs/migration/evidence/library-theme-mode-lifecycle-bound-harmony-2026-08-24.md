# Evidence: Library theme mode lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `setThemeMode()` called `ThemeStore.setMode()`, started thumbnail refresh, and asynchronously wrote
  `THEME_PREFERENCE_KEY` without checking whether the library page remained active.
- Because `themeMode` is process-global AppStorage and the preference file is durable, a stale menu action
  could outlive page disposal.

## Change

- Added an active-page gate as the first executable statement of `setThemeMode()`.
- All global memory, rendering, and preference effects now occur only after the gate.
- Existing sort/search/folder/thumbnail lifecycle contracts were re-checked and left unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-library-theme-mode-lifecycle-bound.mjs (7/7).
- Adjacent preference/thumbnail replay: docs/migration/replays/d02-library-preference-thumbnail-bound.mjs (6/6).
- Adjacent preference/thumbnail replay remained 6/6.
- Full Desktop Replay: REPLAY_FILES=323 PASSED=323 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 10.325 seconds; default in 57.404 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
