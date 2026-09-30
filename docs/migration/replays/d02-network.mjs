// Phase 1164 — core/network exception taxonomy + suspend call
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/network/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('HttpStatusException extends IOException', R('HttpStatusException.java').includes('extends IOException'));
t('HttpStatusException{int code, String×3}', R('HttpStatusException.java').includes('HttpStatusException(int i, String str, String str2, String str3, String str4)') && R('HttpStatusException.java').includes('final int I'));
t('NoConnectivityException extends IOException', R('NoConnectivityException.java').includes('extends IOException'));
t('NotAuthenticatedException extends IOException', R('NotAuthenticatedException.java').includes('extends IOException'));
t('NotAuthenticated package-private (final class)', R('NotAuthenticatedException.java').includes('final class NotAuthenticatedException'));
t('a extends n8e implements wx4 (SuspendLambda)', R('a.java').includes('extends n8e implements wx4'));
t('a invokeSuspend throws NotAuth+NoConn', R('a.java').includes('invokeSuspend(Object obj) throws NotAuthenticatedException, NoConnectivityException'));
t('a captures pcd/mcd/longs', R('a.java').includes('synthetic */ pcd K') && R('a.java').includes('synthetic */ mcd M'));
t('a has create+invokeSuspend', R('a.java').includes('ef2 create(Object obj') && R('a.java').includes('invokeSuspend'));
t('all 4 files present', has('HttpStatusException.java') && has('NoConnectivityException.java') && has('NotAuthenticatedException.java') && has('a.java'));
console.log('network replay: ' + n + '/10 checks green');
