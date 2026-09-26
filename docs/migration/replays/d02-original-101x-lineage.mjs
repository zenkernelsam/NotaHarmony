// D02 原版 1.0.x 线内差 + 三版谱系 — Phase 797
import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = 'C:/Users/Cisco He/Desktop/Notability';
const s101 = fs.readFileSync(`${root}/decompiled_1.0.1/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync(`${root}/decompiled_1.0.3/resources/res/values/strings.xml`, 'utf8');
const m101 = fs.readFileSync(`${root}/decompiled_1.0.1/resources/AndroidManifest.xml`, 'utf8');
const m103 = fs.readFileSync(`${root}/decompiled_1.0.3/resources/AndroidManifest.xml`, 'utf8');
const m142 = fs.readFileSync(`${root}/decompiled_1.4.2/resources/AndroidManifest.xml`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('version lineage registered: 1.0.1=1001, 1.0.3=1014, 1.4.2=1040002',
  m101.includes('android:versionCode="1001"')
  && m103.includes('android:versionCode="1014"')
  && m142.includes('android:versionCode="1040002"'));
check('1.0.3 adds account-deletion state machine keys',
  ['feature_settings__account_deletion_confirm_delete',
    'feature_settings__account_deletion_in_progress',
    'feature_settings__account_deletion_sync_failed_title',
    'app__account_deletion_notice_title']
    .every((k) => s103.includes(`name="${k}"`) && !s101.includes(`name="${k}"`)));
check('1.0.3 adds logout sync-status family',
  ['feature_settings__logout_syncing', 'feature_settings__logout_synced_title',
    'feature_settings__logout_sync_now', 'feature_settings__logout_unsynced_title',
    'feature_settings__sign_out_countdown']
    .every((k) => s103.includes(`name="${k}"`) && !s101.includes(`name="${k}"`)));
check('paywall copy restructured (old labels removed, new keys added)',
  !s103.includes('feature_paywall__lite_feature_1_label')
  && s101.includes('feature_paywall__lite_feature_1_label')
  && s103.includes('feature_paywall__current_plan')
  && s103.includes('feature_paywall__discount_original_price')
  && s103.includes('feature_paywall__period_noun_month')
  && s103.includes('feature_paywall__plan_name_starter_short'));
check('1.0.x string growth modest (+21 net): 1482 -> 1503',
  (s103.match(/name="/g) || []).length === 1503
  && (s101.match(/name="/g) || []).length === 1482);
check('no com.gingerlabs package additions between 1.0.1 and 1.0.3',
  (() => {
    const dirs = (v) => {
      const base = `${root}/decompiled_${v}/sources`;
      const out = new Set();
      const walk = (d) => {
        for (const e of fs.readdirSync(d, { withFileTypes: true })) {
          if (!e.isDirectory()) continue;
          const p = `${d}/${e.name}`;
          out.add(p.slice(base.length + 1));
          walk(p);
        }
      };
      if (fs.existsSync(base)) walk(base);
      return out;
    };
    const a = dirs('1.0.1'), b = dirs('1.0.3');
    return [...b].filter((x) => x.startsWith('com/gingerlabs'))
      .every((x) => a.has(x));
  })());

console.log(`101x-lineage replay: ${checks.length}/${checks.length} checks green`);
