// Phase 1414 — 原版 oye.n0 权限「Access Required → Go to Settings」对话框移植
// 证据链：iwc 枚举(title/body res) → he0 case12 发起 → oj1 拒绝回调 →
// he0 case11 !shouldShowRationale → jwc.c=true → l8n.d 对话框
// (iwc.G 标题 + iwc.H 正文 + Dismiss + Go to Settings) → s86 case19
// APPLICATION_DETAILS_SETTINGS。
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
const iwc = read(`${S}/iwc.java`);
check('iwc.READ_CALENDAR 携带 required/rationale 资源对',
  iwc.includes('READ_CALENDAR(lwc.READ_CALENDAR') &&
  iwc.includes('ui_permissions__calendar_access_required') &&
  iwc.includes('ui_permissions__calendar_access_rationale'));

const oye = read(`${S}/oye.java`);
const n0 = oye.slice(oye.indexOf('Function0 n0(iwc'));
check('oye.n0: 包装 iwc 权限为 Function0 启动器',
  n0.includes('new jwc(iwcVar, function1)'));
check('oye.n0: jwc.c==true → l8n.d 对话框',
  n0.includes('jwcVar.c') && n0.includes('l8n.d('));
check('oye.n0: 对话框标题/正文 = iwc.G/iwc.H',
  n0.includes('jwcVar2.a.G') && n0.includes('jwcVar2.a.H'));
check('oye.n0: Dismiss 按钮 + Go to Settings lambda',
  n0.includes('ui_permissions__dismiss') && n0.includes('new b8(bz5VarH0, context, jwcVar)'));

const he0 = read(`${S}/he0.java`);
check('he0 case12: 已授权→回调；shouldShowRationale→对话框；否则系统请求',
  he0.includes('dbj.n(context2, str) == 0') && he0.includes('wa.g0(activityC2, str)') &&
  he0.includes('bz5Var2.invoke(str)'));
check('he0 case11: 拒绝回调后 !shouldShowRationale → jwc.c=true',
  /case 11:[\s\S]*?!.*wa\.g0\(activityC[\s\S]*?ptgVar\.j\(value, Boolean\.TRUE\)/.test(he0));

const oj1 = read(`${S}/oj1.java`);
check('oj1: 授权结果分发（granted→function1 / denied→he0 lambda）',
  oj1.includes('zBooleanValue') && oj1.includes('function0.invoke()') &&
  oj1.includes('function1.invoke()'));

const b8 = read(`${S}/b8.java`);
check('b8 case9: Go to Settings 按钮文案 + s86 回调',
  b8.includes('ui_permissions__go_to_settings') && b8.includes('new s86('));

const s86 = read(`${S}/s86.java`);
check('s86 case19: ACTION_APPLICATION_DETAILS_SETTINGS(package Uri)',
  s86.includes('android.settings.APPLICATION_DETAILS_SETTINGS') &&
  s86.includes('Uri.fromParts("package"'));

const kan = read(`${S}/kan.java`);
check('kan.a: Connect 卡 onClick = oye.n0(iwc.READ_CALENDAR)',
  kan.includes('oye.n0(iwc.READ_CALENDAR'));

const stringsXml = read(`${JADX}/resources/res/values/strings.xml`);
check('原版字串值: access_required/rationale/dismiss/go_to_settings',
  stringsXml.includes('<string name="ui_permissions__calendar_access_required">Calendar Access Required</string>') &&
  stringsXml.includes('Your calendar is never changed.') &&
  stringsXml.includes('<string name="ui_permissions__dismiss">Dismiss</string>') &&
  stringsXml.includes('<string name="ui_permissions__go_to_settings">Go to Settings</string>'));

// ── Harmony 钉 ──
const gw = read(path.join(REPO, 'note/src/main/ets/data/OriginalComingUpCalendarGateway.ets'));
check('gateway: 三态 outcome 枚举 GRANTED/DENIED_SHOWN/DENIED_HIDDEN',
  gw.includes('ComingUpCalendarRequestOutcome') && gw.includes('DENIED_SHOWN') &&
  gw.includes('DENIED_HIDDEN') && gw.includes('GRANTED'));
check('gateway: denied 分支读 dialogShownResults[0]（!shouldShowRationale 等价）',
  gw.includes('dialogShownResults'));
check('gateway: 设置页出口 = requestPermissionOnSetting（s86 case19）',
  gw.includes('requestPermissionOnSetting') && gw.includes('openComingUpCalendarSettings'));
check('gateway: 设置开启亦走注入缝（ComingUpCalendarSettingsOpener）',
  gw.includes('ComingUpCalendarSettingsOpener'));

const lp = read(path.join(REPO, 'note/src/main/ets/ui/library/LibraryPage.ets'));
check('LibraryPage: outcome 三态分发 GRANTED→refresh / DENIED_HIDDEN→dialog',
  lp.includes('ComingUpCalendarRequestOutcome.GRANTED') &&
  lp.includes('ComingUpCalendarRequestOutcome.DENIED_HIDDEN') &&
  lp.includes('showCalendarAccessDialog'));
check('LibraryPage: 对话框 = required 标题 + rationale 正文 + Go to Settings/Dismiss',
  lp.includes('calendar_access_required') && lp.includes('calendar_access_rationale') &&
  lp.includes('go_to_settings') && lp.includes('dismiss'));
check('LibraryPage: Go to Settings → openComingUpCalendarSettings',
  lp.includes('openComingUpCalendarSettings(context)'));

const en = JSON.parse(read(path.join(REPO, 'note/src/main/resources/base/element/string.json')));
const zh = JSON.parse(read(path.join(REPO, 'note/src/main/resources/zh_CN/element/string.json')));
const enVals = JSON.stringify(en); const zhVals = JSON.stringify(zh);
check('en: calendar_access_required/rationale 与原版逐字一致',
  enVals.includes('Calendar Access Required') &&
  enVals.includes('Notability needs access to your calendar to show your upcoming events. Your calendar is never changed.'));
check('zh: 日历权限对话框文案已本地化',
  zhVals.includes('需要日历访问权限'));

console.log(`\nhome-calendar-access-dialog replay: ${checks.length}/${checks.length} checks green`);
