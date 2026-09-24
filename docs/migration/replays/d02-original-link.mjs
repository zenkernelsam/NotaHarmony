// D02 原版链接 Replay —— Phase 692
// 证据：原版 tqe.LINK(4) 选择菜单项 → tm5→en5{title,url,edit} 链接对话
// 框态；tte=OnHyperlinkConfirmed(url,linkTitle) → cve 分支
// j().e.l(tteVar.b, zyd{...,link:url,...,1919}) —— fm7.l(title,zyd) 即
// replaceSelectedText：选区替换为标题文本并写 {link:url}；
// aue/wm5=OnRemoveLink → fm7.removeHyperlinkFromSelection 清选区链接。
// Harmony：Link 钮 bindSheet（URL+标题双输入、标题非空才可确认=
// en5.c 语义）→ confirmLink 替换选区/插题文 + applyLinkUrl 写/清
// link run；Remove Link=清除。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
const tte = fs.readFileSync(`${D}/sources/defpackage/tte.java`, 'utf8');
const fm7 = fs.readFileSync(`${D}/sources/defpackage/fm7.java`, 'utf8');
const ose = fs.readFileSync(`${D}/sources/defpackage/ose.java`, 'utf8');
const stringsXml = fs.readFileSync(`${D}/resources/res/values/strings.xml`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const model = fs.readFileSync(
  'note/src/main/ets/core/model/ElementTypes.ets', 'utf8').replaceAll('\r\n', '\n');
const renderer = fs.readFileSync(
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8').replaceAll('\r\n', '\n');
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
check(cve.includes('nueVar instanceof tte') &&
  cve.includes('j().e.l(tteVar.b, new zyd(null, null, null, null, null, null, null, tteVar.a'),
  'cve tte: confirmed link → e.l(title, zyd{link:url})');
check(cve.includes('nueVar.equals(aue.a)') &&
  cve.includes('"removeHyperlinkFromSelection"'),
  'cve aue: OnRemoveLink → removeHyperlinkFromSelection');
check(tte.includes('OnHyperlinkConfirmed(url=') &&
  tte.includes('linkTitle='),
  'tte = OnHyperlinkConfirmed{url, linkTitle}');
check(fm7.includes('public final void l(String str, zyd zydVar)') &&
  fm7.includes('"replaceSelectedText"'),
  'fm7.l = replaceSelectedText(title, zyd)');
check(ose.includes('cveVar.k(new mte(um5Var.a, um5Var.b))') &&
  ose.includes('cveVar.k(aue.a)'),
  'ose: um5→mte edit-request / wm5→aue remove dispatch');
check(zyd.includes('public final String h'),
  'zyd.h = link payload slot');
check(stringsXml.includes('<string name="ui_text__link">Link</string>') &&
  stringsXml.includes('<string name="ui_text__link_title">Link title</string>'),
  'original link strings');

// ===== Harmony 结构钉 =====
check(model.includes('link?: string'),
  'RichTextCharacterStyle.link field exists');
check(renderer.includes('characterStyles[linkIndex]?.link !== undefined'),
  'renderer recognizes link runs');
check(overlay.includes('private applyLinkUrl(url: string | null, s: number, e: number): void') &&
  overlay.includes('mid.link = url === null ? undefined : url;') &&
  overlay.includes('style: { link: url }'),
  'applyLinkUrl writes/clears the run field');
check(overlay.includes('private linkUrlAt(s: number, e: number): string') &&
  overlay.includes('run.style.link !== undefined'),
  'linkUrlAt prefills existing link (um5→mte semantics)');
check(overlay.includes('private openLinkSheet(): void') &&
  overlay.includes('this.draftText.substring(s, e)') &&
  overlay.includes('this.linkUrlAt(s, e)'),
  'openLinkSheet prefills title=selection + url=existing link');
check(overlay.includes('private confirmLink(): void') &&
  overlay.includes('this.draftText.substring(0, s) + title +') &&
  overlay.includes('this.adjustCharRunsForEdit(this.draftText, previous)') &&
  overlay.includes('this.applyLinkUrl(url, s, s + title.length)') &&
  overlay.includes('this.onDraftChange(this.draftText)'),
  'confirmLink = replaceSelectedText + {link:url} (fm7.l semantics)');
check(overlay.includes('private removeLink(): void') &&
  overlay.includes('this.applyLinkUrl(null, s, e)'),
  'removeLink clears the selection link field (aue semantics)');
check(overlay.includes('@State showLinkSheet: boolean = false') &&
  overlay.includes('private buildLinkSheet(): void') &&
  overlay.includes("$r('app.string.link_url_hint')") &&
  overlay.includes("$r('app.string.link_title_hint')") &&
  overlay.includes('this.linkUrlDraft.trim().length > 0 &&\n            this.linkTitleDraft.length > 0'),
  'link sheet: url+title inputs, title-gated confirm (en5.c)');
check(overlay.includes("$r('app.string.text_link')") &&
  overlay.includes('this.openLinkSheet()'),
  'Link button + sheet binding');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "text_link"') &&
  stringsEn.includes('"name": "add_link"') &&
  stringsEn.includes('"name": "remove_link"') &&
  stringsEn.includes('"name": "link_title_hint"'),
  'en strings');
check(stringsZh.includes('"name": "text_link"') &&
  stringsZh.includes('"value": "链接"') &&
  stringsZh.includes('"value": "移除链接"'),
  'zh strings');

console.log(`D02_ORIGINAL_LINK_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
