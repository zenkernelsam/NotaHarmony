// D02 原版代码块语言选择 Replay —— Phase 687
// 证据：原版 cve.java bte 分支 → m(new k5a(str))（k5a=SetProgrammingLanguage
// CRDT op）；str===rs1.c.a('plaintext') 时映射 null=清除字段；rs1.d 为
// 27 语言表；code-block 切换路径 m(new m5a(fy2Var), new k5a(...)) 携
// 语言上下文。Harmony：CODE_LANGUAGES 27 表 + caretCodeLanguage 态 +
// bindMenu 选单（仅 decorator=5 出现）+ plaintext→字段清除。
// 另钉 P684 回补修复：无段落 run 路径也须 seedCharStyles。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const k5a = fs.readFileSync(`${D}/sources/defpackage/k5a.java`, 'utf8');
const rs1 = fs.readFileSync(`${D}/sources/defpackage/rs1.java`, 'utf8');
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
check(cve.includes('nueVar instanceof bte') &&
  cve.includes('((bte) nueVar).a.a') &&
  cve.includes('str.equals(rs1.c.a)') &&
  cve.includes('m(new k5a(str))'),
  'cve: bte language pick → k5a(str), plaintext sentinel → null');
check(cve.includes('m(new m5a(fy2Var), new k5a('),
  'cve: paragraph-style op carries language context');
check(k5a.includes('SetProgrammingLanguage(language=') &&
  k5a.includes('public final String a'),
  'k5a = SetProgrammingLanguage op');
check(rs1.includes('new rs1("plaintext", R.string.ui_text__lang_plaintext)') &&
  rs1.includes('new rs1("typescript", R.string.ui_text__lang_typescript)') &&
  rs1.includes('new rs1("bash", R.string.ui_text__lang_bash)'),
  'rs1.d 27-language table incl plaintext sentinel');
check(stringsXml.includes('<string name="ui_text__programming_language">') &&
  stringsXml.includes('<string name="ui_text__lang_plaintext">Plain Text</string>') &&
  stringsXml.includes('<string name="ui_text__lang_cpp">C++</string>'),
  'original language strings');

// ===== Harmony 语言表与状态钉 =====
check(overlay.includes('const CODE_LANGUAGES: string[][] = [') &&
  overlay.includes("['plaintext', 'Plain Text']") &&
  overlay.includes("['typescript', 'TypeScript']") &&
  overlay.includes("['objectivec', 'Objective-C']"),
  'CODE_LANGUAGES table mirrors rs1.d (27 entries)');
check((overlay.match(/\['[a-z]+', '/g) ?? []).length >= 26,
  'language table size ~27');
check(overlay.includes("@State caretCodeLanguage: string = 'plaintext'"),
  'caret code-language state');
check(overlay.includes('private refreshCaretCodeLanguage(): void') &&
  overlay.includes("current.programmingLanguage ?? 'plaintext'"),
  'caret language refresh from draftStyles');
check(overlay.includes('private buildCodeLanguageMenu(): MenuElement[]') &&
  overlay.includes('this.setCodeLanguage(lang)'),
  'bindMenu builder → setCodeLanguage');

// ===== 语义钉 =====
check(overlay.includes('private setCodeLanguage(lang: string): void') &&
  overlay.includes("if (lang !== 'plaintext') {") &&
  overlay.includes('next.programmingLanguage = lang;'),
  'setCodeLanguage: plaintext → field cleared (rs1.c→null semantics)');
check(overlay.includes('this.caretCodeLanguage = next.programmingLanguage ?? '),
  'selection updates caret language state');
check(overlay.includes('if (this.caretDecoratorStyle === 5) {') &&
  overlay.includes('Button(this.caretCodeLanguageLabel())') &&
  overlay.includes('.bindMenu(this.buildCodeLanguageMenu())'),
  'language button only for CODE_BLOCK paragraph');
check(overlay.indexOf("app.string.code_block')") <
  overlay.indexOf('this.caretCodeLanguageLabel()'),
  'language control follows the code_block toggle');
check(model.includes('programmingLanguage?: string'),
  'RichTextParagraphStyle.programmingLanguage field exists');

// ===== P684 回补修复钉：无段落 run 路径也必须 seedCharStyles =====
check(/if \(runs\.length === 0\) \{\s+this\.caretDecoratorStyle = 0;\s+this\.caretCodeLanguage = 'plaintext';\s+this\.seedCharStyles\(\);\s+return;\s+\}/.test(overlay),
  'empty-paragraph-runs path still seeds character runs (P684 fix)');
check(/this\.caretDecoratorStyle = this\.decoratorAt\(this\.caretOffset\);\s+this\.refreshCaretCodeLanguage\(\);\s+this\.seedCharStyles\(\);/.test(overlay),
  'seeded path refreshes language + char runs');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "code_block"') && stringsZh.includes('"name": "code_block"'),
  'code_block string present (button label reuse)');

console.log(`D02_ORIGINAL_CODE_LANGUAGE_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
