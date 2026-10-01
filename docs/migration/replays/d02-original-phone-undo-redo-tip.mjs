// Phase 1415 — 原版窄屏撤销/重做引导气泡 PHONE_UNDO_REDO 移植
// 证据链：t0c.M(PHONE_UNDO_REDO)/t0c.L(FIRST_UNDO_REDO)；dhb default
// jh2.d（宽<600）分流；wv9.b 槽位 int → nyi.b→tyi（2=锚点下方,3=锚点左侧）；
// ad case9/8 文案分流。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const REPO = 'C:/HarmonyProject/NotaHarmony';
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const S = `${JADX}/sources/defpackage`;

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = (p) => fs.readFileSync(p, 'utf8');

// ── 原版钉 ──
const t0c = read(`${S}/t0c.java`);
check('t0c 枚举：PHONE_UNDO_REDO(9) 与 FIRST_UNDO_REDO(8) 并存',
  t0c.includes('"PHONE_UNDO_REDO", 9') && t0c.includes('"FIRST_UNDO_REDO", 8'));

const dhb = read(`${S}/dhb.java`);
check('dhb default：jh2.d 分流 M(窄)/L(宽)，槽位 2/3',
  dhb.includes('jh2.d(nc6Var2)') && dhb.includes('zD ? t0c.M : t0c.L') &&
  dhb.includes('zD ? 2 : 3'));

const jh2 = read(`${S}/jh2.java`);
check('jh2.d = 宽<600dp 判定（compact 等价）',
  /boolean d\(qh2[\s\S]*?z4kVar\.a\(600\)/.test(jh2));

const tyi = read(`${S}/tyi.java`);
check('tyi 槽位语义：3=锚点左侧(tyi.b) / 2=锚点下方居中',
  /this\.F;[\s\S]*?i == 3[\s\S]*?return b\(j2/.test(tyi) &&
  tyi.includes('public final long b('));

const ad = read(`${S}/ad.java`);
check('ad case9/8：PHONE_UNDO_REDO/FIRST_UNDO_REDO 文案分流',
  ad.includes('data_onboarding__phone_undo_redo_tooltip_text') &&
  ad.includes('data_onboarding__first_undo_redo_tooltip_text'));

const stringsXml = read(`${JADX}/resources/res/values/strings.xml`);
check('原版文案：phone_undo_redo = "Press to undo, long press to redo"',
  stringsXml.includes(
    '<string name="data_onboarding__phone_undo_redo_tooltip_text">Press to undo, long press to redo</string>'));

// ── Harmony 钉 ──
const store = read(path.join(REPO, 'note/src/main/ets/data/OnboardingTooltipStore.ets'));
check('store: PHONE_UNDO_REDO 入枚举 + isOnboardingTooltipKind 容错表',
  store.includes("PHONE_UNDO_REDO = 'PHONE_UNDO_REDO'") &&
  store.includes('case OnboardingTooltipKind.PHONE_UNDO_REDO'));

const tb = read(path.join(REPO, 'note/src/main/ets/ui/editor/EditorToolbar.ets'));
check('toolbar: compact(<600)=jh2.d 等价已有 onAreaChange 断点',
  tb.includes('newArea.width as number) < 600'));
check('toolbar: canUndo 触发按 compact 选 kind（jh2.d 分流）',
  tb.includes('this.compact ?\n      OnboardingTooltipKind.PHONE_UNDO_REDO') ||
  /this\.compact \?[\s\S]{0,80}PHONE_UNDO_REDO[\s\S]{0,80}FIRST_UNDO_REDO/.test(tb));
check('toolbar: bindPopup 位置窄版 Bottom/宽版 Left（tyi 槽位 2/3）',
  /undoRedoTipKind === OnboardingTooltipKind\.PHONE_UNDO_REDO \?\s*Placement\.Bottom : Placement\.Left/.test(tb));
check('toolbar: 气泡文案按 kind 分流 phone/first',
  tb.includes('data_onboarding__phone_undo_redo_tooltip_text'));
check('toolbar: dismiss 覆盖两种 kind',
  /kind === OnboardingTooltipKind\.FIRST_UNDO_REDO \|\|[\s\S]{0,60}PHONE_UNDO_REDO\)/.test(tb));

const base = read(path.join(REPO, 'note/src/main/resources/base/element/string.json'));
const zh = read(path.join(REPO, 'note/src/main/resources/zh_CN/element/string.json'));
check('en/zh: phone_undo_redo_tooltip_text 双语在档',
  base.includes('"data_onboarding__phone_undo_redo_tooltip_text", "value": "Press to undo, long press to redo"') &&
  zh.includes('"data_onboarding__phone_undo_redo_tooltip_text"'));

console.log(`\nphone-undo-redo-tip replay: ${checks.length}/${checks.length} checks green`);
