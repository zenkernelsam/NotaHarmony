# Evidence: Recording continuation disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Recording list load guarded only its generation; capture persistence, delete commit, auto advance,
  and timeline seek checked disposal only before their awaits.
- Late continuations could publish stale recordings, rebuild timelines, clear pending deletes on a new
  instance, or reset the wrong completion-advance marker.
- Existing replay covered recording persistence and delete commit at their first await boundary, not the
  follow-up publication after `loadRecordings()`.

## Change

- Added post-await disposal/generation checks before recording publication.
- Capture/delete flows rebuild or clear local state only after both the durable result and refreshed list
  remain valid for a live editor.
- Auto-advance no longer clears its in-flight flag for a disposed instance; seek clears it only after a
  live load completes.
- Durable database results and controller release semantics remain authoritative.

## Verification

- Focused replay: docs/migration/replays/d02-recording-followup-disposal-bound.mjs.
- Adjacent replay: docs/migration/replays/d02-recording-persist-disposal-bound.mjs.
- Adjacent recording replays: persist 2/2, commit-delete 2/2, advance 3/3, and seek 2/2.
- Full Desktop Replay: REPLAY_FILES=326 PASSED=326 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 8.837 seconds; default in 51.922 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
