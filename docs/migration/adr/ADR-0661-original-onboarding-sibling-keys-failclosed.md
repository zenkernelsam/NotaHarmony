# ADR-0661: Original `hq9` sibling datastore keys — notes-role prompt & six-months-Plus onboarding — fail-closed registration

- **Status**: Accepted
- **Phase**: 713
- **Depends on**: ADR-0513 (collaboration surface), ADR-0658 (remote-flag tail), ADR-0660 (onboarding tooltips)

## Context

`hq9.java` backs three datastore keys whose merged model is `gq9(Set tooltipStatus, boolean seenDefaultNotesRolePrompt, Set seenSixMonthsPlusOnboardingUserIds)`. Phase 712 ported the first (`onboardingTooltipSeen`, `gq9.a`). The two siblings are **not portable**:

1. `defaultNotesRolePromptSeen` (`gq9.b`, exposed via `s89` case 14)
2. `sixMonthsPlusOnboardingSeenUserIds` (`gq9.c`, `s89` case 13)

## Evidence

### `defaultNotesRolePromptSeen` — shared-notes role prompt

- `m8.java` / `h3.java` / `ccj.java` render `feature_library__notes_role_prompt_title` (interpolates a role name), `notes_role_prompt_message`, `notes_role_prompt_confirm`, `notes_role_prompt_deny`, and a post-dismissal info variant `notes_role_info_message`/`notes_role_info_dismiss` (`h3:36`, `h3:240`).
- The prompt is driven by shared-note role state: `SyncedNoteMetadata` carries `shared`, `linkAccessLevel`, `linkPermissionScope`, `userAccessLevel` (`cha:21`, `m78:144`) — produced by the collaboration backend already registered fail-closed (ADR-0513, ADR-0658 `COLLAB_RTL`).

### `sixMonthsPlusOnboardingSeenUserIds` — "6 months of Plus" promo modal

- `tt8:74` builds a modal from `ui_designsystem__six_months_plus_onboarding_title`/`_description` (`qtb` analytics key `androidSixMonthsPlusOnboarding`).
- `q31:539` internal-tool reset describes it verbatim: *"The '6 months of Plus, on us' modal will show again on the next library visit (only for an eligible promo subscription)"*.
- The seen-set is a **set of user IDs** — per-account suppression — and eligibility requires an eligible promo subscription. Both require the Notability account + subscription backend.

## Decision

Register both keys fail-closed: Harmony has no shared-notes collaboration backend and no account/subscription system, so neither prompt can ever become eligible. No UI, datastore keys, or strings are ported; the absence is itself the faithful boundary behavior.

## Consequences

- `notes_role_*` (6 strings) and `six_months_plus_onboarding_*` (2 strings) remain intentionally absent.
- A future collaboration/account backend decision would reopen both surfaces together.
- No runtime verification needed — nothing observable on device.
