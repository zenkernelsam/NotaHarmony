# Evidence: Preference saves disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `note/src/main/ets/ui/settings/SettingsPage.ets`
- `note/src/main/ets/ui/settings/DefaultTemplatePage.ets`
- Before: neither page had aboutToDisappear. Late save failures rolled back optimistic state and showed
  toasts after teardown; late successes also toasted.
- Existing load generations protected reload races but did not represent component disposal.

## Change

- Added disposal flags plus per-save lifecycle generations.
- Guarded successful persistence before toasts and failed persistence before rollback/toast on both pages.
- Strengthened load success/failure guards with the same disposal flag.

## Verification

- Focused replay: docs/migration/replays/d02-preference-saves-disposal-bound.mjs (10/10).
- Adjacent route replay remained green: d02-original-default-template-route.mjs.
- Full Desktop Replay: `REPLAY_FILES=317 PASSED=317 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 10 s 163 ms; main BUILD SUCCESSFUL in 56 s 423 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
