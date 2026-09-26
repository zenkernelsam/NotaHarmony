// Phase 830 — queries/uses-feature 明细
import { readFileSync } from 'node:fs';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const m = {};
for (const v of ['1.0.1', '1.0.3', '1.4.2']) {
  m[v] = readFileSync(`${R}/decompiled_${v}/resources/AndroidManifest.xml`, 'utf8');
}
const results = [];
const ck = (n, ok) => results.push([n, ok]);

// queries intent 明细
for (const [v, keys] of [
  ['1.0.1', ['action.SEND', 'action.MAIN', 'InAppBillingService.BIND', 'BillingOverrideService.BIND']],
  ['1.0.3', ['action.SEND', 'action.MAIN', 'InAppBillingService.BIND', 'BillingOverrideService.BIND', 'READ_PERMISSION_SINGULAR']],
  ['1.4.2', ['action.SEND', 'action.MAIN', 'InAppBillingService.BIND', 'BillingOverrideService.BIND', 'READ_PERMISSION_SINGULAR', 'IMAGE_CAPTURE_SECURE']],
]) ck(`queries intent @${v}`, keys.every(k => m[v].includes(k)));

// queries package 明细
ck('queries pkg @1.0.1 仅 samsungapps', m['1.0.1'].includes('com.sec.android.app.samsungapps') && !m['1.0.1'].includes('katana'));
ck('queries pkg @1.0.3 +katana+instagram', ['1.0.3', '1.4.2'].every(v => m[v].includes('com.facebook.katana') && m[v].includes('com.instagram.android')));

// IMAGE_CAPTURE_SECURE 仅 1.4.2
ck('IMAGE_CAPTURE_SECURE 1.4.2 独有', m['1.4.2'].includes('IMAGE_CAPTURE_SECURE') && !m['1.0.3'].includes('IMAGE_CAPTURE_SECURE') && !m['1.0.1'].includes('IMAGE_CAPTURE_SECURE'));

// uses-feature 六条可选，三版全同
const feats = ['camera.any', 'camera"', 'camera.autofocus', 'camera.flash', 'screen.portrait', 'screen.landscape'];
for (const v of ['1.0.1', '1.0.3', '1.4.2']) {
  ck(`uses-feature 六项 @${v}`, feats.every(f => m[v].includes(`android.hardware.${f.replace('"', '')}`) || m[v].includes(`"${f.replace('"', '')}"`)));
  ck(`uses-feature 全可选 @${v}`, !/uses-feature[\s\S]{0,120}required="true"/.test(m[v]));
}

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
