// D02 原版字符样式（B/I/U/S）Replay —— Phase 684
// 证据：原版 cve.java 文本工具条派单把 B/I/U/S 映射为 zyd 字符样式变更
// （xse→a/bold、vte→b/italic、mue→c/underline、jue→k/strikethrough），
// zyd 11 字段与 RichTextCharacterStyle 一一对应；l32.java 渲染
// italic/underline/strikethrough 行，strings.xml 含 ui_text__bold 等键。
// Harmony：TextBlockOverlay 新增选区级字符 run 编辑 + 折叠光标 pending
// typing-attributes；NoteCanvasView.onTextCommit 扩为 (text, charRuns,
// paraRuns) 三参并在全部分支贯通 updateText。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const l32 = fs.readFileSync(`${D}/sources/defpackage/l32.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
const stringsXml = fs.readFileSync(`${D}/resources/res/values/strings.xml`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const tool = fs.readFileSync(
  'note/src/main/ets/rendering/TextBlockTool.ets', 'utf8').replaceAll('\r\n', '\n');
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
check(cve.includes('nueVar.equals(xse.a)') &&
  cve.includes('n(new zyd(Boolean.valueOf(!((br2) ufbVar.I.getValue()).a)'),
  'cve: xse → zyd.a = bold toggle');
check(cve.includes('nueVar.equals(vte.a)') &&
  cve.includes('n(new zyd(null, Boolean.valueOf(!((br2) ufbVar.I.getValue()).b)'),
  'cve: vte → zyd.b = italic toggle');
check(cve.includes('nueVar.equals(mue.a)') &&
  cve.includes('n(new zyd(null, null, Boolean.valueOf(!((br2) ufbVar.I.getValue()).c)'),
  'cve: mue → zyd.c = underline toggle');
check(cve.includes('nueVar.equals(jue.a)') &&
  cve.includes('Boolean.valueOf(!((br2) ufbVar.I.getValue()).d), 1023'),
  'cve: jue → zyd.k = strikethrough toggle');
check(zyd.includes('public final Boolean a;') &&
  zyd.includes('public final Boolean b;') &&
  zyd.includes('public final Boolean c;') &&
  zyd.includes('public final Boolean k;'),
  'zyd payload fields a/b/c/k');
check(l32.includes('R.string.ui_text__italic') &&
  l32.includes('R.string.ui_text__underline') &&
  l32.includes('R.string.ui_text__strikethrough'),
  'l32 renders italic/underline/strikethrough rows');
check(stringsXml.includes('<string name="ui_text__bold">Bold</string>') &&
  stringsXml.includes('<string name="ui_text__italic">Italic</string>') &&
  stringsXml.includes('<string name="ui_text__underline">Underline</string>') &&
  stringsXml.includes('<string name="ui_text__strikethrough">Strikethrough</string>'),
  'original B/I/U/S strings');

// ===== Overlay 状态与提交钉 =====
check(overlay.includes('import { RichTextCharacterStyle, RichTextCharacterStyleRun, TextBlockElement'),
  'overlay imports char-style types');
check(overlay.includes('onCommit: (text: string, characterStyleRuns: RichTextCharacterStyleRun[],') &&
  overlay.includes('paragraphStyleRuns: RichTextParagraphStyleRun[])'),
  'onCommit three-arg signature');
check(overlay.includes('@State caretSelectionStart: number = -1') &&
  overlay.includes('@State caretCharBold: boolean = false') &&
  overlay.includes('@State caretCharItalic: boolean = false') &&
  overlay.includes('@State caretCharUnderline: boolean = false') &&
  overlay.includes('@State caretCharStrike: boolean = false') &&
  overlay.includes('private draftCharRuns: RichTextCharacterStyleRun[] = []') &&
  overlay.includes('private pendingCharStyles: RichTextCharacterStyle = {}'),
  'selection + char-style draft state');
check(overlay.includes('private seedCharStyles(): void') &&
  overlay.includes('this.element.characterStyleRuns'),
  'element characterStyleRuns → draftCharRuns seed');

// ===== 语义钉：覆盖判定 / 切分改写 / 归一化 / 文本差分平移 / pending =====
check(overlay.includes('private rangeHasCharStyle(field: string, s: number, e: number)') &&
  overlay.includes('this.charStyleValue(r.style, field)'),
  'range coverage check (full-on → toggle off)');
check(overlay.includes('private applyCharStyle(field: string, value: boolean, s: number, e: number)') &&
  overlay.includes('JSON.parse(JSON.stringify(run.style))'),
  'applyCharStyle splits boundary runs + preserves sibling fields');
check(overlay.includes('private normalizeCharRuns(): void') &&
  overlay.includes('JSON.stringify(last.style) === JSON.stringify(run.style)'),
  'normalize merges adjacent identical runs');
check(overlay.includes('private adjustCharRunsForEdit(newText: string, oldText: string): number') &&
  overlay.includes('const delStart: number = prefix'),
  'run positions track text edits via prefix/suffix diff');
check(overlay.includes('private toggleCharStyle(field: string): void') &&
  overlay.includes('this.charStyleSet(this.pendingCharStyles, field, !current)') &&
  overlay.includes('this.applyCharStyle(field, !this.rangeHasCharStyle(field, s, e), s, e)'),
  'toggle: collapsed caret → pending; selection → invert range');
check(overlay.includes('private refreshCaretCharStyles(): void') &&
  overlay.includes("this.rangeHasCharStyle('bold', s, e)"),
  'button active-state refresh');

// ===== 编辑器回调钉 =====
check(overlay.includes('.onTextSelectionChange((start: number, end: number) => {') &&
  overlay.includes('this.caretSelectionStart = start;') &&
  overlay.includes('this.refreshCaretCharStyles();'),
  'selection change tracks start + refreshes char states');
check(overlay.includes('const editStart: number = this.adjustCharRunsForEdit(value, previous)') &&
  overlay.includes('Object.keys(this.pendingCharStyles).length > 0') &&
  overlay.includes('this.applyCharStyle(field, true, editStart, insEnd)'),
  'typed input lands pending typing-attributes as char runs');

// ===== 工具条按钮钉（原版 l32/h32 顺序：字符样式先于列表装饰） =====
check(overlay.includes("Button($r('app.string.bold'))") &&
  overlay.includes("Button($r('app.string.italic'))") &&
  overlay.includes("Button($r('app.string.underline'))") &&
  overlay.includes("Button($r('app.string.strikethrough'))") &&
  overlay.includes("this.toggleCharStyle('bold')") &&
  overlay.includes("this.toggleCharStyle('italic')") &&
  overlay.includes("this.toggleCharStyle('underline')") &&
  overlay.includes("this.toggleCharStyle('strikethrough')"),
  'B/I/U/S buttons wired to toggleCharStyle');
check(overlay.indexOf("app.string.bold')") < overlay.indexOf("app.string.bullet_list')") &&
  overlay.indexOf("app.string.strikethrough')") < overlay.indexOf("app.string.bullet_list')"),
  'char-style buttons precede list decorators (original row order)');
check(overlay.includes('await this.onCommit(this.draftText, this.draftCharRuns,') &&
  overlay.includes('this.draftCharRuns = [];') &&
  overlay.includes('this.pendingCharStyles = {};'),
  'Done commits both run arrays + clears char draft');
check(overlay.includes('this.onCancel();') &&
  !/onClick\(\(\) => \{\s+this\.onCommit\(/.test(overlay),
  'Cancel path unchanged (no silent commit)');

// ===== NoteCanvasView 提交贯通钉 =====
check(canvas.includes('async onTextCommit(text: string,\n    characterStyleRuns?: RichTextCharacterStyleRun[],\n    paragraphStyleRuns?: RichTextParagraphStyleRun[])'),
  'onTextCommit three-arg signature');
check(canvas.includes('JSON.stringify(this.editingOriginalTextBlock.characterStyleRuns ?? []) !==') &&
  canvas.includes('JSON.stringify(characterStyleRuns)'),
  'stylesDiffer covers character runs');
check(/characterStyleRuns === undefined &&\s+paragraphStyleRuns === undefined \?[\s\S]{0,200}this\.textBlockTool\.updateText\(this\.editingTextBlock, text\) :[\s\S]{0,400}\(this\.editingTextBlock\.characterStyleRuns \?\? \[\]\) : characterStyleRuns/.test(canvas),
  'local/plain branches: authored ?? existing for both run arrays');
check(canvas.includes('characterStyleRuns === undefined ? preview.characterStyleRuns :\n            characterStyleRuns'),
  'CRDT text-edit path prefers authored char runs over preview');
check(canvas.includes('characterStyleRuns: RichTextCharacterStyleRun[],') &&
  canvas.includes('await this.onTextCommit(text, characterStyleRuns, runs)'),
  'overlay callback forwards both run arrays');

// ===== TextBlockTool / 渲染器 / 字符串钉 =====
check(tool.includes('characterStyleRuns?: RichTextCharacterStyleRun[]') &&
  tool.includes('updated.characterStyleRuns = cloneCharacterStyleRuns(characterStyleRuns)'),
  'updateText accepts + clones both run arrays');
check(renderer.includes("if (style.italic === true) {") &&
  renderer.includes("if (style.bold === true) {") &&
  renderer.includes('style.underline === true') &&
  renderer.includes('style.strikethrough === true') &&
  renderer.includes('private drawDecoration'),
  'renderer honors all four char styles');
for (const k of ['bold', 'italic', 'underline', 'strikethrough']) {
  check(stringsEn.includes(`"name": "${k}"`) && stringsZh.includes(`"name": "${k}"`),
    `string ${k} in base + zh_CN`);
}

console.log(`D02_ORIGINAL_CHARACTER_STYLES_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
