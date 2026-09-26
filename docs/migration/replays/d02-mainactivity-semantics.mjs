// Phase 832 — MainActivity dispatch/lifecycle 体语义
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const ma = readFileSync(join(S, 'com/gingerlabs/notability/app/MainActivity.java'), 'utf8');
const oim = readFileSync(join(S, 'defpackage/oim.java'), 'utf8');
const strings = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// override 清单（15 个）
const overrides = ['dispatchGenericMotionEvent', 'dispatchKeyEvent', 'dispatchTouchEvent',
  'onActivityResult', 'onConfigurationChanged', 'onCreate', 'onDestroy', 'onNewIntent',
  'onPause', 'onProvideKeyboardShortcuts', 'onResume', 'onSaveInstanceState',
  'onStart', 'onTopResumedActivityChanged', 'onUserInteraction'];
ck('15 个 override 全部存在', overrides.every(o => ma.includes(o)));

// dispatchKeyEvent 细节
ck('文本域短路 qdn.a', ma.includes('qdn.a(keyEvent)'));
ck('New Window 门控 oim.a', /vla\.a\(keyEvent\)[\s\S]{0,900}oim\.a\(configuration\)/.test(ma));
ck('oim.a = sw>=600dp', oim.includes('smallestScreenWidthDp >= 600'));
ck('和弦→action 发射 bma.a.f', ma.includes('bmaVar.a.f(amaVarB)') || ma.includes('.a.f(amaVar'));

// 其余 dispatch
ck('触摸 SecurityException 守卫 nxb', /dispatchTouchEvent[\s\S]{0,400}SecurityException[\s\S]{0,200}nxb/.test(ma));
ck('三条 dispatch 埋点 fzm', ['fzm.b(motionEvent)', 'fzm.c(keyEvent)', 'fzm.d(motionEvent)'].every(f => ma.includes(f)));

// 更新流
ck('onActivityResult 1123 更新流', /onActivityResult[\s\S]{0,300}1123/.test(ma));
ck('AppUpdateFailed 埋点', ma.includes('"AppUpdateFailed"'));
ck('阻断对话框 Cancelable=false', /setCancelable\(false\)[\s\S]{0,200}app__update_action_update/.test(ma) || ma.includes('setCancelable(false)'));
const updateStrings = ['app__update_required_title', 'app__update_required_message', 'app__update_action_update', 'app__update_action_exit', 'app__update_action_later', 'app__update_action_restart'];
ck('更新对话框 6 字符串族', updateStrings.every(s => strings.includes(`"${s}"`)));

// 生命周期
ck('showWhenLockedPolicy 持久化', ma.includes('"showWhenLockedPolicy"'));
ck('onStart→r() 锁屏策略重算', /onStart[\s\S]{0,200}r\(\)/.test(ma) && ma.includes('setShowWhenLocked'));
ck('onTopResumed 重跑配置', /onTopResumedActivityChanged\(boolean z\)[\s\S]{0,300}n\(configuration\)/.test(ma));
ck('onUserInteraction ow3.a', /onUserInteraction[\s\S]{0,200}ow3\.a/.test(ma));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
