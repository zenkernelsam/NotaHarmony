# Evidence: Backup load preparation disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The reload success path checked both page disposal and captured load generation.
- Its failure path only compared generation, so a disposed-page continuation could still reset config/server/last-backup state and publish ERROR.
- The nested backup preparation catch logged an exporter failure and immediately built user-facing messaging plus showAlert, bypassing the outer lifecycle guard.

## Change

- Reload failures now log first; state reset and ERROR publication require no disposal and the current load generation.
- Backup preparation failures now log first and return silently when the captured lifecycle generation is stale.
- Messaging construction and alerts occur only for active, current-generation tasks. Existing active behavior and finally cleanup are unchanged.

## Actual verification

- Focused replay: docs/migration/replays/d02-backup-load-preparation-disposal-bound.mjs (5/5).
- Adjacent replay: docs/migration/replays/d02-backup-failures-disposal-bound.mjs (5/5), strengthened to cover the nested preparation catch.
- Full Desktop Replay: REPLAY_FILES=350 PASSED=350 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 10.325 seconds; default in 70.311 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.