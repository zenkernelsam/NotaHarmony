# Original login & paywall surfaces — JADX evidence (2026-09-26)

Phase 714 audit of `feature_login__*` (55 strings) and `feature_paywall__*`
(101 strings) — the app's entire account/subscription UI.

## `feature_login__*` — login/onboarding-account surface

- `nq7.java`: welcome screen — `feature_login__welcome_to_notability` (line
  259/414), benefit sticker carousel (`feature_login__sticker_grow`/
  `momentum`/`everyone` drawables, lines 205–218).
- Sign-in providers: `feature_login__continue_with_apple`,
  `continue_with_google`, `continue_with_microsoft`, email+password form
  (`enter_password`, `email_address`, `a_link_has_been_sent_to_your_email_
  address`).
- Credential/backend classes: `png`, `rbd`, `vq7`, `zl2`, `v60`, `umh`
  (OAuth + Notability account service).

## `feature_paywall__*` — subscription purchase surface

- `hye.java`: paywall UI — `current_plan`, `badge_most_popular`,
  `badge_most_powerful`, `classic_feature_1..6` plan cards,
  `discount_original_price`/`discount_footnote`.
- `bba.java`: purchase/restore error mapper — `error_purchase_
  acknowledgment`, `error_purchase_already_owned`, `error_purchase_
  billing_unavailable`, `error_purchase_cancelled`, `error_purchase_
  network`, `error_purchase_service_unavailable`, `error_restore_
  incomplete`, `samsung_already_claimed`, `error_load_products`.

## Billing backends — two store clients + private validation gateway

```
sources/com/android/billingclient/api/ProxyBillingActivity.java      (Play Billing)
sources/com/gingerlabs/notability/data/billing/client/PlayBillingClient$BillingException.java
sources/com/gingerlabs/notability/data/samsungbilling/client/SamsungBillingClient$SamsungBillingException.java
sources/com/gingerlabs/notability/data/billing/gateway/
  PlayValidationUnavailableException.java   ← server-side receipt validation
  PlayPurchaseAlreadyClaimedException.java
  PlayPurchaseRejectedException.java
  MissingOverviewAfterGrantException.java
  PostGrantOverviewRefreshException.java
```

## Harmony state

`grep -rn "paywall\|signIn\|feature_login\|billing\|purchase" note/src/`
→ no account/subscription implementation; settings has no account row;
no OAuth providers, no store billing client, no validation gateway.
Absence is the correct flag-off-equivalent state.
