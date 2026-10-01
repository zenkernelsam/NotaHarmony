// Phase 1420 — 文本编辑键盘和弦补齐 + DESELECT 更正
// 证据链：syh.a = ra8→qa8 帮助表（txm 分组注册）；e0b = h3a/ya8
// 文本域真实 KeyEvent 分发器；zs9 = ofk.e(Android keyCode) 常量表。
//   Ctrl+Shift+B/L/C → TOGGLE_BULLET/NUMBERED/CHECKLIST_LIST
//     (syh qa8(30/40/31,4)：mask4→ctrl+shift)；
//   Alt+Up/Down → INCREASE/DECREASE_FONT_SIZE
//     (e0b 运行时门 isCtrlPressed()||!isAltPressed()||isShiftPressed()
//      的 else 支 = alt&&!ctrl&&!shift；syh 另列 Ctrl+Alt+Up/Down——
//      qa8(19/20,8)；两和弦皆绑 stepFontSize(±1))；
//   Ctrl+\ → DESELECT（zs9.l=ofk.e(73)=KEYCODE_BACKSLASH；
//     syh qa8(73,12) 同证——Harmony 早期误植 Ctrl+D(2020) 已更正为 2061）。
// qa8(int,int) 掩码反向：bit1/2/3 置位 = ctrl/alt/shift 缺席。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const syh = fs.readFileSync(`${S}/syh.java`, 'utf8');
const e0b = fs.readFileSync(`${S}/e0b.java`, 'utf8');
const zs9 = fs.readFileSync(`${S}/zs9.java`, 'utf8');
const qa8 = fs.readFileSync(`${S}/qa8.java`, 'utf8');
const overlay = fs.readFileSync(`${H}/ets/ui/components/TextBlockOverlay.ets`, 'utf8');

// ---- 原版锚点 ----
check('syh 注册 Ctrl+Shift+B/L/C 列表切换',
  /TOGGLE_BULLET_LIST, oag\.x2\(new qa8\(30, 4\)\)/.test(syh) &&
  /TOGGLE_NUMBERED_LIST, oag\.x2\(new qa8\(40, 4\)\)/.test(syh) &&
  /TOGGLE_CHECKLIST, oag\.x2\(new qa8\(31, 4\)\)/.test(syh));
check('syh 注册字体步进/段落首尾和弦',
  /INCREASE_FONT_SIZE, oag\.x2\(new qa8\(19, 8\)\)/.test(syh) &&
  /DECREASE_FONT_SIZE, oag\.x2\(new qa8\(20, 8\)\)/.test(syh) &&
  /HOME, oag\.x2\(new qa8\(19, 10\)\)/.test(syh) &&
  /END, oag\.x2\(new qa8\(20, 10\)\)/.test(syh));
check('syh DESELECT = qa8(73,12)=Ctrl+\\\\',
  /DESELECT, oag\.x2\(new qa8\(73, 12\)\)/.test(syh));
check('zs9.l = ofk.e(73)（BACKSLASH）', /l = ofk\.e\(73\)/.test(zs9));
check('e0b alt&&!ctrl&&!shift 门分发字体步进',
  /isCtrlPressed\(\) \|\| !keyEvent2?\.isAltPressed\(\) \|\| keyEvent2?\.isShiftPressed\(\)/.test(e0b) &&
  /INCREASE_FONT_SIZE : ra8\.DECREASE_FONT_SIZE/.test(e0b));
check('e0b ctrl 支 DESELECT=zs9.l(73)', /pa8\.a\(jE2, zs9\.l\)\)[\s\S]{0,80}ra8\.DESELECT/.test(e0b));
check('qa8 掩码反向（bit 置位=修饰缺席）',
  qa8.includes('this(i, (i2 & 2) == 0, (i2 & 4) == 0, (i2 & 8) == 0)'));

// ---- Harmony 实现 ----
const handler = overlay.slice(overlay.indexOf('private onEditorKeyEvent'));
const end = handler.indexOf('\n  private collapseSelection');
const seg = handler.slice(0, end);
check('读取 ctrl/alt/shift 三修饰',
  seg.includes("getModifierKeyState(['alt'])") &&
  seg.includes("getModifierKeyState(['shift'])"));
check('Ctrl+Shift+B/L/C → toggleDecoratorStyle(1/2/3)',
  /ctrl && shift && !alt[\s\S]{0,200}2018[\s\S]{0,80}toggleDecoratorStyle\(1\)[\s\S]{0,200}2028[\s\S]{0,80}toggleDecoratorStyle\(2\)[\s\S]{0,200}2019[\s\S]{0,80}toggleDecoratorStyle\(3\)/.test(seg));
check('Ctrl+Alt+Up/Down → stepFontSize(±1)',
  /ctrl && alt && !shift[\s\S]{0,120}2012[\s\S]{0,80}stepFontSize\(1\)[\s\S]{0,120}2013[\s\S]{0,80}stepFontSize\(-1\)/.test(seg));
check('Alt+Up/Down → stepFontSize(±1)（e0b 运行时分发）',
  /alt && !shift\)[\s\S]{0,120}2012[\s\S]{0,80}stepFontSize\(1\)[\s\S]{0,120}2013[\s\S]{0,80}stepFontSize\(-1\)/.test(seg));
check('DESELECT = Ctrl+\\（2061）非 Ctrl+D（2020）',
  seg.includes('2061') && seg.includes('KEYCODE_BACKSLASH = DESELECT') &&
  !/2020.*DESELECT|DESELECT.*2020/.test(seg));
check('纯 Ctrl+B/I/U 限定 !shift && !alt（与列表和弦不冲突）',
  /ctrl && !alt && !shift\)[\s\S]{0,200}2018[\s\S]{0,80}toggleCharStyle\('bold'\)/.test(seg));
check('lease 门控保留', seg.includes('this.photoImportLeaseActive'));
check('KeyType.Down 分发保留', seg.includes('event.type !== KeyType.Down'));

console.log(`\nD02_ORIGINAL_TEXT_KBD_CHORDS_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
