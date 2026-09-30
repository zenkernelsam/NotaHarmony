// Phase 1286 — dual IAP billing + subscription domain
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('PlayBillingClient', X('data/billing/client/PlayBillingClient$BillingException.java'));
t('Play gateway exceptions', X('data/billing/gateway/PlayPurchaseRejectedException.java') && X('data/billing/gateway/PlayPurchaseAlreadyClaimedException.java') && X('data/billing/gateway/PlayValidationUnavailableException.java'));
const pr = R('data/billing/gateway/PlayPurchaseRejectedException.java');
t('Play token-not-validated', pr.includes('token was not validated'));
t('SamsungBillingClient', X('data/samsungbilling/client/SamsungBillingClient$SamsungBillingException.java'));
t('Samsung gateway exceptions', X('data/samsungbilling/gateway/SamsungPurchaseAlreadyClaimedException.java') && X('data/samsungbilling/gateway/SamsungPurchaseInvalidException.java'));
t('subscription PurchaseAck', X('domain/subscription/PurchaseAcknowledgmentException.java'));
const ri = R('domain/subscription/RestoreIncompleteException.java');
t('RestoreIncomplete message', ri.includes('none could be processed'));
const sd = R('domain/subscription/SamsungIapDisabledException.java');
t('SamsungIapDisabled', sd.includes('IllegalStateException'));
t('MissingOverview post-grant', X('data/billing/gateway/MissingOverviewAfterGrantException.java'));
const pbc = X('data/billing/client/PlayBillingClient$BillingException.java');
t('billing client structure', pbc);
console.log('dual-iap replay: ' + n + '/10 checks green');
