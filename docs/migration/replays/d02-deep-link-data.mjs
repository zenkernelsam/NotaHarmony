// Phase 838 — 深链 data 面 + n() 配置流
import { readFileSync } from 'node:fs';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const m = {};
for (const v of ['1.0.1', '1.0.3', '1.4.2']) {
  m[v] = readFileSync(`${R}/decompiled_${v}/resources/AndroidManifest.xml`, 'utf8');
}
const ma = readFileSync(`${R}/decompiled_1.4.2/sources/com/gingerlabs/notability/app/MainActivity.java`, 'utf8');
const mj = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/module.json5', 'utf8');
const dl = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/DeepLinkIngress.ets', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 版本谱系
ck('1.0.1 基线 4 path', ['/event/learn-from-home', '/app/note', '/authlink'].every(p => m['1.0.1'].includes(`"${p}"`) || m['1.0.1'].includes(`"${p}/"`)) && !m['1.0.1'].includes('plus25'));
ck('1.0.3 +/event/plus25', m['1.0.3'].includes('/event/plus25') && !m['1.0.3'].includes('planner2627'));
ck('1.4.2 +planner2627 +/gallery', m['1.4.2'].includes('/event/planner2627') && m['1.4.2'].includes('"/gallery"'));
ck('host notability.com + 通配', m['1.4.2'].includes('"notability.com"') && m['1.4.2'].includes('"*.notability.com"'));
ck('msauth scheme', m['1.4.2'].includes('"msauth"') && m['1.4.2'].includes('com.gingerlabs.notability'));
ck('application/pdf MIME', m['1.4.2'].includes('application/pdf'));

// n() 配置流
ck('n() 推 mi9(Configuration+Rect)', /void n\(Configuration[\s\S]{0,400}new mi9\(new Configuration[\s\S]{0,100}new Rect\(bounds\)/.test(ma));
ck('getCurrentWindowMetrics 边界', ma.includes('getCurrentWindowMetrics'));
ck('onTopResumed 亦走 n()', /onTopResumedActivityChanged[\s\S]{0,300}n\(configuration\)/.test(ma));

// Harmony 侧
ck('module.json5 声明 app/note', mj.includes('app/note') && mj.includes('notability.com'));
ck('module.json5 声明 file/pdf', mj.includes('application/pdf'));
ck('DeepLinkIngress 注释含 gallery+planner2627', dl.includes('/gallery') && dl.includes('planner2627'));
ck('子域匹配逻辑', dl.includes('endsWith(DEEP_LINK_HOST_SUFFIX)'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
