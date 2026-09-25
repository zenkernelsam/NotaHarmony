# ADR-0662: Original login & paywall surfaces (`feature_login__*`, `feature_paywall__*`) — fail-closed registration

- **Status**: Accepted
- **Phase**: 714
- **Depends on**: ADR-0658 (remote-flag tail — NOTE_LIMIT/subscription flags), ADR-0661 (six-months-plus promo — subscription-eligibility modal)

## Context

Two remaining large string families are the app's entire account and
subscription UI:

- `feature_login__*` (55 strings): welcome screen with benefit sticker
  carousel, Apple/Google/Microsoft sign-in buttons, email+password form,
  email-link confirmation.
- `feature_paywall__*` (101 strings): plan cards (`classic_feature_1..6`,
  `badge_most_popular`/`most_powerful`), `current_plan`, discount
  footnotes, purchase/restore error set, Samsung promo claims.

## Evidence

- `nq7.java` renders the login screen (`feature_login__welcome_to_notability`,
  `sticker_grow`/`momentum`/`everyone` drawables); credential flows in
  `png`, `rbd`, `vq7`, `zl2`, `v60`, `umh` (Apple/Google/Microsoft/email
  OAuth + Notability account backend).
- `hye.java` renders the paywall (`current_plan`, badges); `bba.java`
  maps purchase/restore errors (`error_purchase_*`,
  `samsung_already_claimed`, `error_restore_incomplete`).
- Billing backends: `com.gingerlabs.notability.data.billing.client.
  PlayBillingClient` (Google Play Billing — `com.android.billingclient`
  tree present) **and** `data.samsungbilling.client.SamsungBillingClient`
  (Galaxy Store), plus a private validation gateway
  (`data.billing.gateway.PlayValidationUnavailableException`,
  `PlayPurchaseAlreadyClaimedException`, `PlayPurchaseRejectedException`,
  `MissingOverviewAfterGrantException`) — server-side purchase
  validation on Notability's backend.

## Decision

Fail-closed: HarmonyOS has no Google Play Billing or Samsung billing
client, no OAuth identity providers configured, and no Notability
account backend. The app is a standalone local note-taker — no login
screen, no paywall, no purchase/restore flows are ported, and none of
the 156 strings enter resources. Absence is the faithful boundary.

Prior registrations already closed dependent surfaces (NOTE_LIMIT and
subscription-duration flags in ADR-0658 Class B; the six-months-Plus
promo in ADR-0661). This ADR closes the root surface itself.

## Consequences

- No sign-in/account UI anywhere; settings contain no account row.
- No purchase, restore, plan-comparison, or billing-error UI.
- If a future account/billing backend decision is made, this surface
  reopens together with ADR-0661's promo modal and Learn quota
  (ADR-0652).
