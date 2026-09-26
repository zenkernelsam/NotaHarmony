// Phase 851 — REST 端点注册表闭合
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const R = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 全树注解扫描
const eps = [];
const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.java')) { const t = readFileSync(p, 'utf8'); for (const m of t.matchAll(/@(f16|y9c)\("([^"]*)"\)/g)) eps.push([f.name.replace('.java', ''), m[1] === 'f16' ? 'GET' : 'POST', m[2]]); } } };
walk(join(R, 'defpackage'));
walk(join(R, 'com/gingerlabs/notability'));

ck('端点总数=24', eps.length === 24);
ck('auth 7 端点', eps.filter(e => e[0] === 'b2f').length === 7 &&
  ['/auth/nonce', '/google/sign-in', '/microsoft/sign-in', '/passkey/register/options', '/passkey/register/verify', '/passkey/authenticate/options', '/passkey/authenticate/verify'].every(p => eps.some(e => e[2] === p)));
ck('Stripe×2', eps.filter(e => e[0] === 'c1h' && /stripeConsumer/.test(e[2])).length === 2);
ck('collab-api×3', eps.filter(e => /collab-api/.test(e[2])).length === 3);
ck('learn×3', eps.filter(e => /^learn\//.test(e[2])).length === 3);
ck('Intercom×3', eps.filter(e => /intercom/.test(e[2])).length === 3);
ck('Zendesk×4', eps.filter(e => /zendesk/.test(e[2])).length === 4);
ck('images/email×2', eps.some(e => e[2] === '/images/thumbnails') && eps.some(e => e[2] === '/email/subscribe'));
ck('全部 POST/GET', eps.every(e => e[1] === 'GET' || e[1] === 'POST'));

// Harmony 无 REST 客户端面
let found = 0;
const walkEts = (d) => { try { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walkEts(p); else if (f.name.endsWith('.ets')) { const t = readFileSync(p, 'utf8'); if (/stripeConsumer|passkey\/register|collab-api|intercom|zendesk|awaitQuizJob|parseSyllabus/.test(t)) found++; } } } catch {} };
walkEts('C:/HarmonyProject/NotaHarmony/note/src/main/ets');
ck('Harmony 无 REST 端点面', found === 0);

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
