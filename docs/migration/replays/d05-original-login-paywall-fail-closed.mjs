// D05 原版登录+付费墙面 fail-closed — Phase 714（ADR-0662）。
// feature_login__*（55 串）OAuth/邮箱登录 + feature_paywall__*（101 串）
// Play/Samsung 双计费客户端 + 私有 receipt 校验网关；Harmony 无账号/
// 订阅后端，缺席即边界。
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const nq7 = read(`${JADX}/sources/defpackage/nq7.java`);
const hye = read(`${JADX}/sources/defpackage/hye.java`);
const bba = read(`${JADX}/sources/defpackage/bba.java`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版登录面 ---
for (const s of ['welcome_to_notability', 'continue_with_apple',
  'continue_with_google', 'continue_with_microsoft', 'email_address',
  'enter_password', 'create_a_free_account',
  'a_link_has_been_sent_to_your_email_address', 'benefit_cloud_backup',
  'benefit_cross_device']) {
  check(strings.includes(`feature_login__${s}`), `strings login ${s}`);
}
check(nq7.includes('feature_login__welcome_to_notability') &&
  nq7.includes('feature_login__sticker_grow'),
  'nq7 渲染欢迎屏+贴纸轮播');

// --- 原版付费墙面 ---
for (const s of ['current_plan', 'badge_most_popular', 'badge_most_powerful',
  'classic_feature_1', 'discount_original_price', 'error_load_products',
  'error_purchase_already_owned', 'error_purchase_cancelled',
  'error_restore_incomplete', 'samsung_already_claimed']) {
  check(strings.includes(`feature_paywall__${s}`), `strings paywall ${s}`);
}
check(hye.includes('feature_paywall__'), 'hye 付费墙 UI');
check(bba.includes('error_purchase_acknowledgment') &&
  bba.includes('samsung_already_claimed'), 'bba 购买/恢复错误映射');

// --- 计费后端：Play + Samsung + 私有校验网关 ---
const base = `${JADX}/sources/com/gingerlabs/notability/data`;
for (const rel of [
  'billing/client/PlayBillingClient$BillingException.java',
  'samsungbilling/client/SamsungBillingClient$SamsungBillingException.java',
  'billing/gateway/PlayValidationUnavailableException.java',
  'billing/gateway/PlayPurchaseAlreadyClaimedException.java',
  'billing/gateway/PlayPurchaseRejectedException.java']) {
  check(existsSync(`${base}/${rel}`), `计费类 ${rel}`);
}
check(existsSync(`${JADX}/sources/com/android/billingclient/api/ProxyBillingActivity.java`),
  'com.android.billingclient 树存在');

// --- Harmony 侧：登录/订阅面缺席 ---
const walk = (dir) => readdirSync(dir, { withFileTypes: true })
  .flatMap((e) => e.isDirectory() ? walk(`${dir}/${e.name}`) :
    e.name.endsWith('.ets') ? [`${dir}/${e.name}`] : []);
for (const f of walk('note/src/main/ets')) {
  check(!/paywall|feature_login|signInWith|BillingClient|purchaseFlow|restorePurchase/i.test(read(f)),
    `${f.split('/').pop()} 无登录/付费墙实现`);
}
const harmonyStrings = read('note/src/main/resources/base/element/string.json');
check(!harmonyStrings.includes('feature_login'), 'Harmony 无 feature_login 字符串');
check(!harmonyStrings.includes('feature_paywall'), 'Harmony 无 feature_paywall 字符串');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0662-original-login-paywall-failclosed.md')
  .includes('SamsungBillingClient'), 'ADR-0662 声明双计费边界');
check(read('docs/migration/evidence/original-login-paywall-jadx-2026-09-26.md')
  .includes('PlayValidationUnavailableException'), '证据文档记录校验网关');

console.log(`D05_ORIGINAL_LOGIN_PAYWALL_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
