// D02 原版 1.4.2 账号面/引导增量/权限差 — Phase 784
// 钉住 ui_account__ 三流程（登出/改密/换号）同步门控语义、
// onboarding +5 与已登记面的绑定、READ_CALENDAR 权限。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const m142 = fs.readFileSync(`${r142}/resources/AndroidManifest.xml`, 'utf8');
const m103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('ui_account__ hosts relocated sign-out flow (re-keyed from settings)',
  s142.includes('ui_account__sign_out_title">')
  && s142.includes('ui_account__sign_out_countdown">')
  && s142.includes('ui_account__sign_out_synced_title">')
  && !s103.includes('ui_account__'));
check('unsynced-loss warning semantics on all three flows',
  s142.includes('unsynced changes which will be lost if you sign out')
  && s142.includes('password reset signs this device out')
  && s142.includes('Signing in removes the notes already on this device'));
check('switch-account spend-link one-shot semantics',
  s142.includes('Signing in with this link uses it up'));
check('countdown button pattern on all three flows',
  s142.includes('sign_out_countdown">Sign out (%1$d)')
  && s142.includes('change_password_confirm_countdown">Continue (%1$d)')
  && s142.includes('switch_account_confirm_countdown">Sign in (%1$d)'));
check('onboarding +5 keys bind to registered surfaces',
  ['first_angle_measure_mode', 'first_rainbow_effect', 'first_ruler_enabled',
    'phone_undo_redo', 'save_as_template']
    .every((k) => s142.includes(`data_onboarding__${k}_tooltip_text">`))
  && !s103.includes('first_angle_measure_mode'));
check('READ_CALENDAR permission added; other deltas already registered',
  m142.includes('android.permission.READ_CALENDAR')
  && !m103.includes('android.permission.READ_CALENDAR')
  && m142.includes('HwrEngineService')
  && m142.includes('ApiGatedFirebaseInitProvider'));

console.log(`account/onboarding replay: ${checks.length}/${checks.length} checks green`);
