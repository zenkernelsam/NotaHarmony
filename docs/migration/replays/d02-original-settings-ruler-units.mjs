// Phase 675 — 原版 ruler_units 设置行（x22 case 4 + n94 单位选择器 +
// o59.n/oof 序列化 + ub5 默认 IMPERIAL）。
// 原版证据（decompiled_1.0.3）：
//   x22.java     case 4 渲染 feature_settings__ruler_units 行（设置列表
//     位于 straight_lines(0)/shapes(1)/palm(2)/auto_deselect(3) 与
//     language(5) 之间）。
//   n94.java     case 1：遍历 oof.N=[IMPERIAL,METRIC]，每单位一个
//     apb.e 选择项，点选经 vc→wb5→fr2 写偏好。
//   ss8.java     case 8：tk8Var2.g(o59.n, oofVar.I) —— 写入 "rulerUnits"。
//   o59.java     n = new eua("rulerUnits")。
//   oof.java     IMPERIAL("Imperial") / METRIC("Metric")，N 顺序
//     Imperial→Metric；I = 序列化名。
//   ub5.java     默认构造 rulerUnits=IMPERIAL。
//   vnh.java     c(oof) → feature_settings__imperial/metric 显示名。
//   s01.java     a0() 过滤 a6f.T(RULER) —— 尺具本身在 1.0.3 全部被
//     工具箱列表隐藏；设置行仍然可见（本次按原版表面移植）。
// Harmony 对齐：EditorSettingsStore rulerUnits 键 + Imperial/Metric
// 序列化 + 默认 Imperial；SettingsPage 在 auto_deselect_eraser 与
// language 之间新增 ruler_units 行，尾部显示当前单位，点击打开
// RulerUnitsDialog（Imperial/Metric 两项、当前项 ✓、点选即写并关闭）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const x22 = fs.readFileSync(`${originalRoot}sources/defpackage/x22.java`, 'utf8');
const n94 = fs.readFileSync(`${originalRoot}sources/defpackage/n94.java`, 'utf8');
const o59 = fs.readFileSync(`${originalRoot}sources/defpackage/o59.java`, 'utf8');
const oof = fs.readFileSync(`${originalRoot}sources/defpackage/oof.java`, 'utf8');
const ub5 = fs.readFileSync(`${originalRoot}sources/defpackage/ub5.java`, 'utf8');
const s01 = fs.readFileSync(`${originalRoot}sources/defpackage/s01.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const store = fs.readFileSync('note/src/main/ets/data/EditorSettingsStore.ets', 'utf8');
const settings = fs.readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const fake = fs.readFileSync('note/src/test/EditorViewModel.test.ets', 'utf8');
const baseJson = JSON.parse(fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(x22.includes('feature_settings__ruler_units'), 'x22 case 4 label');
check(/case 4[\s\S]{0,600}feature_settings__ruler_units/.test(x22), 'x22 case 4 wiring');
check(n94.includes('oof.N') && n94.includes('oofVar'), 'n94 iterates oof.N');
check(o59.includes('new eua("rulerUnits")'), 'o59.n key name');
check(oof.includes('IMPERIAL("Imperial")') && oof.includes('METRIC("Metric")'),
  'oof serialized names');
check(ub5.includes('oof.IMPERIAL'), 'ub5 default IMPERIAL');
check(/a0\([\s\S]*?!= a6f\.T/.test(s01), 's01.a0 hides RULER from toolbox');
check(stringsXml.includes('<string name="feature_settings__ruler_units">Ruler units</string>'),
  'original EN title');
check(stringsXml.includes('<string name="feature_settings__imperial">Imperial</string>'),
  'original EN imperial');
check(stringsXml.includes('<string name="feature_settings__metric">Metric</string>'),
  'original EN metric');

// --- Store ---
check(store.includes("const RULER_UNITS_KEY: string = 'rulerUnits'"), 'pref key = o59.n');
check(store.includes("RULER_UNITS_IMPERIAL: string = 'Imperial'"), 'Imperial = oof.I');
check(store.includes("RULER_UNITS_METRIC: string = 'Metric'"), 'Metric = oof.I');
check(store.includes('DEFAULT_RULER_UNITS: string = RULER_UNITS_IMPERIAL'),
  'default IMPERIAL (ub5)');
check(store.includes('getRulerUnits()') && store.includes('saveRulerUnits(units'),
  'iface + impl');
check(/getRulerUnits[\s\S]*?units === RULER_UNITS_IMPERIAL \|\| units === RULER_UNITS_METRIC/
  .test(store), 'invalid value falls back to default');
check(store.includes('getStringPref') && store.includes('saveStringPref'),
  'generic string pref helpers');

// --- SettingsPage ---
check(settings.includes('@State rulerUnits: string = DEFAULT_RULER_UNITS'), 'state');
check(settings.includes('await store.getRulerUnits()'), 'load');
check(settings.includes('this.rulerUnits = rulerUnits'), 'load assign');
check(settings.includes("$r('app.string.ruler_units')"), 'row title label');
check(/rulerUnits === RULER_UNITS_METRIC[\s\S]{0,80}metric[\s\S]{0,80}imperial/
  .test(settings), 'trailing value shows current unit');
check(settings.includes('rulerUnitsDialog.open()'), 'row opens picker');
check(settings.includes('RulerUnitsDialog({'), 'dialog builder');
check(settings.includes('setRulerUnits(units)'), 'onPick wiring');
check(/setRulerUnits[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setRulerUnits[\s\S]*?rulerUnits = previous/.test(settings), 'rollback');
check(/setRulerUnits[\s\S]*?units !== RULER_UNITS_IMPERIAL && units !== RULER_UNITS_METRIC/
  .test(settings), 'setter rejects invalid units');
// 行序：auto_deselect_eraser → ruler_units → language（x22 case 3→4→5）
const adIdx = settings.indexOf("auto_deselect_eraser'))");
const ruIdx = settings.indexOf("ruler_units'))");
const langIdx = settings.indexOf("$r('app.string.language')");
check(adIdx > 0 && ruIdx > adIdx && langIdx > ruIdx, 'row order x22 3→4→5');
// 选择器：oof.N 顺序 Imperial→Metric + 当前项 ✓ + 点选关闭
check(/units: RULER_UNITS_IMPERIAL[\s\S]{0,120}units: RULER_UNITS_METRIC/.test(settings),
  'picker order oof.N');
check(/option\.units === this\.selected[\s\S]{0,200}✓/.test(settings), 'selected checkmark');
check(/controller\.close\(\)[\s\S]{0,80}onPick\(option\.units\)/.test(settings),
  'pick closes dialog then writes');

// --- Strings ---
check(baseVal('ruler_units') === 'Ruler units', 'EN title verbatim');
check(baseVal('imperial') === 'Imperial', 'EN imperial verbatim');
check(baseVal('metric') === 'Metric', 'EN metric verbatim');
check(zhVal('ruler_units')?.length > 0, 'zh title');
check(zhVal('imperial')?.length > 0, 'zh imperial');
check(zhVal('metric')?.length > 0, 'zh metric');

// --- Test fake ---
check(fake.includes('getRulerUnits') && fake.includes('saveRulerUnits'), 'fake methods');

console.log(`TOTAL=${n}`);
