// Phase 842 — 计费/订阅失败分类学
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const strings = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 异常文件计数（4 个目录合）
const dirs = ['data/billing/client', 'data/billing/gateway', 'data/samsungbilling/client', 'data/samsungbilling/gateway', 'domain/subscription', 'data/subscription/storage'];
let total = 0;
for (const d of dirs) { try { total += readdirSync(join(B, d)).filter(f => f.endsWith('.java')).length; } catch {} }
ck('计费相关目录异常类≥9', total >= 9);

// Play 关键异常存在
for (const [d, f] of [
  ['data/billing/client', 'PlayBillingClient$BillingException'],
  ['data/billing/gateway', 'PlayPurchaseRejectedException'],
  ['domain/subscription', 'PurchaseAcknowledgmentException'],
  ['domain/subscription', 'RestoreIncompleteException'],
  ['data/billing/gateway', 'PostGrantOverviewRefreshException'],
]) {
  let ok = false;
  try { ok = readFileSync(join(B, d, f + '.java'), 'utf8').includes('Exception'); } catch {}
  ck(`Play 异常 ${f}`, ok);
}
// Samsung 侧
for (const [d, f] of [
  ['data/samsungbilling/client', 'SamsungBillingClient$SamsungBillingException'],
  ['data/samsungbilling/gateway', 'SamsungPurchaseAlreadyClaimedException'],
  ['data/samsungbilling/gateway', 'SamsungValidationUnavailableException'],
  ['domain/subscription', 'SamsungIapDisabledException'],
]) {
  let ok = false;
  try { ok = readFileSync(join(B, d, f + '.java'), 'utf8').includes('Exception'); } catch {}
  ck(`Samsung 异常 ${f}`, ok);
}

// paywall 字符串
ck('paywall 族存在', ['feature_paywall__error_purchase_billing_unavailable', 'feature_paywall__restore_subscribed_elsewhere', 'feature_settings__user_tier_premium'].every(s => strings.includes(`"${s}"`)));
ck('FinishNotes/版本历史 upsell 闸', strings.includes('finish_notes_upgrade') && strings.includes('version_history_upsell_upgrade'));

// Harmony 无订阅面
const settings = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
ck('Harmony 无订阅行', !settings.includes('subscription') && !settings.includes('premium') && !settings.includes('tier'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
