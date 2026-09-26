// D02 原版 1.4.2 设置面增量 — Phase 780
// 钉住 +60 新键分族（打字默认/标题模板/TTS/社交/营销）与 −14
// 移除键（logout/theme 重构），及 rcj 的 TTS 滑杆渲染。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const rcj = fs.readFileSync(`${r142}/sources/defpackage/rcj.java`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const families = {
  'typing defaults': ['default_font', 'default_font_size', 'default_font_style',
    'line_spacing', 'grid_spacing', 'check_spelling', 'check_spelling_description'],
  'tap gestures': ['tap_anywhere', 'tap_anywhere_description',
    'two_finger_tap', 'two_finger_tap_description'],
  'note-title template': ['default_note_title', 'prefix', 'suffix',
    'include_date', 'include_time'],
  'tts speed': ['text_to_speech_speed', 'slower', 'faster'],
  'social footer': ['cd_instagram', 'cd_linkedin', 'cd_threads',
    'cd_tiktok', 'cd_youtube'],
  'newsletter': ['newsletter_signup_title', 'newsletter_join',
    'newsletter_use_account_email', 'newsletter_subscribed_title'],
};
for (const [fam, keys] of Object.entries(families)) {
  check(`1.4.2 settings family present: ${fam}`,
    keys.every((k) => s142.includes(`feature_settings__${k}">`)));
  check(`1.0.3 lacked settings family: ${fam}`,
    !keys.some((k) => s103.includes(`feature_settings__${k}">`)));
}
check('logout/theme keys removed by 1.4.2 restructure',
  ['logout_title', 'logout_syncing', 'sign_out', 'stay_signed_in',
    'dark_theme', 'match_system_appearance']
    .every((k) => s103.includes(`feature_settings__${k}">`))
  && ['logout_title', 'sign_out', 'dark_theme']
    .every((k) => !s142.includes(`feature_settings__${k}">`)));
check('rcj renders the text-to-speech speed slider row',
  rcj.includes('feature_settings__text_to_speech_speed'));

console.log(`settings-delta replay: ${checks.length}/${checks.length} checks green`);
