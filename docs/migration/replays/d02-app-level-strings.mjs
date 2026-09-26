// Phase 837 — app__ 顶层字符串族审计
import { readFileSync } from 'node:fs';
import { readdirSync } from 'node:fs';

const strings = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const appKeys = [...strings.matchAll(/name="(app__[a-z_0-9]+)"/g)].map(m => m[1]);
const results = [];
const ck = (n, ok) => results.push([n, ok]);

ck('app__ 族 40 条', appKeys.length === 40);

// 已归因族
for (const k of ['app__update_required_title', 'app__update_ready_title', 'app__update_launch_failed',
  'app__missing_native_library_title', 'app__shortcut_new_note', 'app__shortcut_new_photo',
  'app__open_pdf_failed', 'app__open_pdf_password_protected', 'app__open_pdf_too_large']) {
  ck(`已归因 ${k}`, appKeys.includes(k));
}
ck('kbd_shortcut 族 7 条', appKeys.filter(k => k.startsWith('app__kbd_shortcut_')).length === 7);

// 新登记缺口族
ck('评分族存在', appKeys.filter(k => k.startsWith('app__app_rating')).length >= 5);
ck('分享上限族存在', appKeys.includes('app__note_limit_share_title') && appKeys.includes('app__note_limit_share_message'));
ck('强制登出族存在', appKeys.includes('app__force_logout_title') && appKeys.includes('app__force_logout_message'));
ck('账号删除须知存在', appKeys.includes('app__account_deletion_notice_title'));

// Harmony 反向核对：评分/分享上限/强制登出无实现
const etsFiles = [];
const walk = (d) => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = `${d}/${e.name}`; if (e.isDirectory()) walk(p); else if (e.name.endsWith('.ets')) etsFiles.push(p); } };
walk('C:/HarmonyProject/NotaHarmony/note/src/main/ets');
const allEts = etsFiles.map(f => readFileSync(f, 'utf8')).join('\n');
ck('Harmony 无应用内评分实现', !allEts.includes('appRating') && !allEts.includes('inAppReview'));
ck('Harmony 无分享上限闸', !allEts.includes('note_limit_share') && !allEts.includes('shareLimit'));
ck('Harmony 无强制登出实现', !allEts.includes('force_logout') && !allEts.includes('forceLogout'));
ck('Harmony PDF 错误已映射', allEts.includes('open_pdf_too_large') || allEts.includes('gr9.TooLarge'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
