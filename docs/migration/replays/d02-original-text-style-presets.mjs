// D02 原版字体样式预设 Replay —— Phase 689
// 证据：原版 i31 字体样式面板项 → ix4Var.invoke(new ote(hr4Var))；
// cve ote 分支 → n(new zyd(hr4.I, Boolean.FALSE, null,null,null,
// Float(hr4.J), null,... 2012)) —— {bold,italic:false,fontSize} 原子写。
// hr4 枚举：LargeTitle(36,true)/Heading1(30,true)/Heading2(24,true)/
// Heading3(18,true)/Body(14,false,=K 缺省)/Caption(12,false)；
// cve.l(f) → zyd.f=Float(rh8.u(f,4,72)) 字号字段 clamp [4,72]。
// Harmony：bindMenu 6 预设 → applyTextStylePreset 原子三字段区间写；
// 折叠光标写 pending{bold,italic:false,fontSize}，pending 落地经
// applyCharStyle(bold/italic) + applyFontSize。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const hr4 = fs.readFileSync(`${D}/sources/defpackage/hr4.java`, 'utf8');
const i31 = fs.readFileSync(`${D}/sources/defpackage/i31.java`, 'utf8');
const stringsXml = fs.readFileSync(`${D}/resources/res/values/strings.xml`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const model = fs.readFileSync(
  'note/src/main/ets/core/model/ElementTypes.ets', 'utf8').replaceAll('\r\n', '\n');
const stringsEn = fs.readFileSync(
  'note/src/main/resources/base/element/string.json', 'utf8');
const stringsZh = fs.readFileSync(
  'note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0, failed = 0;
function check(cond, name) {
  total++;
  if (!cond) {
    failed++;
    console.error(`FAIL ${name}`);
  }
}

// ===== 原版证据钉 =====
check(cve.includes('nueVar instanceof ote') &&
  cve.includes('hr4 hr4Var = ((ote) nueVar).a') &&
  cve.includes('Float.valueOf(hr4Var.J)') &&
  cve.includes('2012));'),
  'cve ote: preset → zyd{hr4.I,italic:FALSE,hr4.J} mask2012');
check(cve.includes('n(new zyd(null, null, null, null, null, Float.valueOf(rh8.u(f, 4.0f, 72.0f))'),
  'cve l(f): fontSize field clamped [4,72]');
check(hr4.includes('new gr4("LargeTitle", 0, true, 36.0f)') &&
  hr4.includes('new dr4("Heading1", 1, true, 30.0f)') &&
  hr4.includes('new er4("Heading2", 2, true, 24.0f)') &&
  hr4.includes('new fr4("Heading3", 3, true, 18.0f)') &&
  hr4.includes('new br4("Body", 4, false, 14.0f)') &&
  hr4.includes('new cr4("Caption", 5, false, 12.0f)') &&
  hr4.includes('K = br4Var'),
  'hr4 enum: 6 presets, Body is default K');
check(i31.includes('ix4Var.invoke(new ote(hr4Var))'),
  'i31 font-style picker → ote(hr4)');
check(stringsXml.includes('<string name="ui_text__font_style_large_title">Large Title</string>') &&
  stringsXml.includes('<string name="ui_text__font_style_body">Body</string>') &&
  stringsXml.includes('<string name="ui_text__font_style_caption">Caption</string>'),
  'original font-style strings');

// ===== Harmony 结构钉 =====
check(model.includes('fontSize?: number'),
  'RichTextCharacterStyle.fontSize field exists');
check(overlay.includes('private applyTextStylePreset(bold: boolean, fontSize: number): void') &&
  overlay.includes('mid.bold = bold;') &&
  overlay.includes('mid.italic = false;') &&
  overlay.includes('mid.fontSize = fontSize;'),
  'applyTextStylePreset writes {bold,italic:false,fontSize} atomically');
check(overlay.includes('style: { bold: bold, italic: false, fontSize: fontSize }'),
  'gap-fill carries the full preset triple');
check(overlay.includes('this.pendingCharStyles.bold = bold;') &&
  overlay.includes('this.pendingCharStyles.italic = false;') &&
  overlay.includes('this.pendingCharStyles.fontSize = fontSize;'),
  'collapsed caret → pending preset merge');
check(overlay.includes('private applyFontSize(size: number | null, s: number, e: number): void') &&
  overlay.includes('mid.fontSize = size === null ? undefined : size;') &&
  overlay.includes('style: { fontSize: size }'),
  'applyFontSize range write (pending-apply path)');
check(overlay.includes('this.applyFontSize(this.pendingCharStyles.fontSize,'),
  'pending fontSize applied to typed text');
check(overlay.includes('private buildTextStyleMenu(): MenuElement[]') &&
  overlay.includes('this.applyTextStylePreset(true, 36);') &&
  overlay.includes('this.applyTextStylePreset(true, 30);') &&
  overlay.includes('this.applyTextStylePreset(true, 24);') &&
  overlay.includes('this.applyTextStylePreset(true, 18);') &&
  overlay.includes('this.applyTextStylePreset(false, 14);') &&
  overlay.includes('this.applyTextStylePreset(false, 12);'),
  '6-preset menu mirrors hr4 (sizes + bold flags)');
check(overlay.includes("$r('app.string.text_style')") &&
  overlay.includes('.bindMenu(this.buildTextStyleMenu())'),
  'Style button + bindMenu');
check(overlay.indexOf("$r('app.string.text_style')") <
  overlay.indexOf("$r('app.string.bold')"),
  'Style button leads the format row (i31 panel position)');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "text_style"') &&
  stringsEn.includes('"name": "font_style_large_title"') &&
  stringsEn.includes('"name": "font_style_caption"'),
  'en strings');
check(stringsZh.includes('"name": "text_style"') &&
  stringsZh.includes('"value": "大标题"') &&
  stringsZh.includes('"value": "正文"'),
  'zh strings');

console.log(`D02_ORIGINAL_TEXT_STYLE_PRESETS_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
