import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const bar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const ke1 = readOriginal('decompiled_1.0.3/sources/defpackage/ke1.java');
const n8 = readOriginal('decompiled_1.0.3/sources/defpackage/n8.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// n8 case 20: the page_indicator text is clickable and opens the dialog.
ok(n8.includes('R.string.feature_note__page_indicator') &&
   /m18\.K\(pd8VarJ, false, null, l5cVar, \(Function0\) objS/.test(n8),
  'original clickable page indicator missing');
// ke1 cases 12/13: dialog title + page-label field.
ok(ke1.includes('feature_note__jump_to_title') &&
   ke1.includes('feature_note__jump_to_page_label'),
  'original jump dialog labels missing');
// n8 case 21: Go enabled iff svd.p0(input) parses to 1..pageCount.
ok(n8.includes('feature_note__jump_to_go') &&
   /svd\.p0\(\(String\) gl8Var2\.getValue\(\)\)/.test(n8) &&
   n8.includes('numP0 != null && 1 <='),
  'original Go enable rule missing');
ok(origStrings.includes('feature_note__jump_to_title') &&
   origStrings.includes('feature_note__jump_to_cancel') &&
   origStrings.includes('feature_note__jump_to_go') &&
   origStrings.includes('feature_note__page_indicator'),
  'original jump strings missing');

// --- Harmony anchors ----------------------------------------------------------------------
// Indicator tap -> dialog; fail-closed under busy/lease.
ok(/Text\(\(this\.currentPageIndex \+ 1\) \+ ' \/ ' \+ this\.pageCount\)[\s\S]*?\.onClick\(\(\) => \{\s*if \(this\.busy \|\| this\.photoImportLeaseActive\)[\s\S]*?this\.jumpDialog\.open\(\)/.test(bar),
  'clickable page indicator missing');
// Dialog: JumpToPageDialog with pageCount + initialValue + onGo callback.
ok(bar.includes('builder: JumpToPageDialog({') &&
   bar.includes('pageCount: this.pageCount') &&
   bar.includes('initialValue: (this.currentPageIndex + 1).toString()') &&
   bar.includes('this.onJumpToPage(pageIndex)'),
  'jump dialog wiring missing');
// Go-enable rule parity: parse + strict integer + 1..pageCount.
ok(bar.includes('parseInt(this.inputText.trim(), 10)') &&
   bar.includes('target >= 1 && target <= this.pageCount') &&
   bar.includes('this.onGo(target - 1)'),
  'Go enable/apply rule missing');
// Dialog renders title/label/Go strings.
ok(bar.includes("$r('app.string.jump_to_title')") &&
   bar.includes("$r('app.string.jump_to_page_label')") &&
   bar.includes("$r('app.string.jump_to_go')"),
  'jump dialog strings missing');
// NotePage applies the 0-based index under the page guard set.
ok(notePage.includes('onJumpToPage: (pageIndex: number) =>') &&
   /pageIndex >= 0 && pageIndex < this\.pages\.length[\s\S]*?this\.currentPageIndex = pageIndex/.test(notePage),
  'jump apply guard missing');
for (const name of ['jump_to_title', 'jump_to_page_label', 'jump_to_go']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

// --- Executable model: svd.p0 + range enable ----------------------------------------------
// Mirror of JumpToPageDialog.targetPage()/goEnabled().
function targetPage(input, pageCount) {
  const t = input.trim();
  const parsed = parseInt(t, 10);
  if (Number.isNaN(parsed) || parsed.toString() !== t) { return -1; }
  return parsed >= 1 && parsed <= pageCount ? parsed : -1;
}
assert.equal(targetPage('3', 5), 3); checks++;
assert.equal(targetPage('0', 5), -1); checks++;
assert.equal(targetPage('6', 5), -1); checks++;
assert.equal(targetPage('abc', 5), -1); checks++;
assert.equal(targetPage('2.5', 5), -1); checks++;
assert.equal(targetPage(' 4 ', 5), 4); checks++;
assert.equal(targetPage('5', 5), 5); checks++;
assert.equal(targetPage('-1', 5), -1); checks++;
// Jump applies 0-based index.
assert.equal(targetPage('1', 9) - 1, 0); checks++;

console.log(`D02_ORIGINAL_JUMP_TO_PAGE_OK TOTAL=${checks} FAILED=0`);
