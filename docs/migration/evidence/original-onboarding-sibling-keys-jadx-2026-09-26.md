# Original `hq9` sibling datastore keys — JADX evidence (2026-09-26)

Phase 713 audit of the two `hq9` datastore keys left unported by Phase 712.

## `gq9` model — three-field seen-state record

`decompiled_1.0.3/sources/defpackage/gq9.java`:

```java
public final class gq9 {
    public final Set a;        // onboardingTooltipSeen          → ported (Phase 712)
    public final boolean b;    // defaultNotesRolePromptSeen     → this phase
    public final Set c;        // sixMonthsPlusOnboardingSeenUserIds → this phase
    // toString: "Data(tooltipStatus=…, seenDefaultNotesRolePrompt=…, seenSixMonthsPlusOnboardingUserIds=…)"
}
```

`hq9.java:13` — `eua("sixMonthsPlusOnboardingSeenUserIds")` datastore key; the role-prompt key is its sibling. `s89.java` cases 13/14/15 expose `gq9.c`, `gq9.b`, `gq9.a` respectively as flows.

## `defaultNotesRolePromptSeen` → shared-notes role prompt

Consumers `m8.java`, `h3.java`, `ccj.java` render:

| String | Site |
|--------|------|
| `feature_library__notes_role_prompt_title` | `m8:61` — interpolates role name `{0}` |
| `feature_library__notes_role_prompt_message` | `h3:240` |
| `feature_library__notes_role_prompt_confirm` | `ccj:36` |
| `feature_library__notes_role_prompt_deny` | `ccj:36` (same row) |
| `feature_library__notes_role_info_message` | `h3:240` (info variant, `gl8` bool selects) |
| `feature_library__notes_role_info_dismiss` | `ccj:36` (info variant button) |

Role state provenance: `SyncedNoteMetadata` carries `shared`, `linkAccessLevel`,
`linkPermissionScope`, `userAccessLevel` (`cha.java:21` schema, `m78.java:144` merged
metadata) — the collaboration sync backend registered fail-closed in ADR-0513 /
ADR-0658 (`COLLAB_RTL`).

## `sixMonthsPlusOnboardingSeenUserIds` → "6 months of Plus" promo modal

- `tt8.java:74` — modal built from `ui_designsystem__six_months_plus_onboarding_title` +
  `_description`; analytics key `qtb.c = "androidSixMonthsPlusOnboarding"` →
  `"SixMonthsPlusOnboarding"`.
- `lq7.java:253` — callback `tt8.onSeenSixMonthsPlusOnboarding()` writes the current
  user id into the seen-set.
- `q31.java:539` — internal-tool reset row, verbatim: *"Reset 6-months-Plus
  onboarding — The '6 months of Plus, on us' modal will show again on the next
  library visit (only for an eligible promo subscription)."*

Eligibility requires an eligible **promo subscription**; the seen-set is a set of
**user IDs** (per-account suppression). Both are account/subscription-backend
concepts absent in Harmony.

## Harmony state

- `grep -rn "notes_role\|six_months_plus\|SixMonthsPlus\|rolePrompt" note/src/` →
  zero hits; no surfaces, no strings, no datastore keys.
- Correct behavior for both surfaces is absence: neither can ever become eligible
  without a collaboration backend / account system.
