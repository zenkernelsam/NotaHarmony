// Phase 1282 — Apple/Microsoft OAuth web sign-in
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ap = 'com/gingerlabs/notability/feature/login/apple/AppleSignInActivity.java';
const ms = 'com/gingerlabs/notability/feature/login/microsoft/MicrosoftSignInActivity.java';
const apple = R(ap), msft = R(ms);
t('AppleSignInActivity extends r12', apple.includes('extends r12'));
t('Apple WebView + auth_url', apple.includes('WebView') && apple.includes('auth_url'));
t('Apple callback_url intercept', apple.includes('callback_url'));
t('Apple v60 WebViewClient', apple.includes('v60'));
t('Apple a70 result', apple.includes('a70'));
t('MicrosoftSignInActivity extends r12', msft.includes('extends r12'));
t('Microsoft h(Uri) deep-link', msft.includes('h(Uri uri)'));
t('Microsoft LOGIN + oauth error', msft.includes('yn7.LOGIN') && msft.includes('OAuth error'));
t('Microsoft aa8 result', msft.includes('aa8'));
t('both activities exist', existsSync(S + ap) && existsSync(S + ms));
console.log('oauth-login replay: ' + n + '/10 checks green');
