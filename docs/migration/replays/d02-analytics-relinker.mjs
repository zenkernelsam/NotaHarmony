// Phase 1304 — ReLinker + Singular + Mixpanel + Wire
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ReLinker MissingLibraryException', existsSync(S + 'com/getkeepsafe/relinker/MissingLibraryException.java'));
const rl = readFileSync(S + 'com/getkeepsafe/relinker/MissingLibraryException.java', 'utf8');
t('MissingLibraryException', rl.includes('MissingLibraryException') || rl.includes('Exception'));
t('Singular sdk', existsSync(S + 'com/singular/sdk'));
t('Singular DeferredDeepLink', existsSync(S + 'com/singular/sdk/DeferredDeepLinkHandler.java'));
t('Singular Api', existsSync(S + 'com/singular/sdk/internal/Api.java'));
t('Mixpanel', existsSync(S + 'com/mixpanel'));
t('Square wire', existsSync(S + 'com/squareup/wire'));
t('sso GoogleCredentialException', existsSync(S + 'sso/GoogleCredentialException.java'));
t('singular Events', existsSync(S + 'com/singular/sdk/Events.java'));
t('multi analytics providers', existsSync(S + 'com/singular') && existsSync(S + 'com/mixpanel') && existsSync(S + 'com/google/firebase'));
console.log('analytics-relinker replay: ' + n + '/10 checks green');
