// Phase 681 — 原版 QUOTE_AND_CODE_BLOCKS（ac4.R / androidQuoteAndCodeBlocks）：
// 文本框编辑态段落样式工具（Block quote / Code block）+ CODE_BLOCK 渲染。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   ac4.java     99: QUOTE_AND_CODE_BLOCKS ordinal 6，jtb.c 远端键。
//   jtb.java     5:  new jtb("androidQuoteAndCodeBlocks")——远端开关，
//                出厂 defaults 缺席（rollout 门控）。
//   fy2.java     22-23: BLOCK_QUOTE((byte)4) / CODE_BLOCK((byte)5)——
//                段落 decorator 枚举，与既有 1/2/3 同枚举。
//   h32.java     359/369: 文本格式工具条 ui_text__block_quote /
//                ui_text__code_block 图标+文案行（go5.b 菜单项）。
//   ili.java     192: 工具条可见性 = lc4.a(ac4.R)——feature 门控。
//   x90.java     947: !lc4.a(ac4.R) 时读侧 mask（远端关闭即不渲染）。
//   cve.java     201-217: 菜单动作分发 o(fy2.BULLET/NUMBER/CHECK_BOX/
//                BLOCK_QUOTE/CODE_BLOCK)——段落级单选互斥；
//                o() → m(new m5a(fy2Var)) = MODIFY_PARAGRAPH_STYLE CRDT op，
//                CODE_BLOCK 额外携 k5a(this.W) 语言上下文。
//   lj3.java     298/853: CODE_BLOCK 渲染字号 f3=f2-24f（≥1）——等宽+缩字。
//   sq4.java     8: "monospace" FontFamily token——代码字族。
//   strings.xml  1391/1395: "Block quote"/"Code block"。
// Harmony：TextBlockOverlay 编辑态底部行新增两枚段落级切换（光标段落序号
//   驱动 draftStyles，再次点击回 NONE）；提交把段落序号样式折回字符区间
//   run；TextBlockTool.updateText 允许 runs-only 提交；NoteCanvasView
//   onTextCommit 三分支（本地/CRDT 文本变更/CRDT 仅样式）均携 authored runs；
//   Canvas2DTextRenderer 对 decoratorStyle==5 段落切 monospace 字族+整行
//   浅底带（lj3 缩字号 -24f 登记近似）；CRDT 文本块无本地 style-op 编码器，
//   样式写元素级——ADR-0648 注册限制。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const jtb = fs.readFileSync(`${originalRoot}sources/defpackage/jtb.java`, 'utf8');
const fy2 = fs.readFileSync(`${originalRoot}sources/defpackage/fy2.java`, 'utf8');
const h32 = fs.readFileSync(`${originalRoot}sources/defpackage/h32.java`, 'utf8');
const ili = fs.readFileSync(`${originalRoot}sources/defpackage/ili.java`, 'utf8');
const x90 = fs.readFileSync(`${originalRoot}sources/defpackage/x90.java`, 'utf8');
const cve = fs.readFileSync(`${originalRoot}sources/defpackage/cve.java`, 'utf8');
const lj3 = fs.readFileSync(`${originalRoot}sources/defpackage/lj3.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const overlay = fs.readFileSync('note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8');
const tool = fs.readFileSync('note/src/main/ets/rendering/TextBlockTool.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8');
const en = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(ac4.includes('"QUOTE_AND_CODE_BLOCKS", 6'), 'ac4.R = QUOTE_AND_CODE_BLOCKS(6)');
check(jtb.includes('new jtb("androidQuoteAndCodeBlocks")'),
  'remote key androidQuoteAndCodeBlocks');
check(fy2.includes('BLOCK_QUOTE((byte) 4)') && fy2.includes('CODE_BLOCK((byte) 5)'),
  'fy2 decorator enum 4/5');
check(h32.includes('ui_text__block_quote') && h32.includes('ui_text__code_block'),
  'h32 toolbar entries');
check(ili.includes('lc4.a(ac4.R)'), 'ili toolbar visibility = ac4.R gate');
check(x90.includes('!lc4.a(ac4.R)'), 'x90 read-side mask');
check(cve.includes('o(fy2.BLOCK_QUOTE)') && cve.includes('o(fy2.CODE_BLOCK)'),
  'cve dispatch BLOCK_QUOTE/CODE_BLOCK');
check(cve.includes('new m5a(fy2Var)'), 'cve → m5a MODIFY_PARAGRAPH_STYLE op');
check(lj3.includes('fy2.CODE_BLOCK'), 'lj3 code-block render path');
check(stringsXml.includes('<string name="ui_text__block_quote">Block quote</string>') &&
  stringsXml.includes('<string name="ui_text__code_block">Code block</string>'),
  'original strings');

// --- Overlay 编辑态钉 ---
check(overlay.includes("import { RichTextCharacterStyle, RichTextCharacterStyleRun, TextBlockElement, RichTextParagraphStyle, RichTextParagraphStyleRun }"),
  'overlay style imports');
check(overlay.includes('@State caretOffset: number = -1') &&
  overlay.includes('@State caretDecoratorStyle: number = 0') &&
  overlay.includes('private draftStyles: Map<number, RichTextParagraphStyle>'),
  'caret + paragraph-style draft state');
check(overlay.includes('private seedParagraphStyles()') &&
  overlay.includes('this.styleAtChar(runs, paragraphStart)'),
  'element runs → paragraph-index seed');
check(overlay.includes('private paragraphIndexAt(offset: number): number') &&
  overlay.includes('private decoratorAt(offset: number): number'),
  'caret paragraph resolution');
check(overlay.includes('private toggleDecoratorStyle(decorator: number)') &&
  overlay.includes('this.toggleDecoratorStyle(4)') &&
  overlay.includes('this.toggleDecoratorStyle(5)'),
  'quote/code toggle buttons');
check(overlay.includes('this.caretDecoratorStyle === 4') &&
  overlay.includes('this.caretDecoratorStyle === 5'),
  'active-state styling per caret paragraph');
check(overlay.includes("$r('app.string.block_quote')") &&
  overlay.includes("$r('app.string.code_block')"),
  'original button labels');
check(overlay.includes('private computeParagraphRuns(): RichTextParagraphStyleRun[]') &&
  overlay.includes('runs.push({ start: paragraphStart, end: end, style: style })'),
  'paragraph-index → char-range runs');
check(overlay.includes('await this.onCommit(this.draftText, this.draftCharRuns,') &&
  overlay.includes('this.computeParagraphRuns())'),
  'commit emits authored runs');
check(overlay.includes('this.caretDecoratorStyle = this.decoratorAt(end)'),
  'caret move refreshes active state');

// --- TextBlockTool 钉 ---
check(tool.includes('if (text === element.richText && paragraphStyleRuns === undefined)'),
  'runs-only commit bypasses no-op short-circuit');

// --- NoteCanvasView 提交路径钉 ---
check(canvas.includes('async onTextCommit(text: string,\n    characterStyleRuns?: RichTextCharacterStyleRun[],\n    paragraphStyleRuns?: RichTextParagraphStyleRun[])'),
  'onTextCommit accepts authored runs');
check(canvas.includes('const stylesDiffer: boolean = this.editingOriginalTextBlock !== null') &&
  canvas.includes('JSON.stringify(paragraphStyleRuns)') &&
  canvas.includes('JSON.stringify(characterStyleRuns)'),
  'stylesDiffer detection');
check(canvas.includes('(this.editingOriginalTextBlock.richText !== text || stylesDiffer) &&\n        decodeOperationId(this.editingOriginalTextBlock.id) === null'),
  'local path covers style-only commits');
check(canvas.includes('paragraphStyleRuns === undefined ? preview.paragraphStyleRuns : paragraphStyleRuns'),
  'CRDT text-edit path prefers authored runs');
check(/} else if \(stylesDiffer\) \{[\s\S]{0,800}updateText\([\s\S]{0,400}\(this\.editingTextBlock\.paragraphStyleRuns \?\? \[\]\) : paragraphStyleRuns\)/,
  'CRDT style-only element-level apply');
check(canvas.includes('characterStyleRuns: RichTextCharacterStyleRun[],') &&
  canvas.includes('runs: RichTextParagraphStyleRun[]): Promise<boolean> =>') &&
  canvas.includes('await this.onTextCommit(text, characterStyleRuns, runs)'),
  'overlay onCommit wiring');

// --- 渲染器钉 ---
check(renderer.includes('private applyCodeBlockFace(characterStyles: RichTextCharacterStyle[],') &&
  renderer.includes("codeStyle.familyName = 'monospace'"),
  'code-block monospace face (sq4 token)');
check((renderer.match(/this\.applyCodeBlockFace\(characterStyles, paragraphStyles, characters\.length\)/g) ?? []).length === 4,
  'face applied in all four measure/render paths');
check(renderer.includes('if (paragraph.decoratorStyle === 5) {') &&
  renderer.includes('ctx.fillRect(element.textOrigin.x, baseline - element.fontSize,') &&
  renderer.includes('this.colorToRgba(element.fontColor, 0.08)'),
  'code-block per-line background band');

// --- 字符串钉 ---
check(en.includes('"block_quote"') && en.includes('"code_block"') &&
  en.includes('"value": "Block quote"') && en.includes('"value": "Code block"'),
  'en strings');
check(zh.includes('"block_quote"') && zh.includes('"code_block"'), 'zh strings');

console.log(`TOTAL=${n}`);
