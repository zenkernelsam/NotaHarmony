// Phase 843 — 登录提供方 + Zendesk 支持面
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const strings = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const src = (p) => readFileSync(join(B, p), 'utf8');

// Apple WebView OAuth
const apple = src('feature/login/apple/AppleSignInActivity.java');
ck('Apple: auth_url/callback_url extras', apple.includes('"auth_url"') && apple.includes('"callback_url"'));
ck('Apple: WebView JS+DOM 开启', apple.includes('setJavaScriptEnabled(true)') && apple.includes('setDomStorageEnabled(true)'));
ck('Apple: flow_state 保存恢复', apple.includes('"flow_state"') && apple.includes('onSaveInstanceState'));
ck('Apple: 方向锁定', apple.includes('setRequestedOrientation'));
ck('Apple: error 文案回传', apple.includes('apple_sign_in_error'));

// Microsoft
const ms = src('feature/login/microsoft/MicrosoftSignInActivity.java');
ck('Microsoft: has_received_redirect 态', ms.includes('has_received_redirect'));
ck('Microsoft: error 文案', ms.includes('microsoft_sign_in_error'));

// Zendesk API
const api = src('ui/support/data/a.java');
ck('Zendesk: articles/search.json', (api.match(/help_center\/articles\/search\.json/g) || []).length === 2);
ck('Zendesk: requests.json', api.includes('zendesk/v2/requests.json'));
ck('Zendesk: uploads.json', api.includes('zendesk/v2/uploads.json'));
ck('Zendesk: Content-Encoding identity', api.includes('Content-Encoding: identity'));
ck('ZendeskApiException extends Exception', src('ui/support/data/ZendeskApiException.java').includes('extends Exception'));

// login 字符串族
ck('login 字符串族≥30', (strings.match(/"feature_login__/g) || []).length >= 30);
ck('三提供方 CTA', ['continue_with_apple', 'continue_with_google', 'continue_with_microsoft'].every(s => strings.includes(`"feature_login__${s}"`)));

// Harmony 无账户面
let files = [];
const walk = (d) => { try { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.ets')) files.push(p); } } catch {} };
walk('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui');
const uiAll = files.map(f => readFileSync(f, 'utf8')).join('\n');
ck('Harmony 无 Zendesk/OAuth 面', !uiAll.includes('zendesk') && !uiAll.includes('Zendesk') && !uiAll.includes('continue_with_apple'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
