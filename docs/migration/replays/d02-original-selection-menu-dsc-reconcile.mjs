// Phase 678 — 原版选区菜单 dsc 22 项全表对账：CONVERT_*（MyScript iink
// 管线，xsc.p() 后端门禁）/ FIT_TO_PAGE（原版死桩）/ MORE（双行
// showSubmenu）fail-closed/适配登记。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   dsc.java  22 动作枚举：STYLE..MORE。
//   dhb.java  case13 内派发：case11/12 走 j4e/tqd 转换管线
//     （xsc.p() 探测 + ba6.o 页面门禁 + xsc.v 跨页校验）；
//     case15 = throw new NotImplementedError(0)；
//     case21 = 翻转 msc.b（esc 双行 options 的 showSubmenu）。
//   msc.java  ShowMenuOptions{options=esc{primary,submenu},b,c}。
//   com.myscript.iink  原版打包的 MyScript Interactive Ink SDK。
// Harmony 判定：CONVERT_* 无生产 OCR provider（仅测试桩）→
// 菜单缺省与原版 xsc.p() 不可用语义一致（fail-closed）；
// FIT_TO_PAGE 原版即死桩；MORE 为单行适配（ADR-0645）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const dsc = fs.readFileSync(`${originalRoot}sources/defpackage/dsc.java`, 'utf8');
const dhb = fs.readFileSync(`${originalRoot}sources/defpackage/dhb.java`, 'utf8');
const msc = fs.readFileSync(`${originalRoot}sources/defpackage/msc.java`, 'utf8');
const ux9 = fs.readFileSync(`${originalRoot}sources/defpackage/ux9.java`, 'utf8');
const xsc = fs.readFileSync(`${originalRoot}sources/defpackage/xsc.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const overlay = fs.readFileSync('note/src/main/ets/ui/components/SelectionOverlay.ets', 'utf8');
const coordinator = fs.readFileSync(
  'note/src/main/ets/core/adaptation/OriginalHandwritingConversionCoordinator.ets', 'utf8');
const recognition = fs.readFileSync(
  'note/src/main/ets/core/adaptation/OriginalHandwritingRecognition.ets', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉：dsc 22 项枚举 ---
check(dsc.includes('new dsc("STYLE", 0)'), 'dsc.STYLE ordinal0');
check(dsc.includes('new dsc("CONVERT_TO_MATH", 11)'), 'dsc.CONVERT_TO_MATH');
check(dsc.includes('new dsc("CONVERT_TO_TEXT", 12)'), 'dsc.CONVERT_TO_TEXT');
check(dsc.includes('new dsc("FIT_TO_PAGE", 15)'), 'dsc.FIT_TO_PAGE');
check(dsc.includes('new dsc("LOCK", 18)') && dsc.includes('new dsc("UNLOCK", 19)'),
  'dsc.LOCK/UNLOCK');
check(dsc.includes('new dsc("DESELECT", 20)') && dsc.includes('new dsc("MORE", 21)'),
  'dsc.DESELECT/MORE tail');
check(/d0 = new dsc\[\]/.test(dsc), 'dsc.d0 table');

// --- 原版证据钉：派发语义 ---
check(/case 15:\s*\n\s*throw new NotImplementedError\(0\)/.test(dhb),
  'dhb case15 FIT_TO_PAGE dead stub');
check(/case 21:[\s\S]{0,600}new msc\(mscVar\.a, !mscVar\.b, mscVar\.c\)/.test(dhb),
  'dhb case21 MORE toggles msc.b showSubmenu');
check(/case 11:[\s\S]{0,200}isc iscVar = isc\.a;[\s\S]{0,200}xscVar\.p\(\)/.test(dhb),
  'dhb case11 CONVERT_TO_MATH backend probe');
check(/case 12:[\s\S]{0,200}jsc jscVar = jsc\.a;[\s\S]{0,200}xscVar\.p\(\)/.test(dhb),
  'dhb case12 CONVERT_TO_TEXT backend probe');
check(dhb.includes('Math conversion selection spans pages') &&
  dhb.includes('Text conversion selection spans pages'),
  'dhb convert span-pages guards');
check(msc.includes('ShowMenuOptions(options=') && msc.includes('showSubmenu='),
  'msc two-row state');
check(ux9.includes('feature_note__selection_menu_more'), 'ux9 renders MORE row');
check(xsc.includes('public final boolean p()'), 'xsc.p backend probe');

// --- 原版证据钉：字符串 ---
check(stringsXml.includes('selection_menu_convert_to_math'), 'convert_to_math label');
check(stringsXml.includes('selection_menu_convert_to_text'), 'convert_to_text label');
check(stringsXml.includes('selection_menu_fit_to_page'), 'fit_to_page label');
check(stringsXml.includes('selection_menu_more'), 'more label');

// --- Harmony 实现钉：已覆盖项 ---
for (const act of ['COPY', 'CUT', 'DUPLICATE', 'GROUP', 'UNGROUP', 'SEND_FORWARD',
  'SEND_BACKWARD', 'SEND_TO_FRONT', 'SEND_TO_BACK', 'DELETE', 'EDIT_MATH', 'CROP',
  'FLIP_H', 'FLIP_V', 'LOCK', 'DESELECT', 'STYLE', 'PASTE']) {
  check(new RegExp(`${act} = \\d+`).test(overlay), `SelectionMenuAction.${act}`);
}

// --- Harmony fail-closed/适配钉 ---
check(!/CONVERT_TO_MATH\s*=\s*\d/.test(overlay) && !/CONVERT_TO_TEXT\s*=\s*\d/.test(overlay),
  'no CONVERT_* actions (fail-closed)');
check(!/FIT_TO_PAGE\s*=\s*\d/.test(overlay) && !/\bMORE\s*=\s*\d/.test(overlay),
  'no FIT_TO_PAGE/MORE actions');
check(overlay.includes('ADR-0645'), 'overlay comment cites ADR-0645');
check(overlay.includes('msc.b') || overlay.includes('showSubmenu'),
  'overlay comment explains MORE two-row');
check(coordinator.includes('runOriginalHandwritingConversion') &&
  coordinator.includes('selectedStrokeIds'),
  'conversion coordinator scaffold for future CONVERT_TO_TEXT');
check(recognition.includes('interface OriginalHandwritingRecognitionProvider'),
  'recognition provider is an interface (no production impl)');

console.log(`TOTAL=${n}`);
