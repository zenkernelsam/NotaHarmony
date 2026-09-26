// Phase 829 — 组件属性深检（service/receiver/provider 级属性）
import { readFileSync } from 'node:fs';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const m142 = readFileSync(`${R}/decompiled_1.4.2/resources/AndroidManifest.xml`, 'utf8');
const m103 = readFileSync(`${R}/decompiled_1.0.3/resources/AndroidManifest.xml`, 'utf8');
const m101 = readFileSync(`${R}/decompiled_1.0.1/resources/AndroidManifest.xml`, 'utf8');
const nb103 = readFileSync(`${R}/decompiled_1.0.3/sources/com/gingerlabs/notability/app/NbApplication.java`, 'utf8');

const results = [];
const ck = (name, ok) => results.push([name, ok]);

// ── 应用级 service 属性 ─────────────────────────────────
ck('AudioCaptureService fst=mediaProjection', /AudioCaptureService[\s\S]{0,200}foregroundServiceType="mediaProjection"|foregroundServiceType="mediaProjection"[\s\S]{0,200}AudioCaptureService/.test(m142));
ck('RecordingForegroundService fst=microphone', /RecordingForegroundService[\s\S]{0,200}foregroundServiceType="microphone"|foregroundServiceType="microphone"[\s\S]{0,200}RecordingForegroundService/.test(m142));
ck('HwrEngineService :hwr 进程', /HwrEngineService[\s\S]{0,300}android:process=":hwr"/.test(m142));
ck('应用级 service 均 exp=false', !/<service[^>]*android:exported="true"[^>]*com\.gingerlabs/.test(m142));

// ── 版本差 ─────────────────────────────────────────────
ck('HwrEngineService 1.4.2 新增', m142.includes('HwrEngineService') && !m103.includes('HwrEngineService') && !m101.includes('HwrEngineService'));
ck(':hwr 进程仅 1.4.2', m142.includes(':hwr') && !m103.includes(':hwr'));
ck('1.0.3 NbApplication 无进程守卫', !nb103.includes('getProcessName'));
ck('1.0.3 已有 ProcessFreezeDetector', nb103.includes('ProcessFreezeDetector'));

// ── 应用级 receiver ─────────────────────────────────────
ck('AppUpgradeReceiver MY_PACKAGE_REPLACED', /AppUpgradeReceiver[\s\S]{0,300}MY_PACKAGE_REPLACED/.test(m142));
ck('5 个 WidgetProvider APPWIDGET_UPDATE', (m142.match(/APPWIDGET_UPDATE/g) || []).length >= 5);

// ── 应用级 provider ─────────────────────────────────────
ck('ApiGatedFirebaseInitProvider', m142.includes('ApiGatedFirebaseInitProvider'));
ck('ExportFileProvider', m142.includes('ExportFileProvider'));
ck('WidgetImageProvider', m142.includes('WidgetImageProvider'));
const providers = m142.match(/<provider[\s\S]*?(?:\/>|<\/provider>)/g) || [];
const appProviders = providers.filter(b => (b.match(/name="([^"]+)"/) || [])[1]?.includes('gingerlabs'));
ck('应用级 provider 均 exp=false', appProviders.every(b => b.includes('exported="false"')));
ck('ApiGated initOrder=100+directBootAware', /ApiGatedFirebaseInitProvider[\s\S]{0,300}initOrder="100"/.test(m142) && /ApiGatedFirebaseInitProvider[\s\S]{0,300}directBootAware="true"/.test(m142));
ck('ExportFileProvider 授权+filepaths', /ExportFileProvider[\s\S]{0,400}grantUriPermissions="true"[\s\S]{0,400}filepaths/.test(m142));
ck('WidgetImageProvider 授权', /WidgetImageProvider[\s\S]{0,300}grantUriPermissions="true"/.test(m142));

let pass = 0;
for (const [name, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${name}`); }
  else console.log(`FAIL ${name}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
