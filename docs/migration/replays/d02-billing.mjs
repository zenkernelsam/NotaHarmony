// Phase 1169 — billing layer (Play + Samsung dual gateway + domain subscription exceptions)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('Play billing gateway: 5 exceptions', ['MissingOverviewAfterGrantException','PlayPurchaseAlreadyClaimedException','PlayPurchaseRejectedException','PlayValidationUnavailableException','PostGrantOverviewRefreshException'].every(f=>has('data/billing/gateway/'+f+'.java')));
t('PlayPurchaseAlreadyClaimedException extends IllegalStateException', R('data/billing/gateway/PlayPurchaseAlreadyClaimedException.java').includes('extends IllegalStateException'));
t('PlayPurchaseRejectedException exists', R('data/billing/gateway/PlayPurchaseRejectedException.java').includes('extends IllegalStateException'));
t('PlayValidationUnavailableException extends RuntimeException', R('data/billing/gateway/PlayValidationUnavailableException.java').includes('extends RuntimeException'));
t('Samsung billing gateway: 4 exceptions', ['MissingSamsungOverviewAfterGrantException','SamsungPurchaseAlreadyClaimedException','SamsungPurchaseInvalidException','SamsungValidationUnavailableException'].every(f=>has('data/samsungbilling/gateway/'+f+'.java')));
t('SamsungPurchaseAlreadyClaimedException', R('data/samsungbilling/gateway/SamsungPurchaseAlreadyClaimedException.java').includes('extends IllegalStateException'));
t('SamsungValidationUnavailableException(Exception)', R('data/samsungbilling/gateway/SamsungValidationUnavailableException.java').includes('SamsungValidationUnavailableException(Exception'));
t('domain/subscription: 3 exceptions', ['PurchaseAcknowledgmentException','RestoreIncompleteException','SamsungIapDisabledException'].every(f=>has('domain/subscription/'+f+'.java')));
t('PurchaseAcknowledgmentException RuntimeException', R('domain/subscription/PurchaseAcknowledgmentException.java').includes('extends RuntimeException'));
t('SamsungIapDisabledException IllegalState', R('domain/subscription/SamsungIapDisabledException.java').includes('extends IllegalStateException'));
console.log('billing replay: ' + n + '/10 checks green');
