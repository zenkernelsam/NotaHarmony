import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const cie = original('cie.java');
const m4c = original('m4c.java');
const d3c = original('d3c.java');
const he8 = original('he8.java');
const encoder = read('note/src/main/ets/data/OriginalRichTextStylePayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixture = read('note/src/test/OriginalRichTextStylePayloadEncoder.test.ets');

const copyStart = m4c.indexOf('public final qo5 u(com.gingerlabs.notability.core.model.a aVar)');
const copyEnd = m4c.indexOf('@Override // defpackage.t3c', copyStart + 1);
assert(copyStart >= 0 && copyEnd > copyStart);
const richTextCopy = m4c.slice(copyStart, copyEnd);

assert.match(cie, /aVar\.g\(qo5VarB\);[\s\S]*?m4cVar\.u\(aVar\);[\s\S]*?aVar\.g\(null\)/);
assert.match(richTextCopy, /Character\.codePointCount/);
assert.match(richTextCopy, /th7VarS3\.add\(c1j\.a\(/);
assert.match(richTextCopy, /th7VarS2\.add\(Q\(/);
assert.doesNotMatch(richTextCopy, /this\.m/);
assert.doesNotMatch(richTextCopy, /mqf|bl2|UpdateCheckbox/);
assert.match(d3c, /Link\(value=/);
assert.match(he8, /isChecked is deprecated, use UpdateCheckbox/);

assert.match(encoder, /originalClipboardParagraphStyleRuns/);
assert.match(encoder, /if \(run\.style\.indentLevel !== undefined\)/);
assert.match(encoder, /if \(run\.style\.writingDirection !== undefined\)/);
assert.doesNotMatch(encoder, /style\.isChecked = run\.style\.isChecked/);
assert.match(encoder, /previous\.end === run\.start/);
assert.match(persistence, /originalClipboardParagraphStyleRuns\(text\.paragraphStyleRuns \?\? \[\]\)/);
assert.match(fixture, /resets checked state like original m4c copy/);

function copyParagraphRuns(source) {
  const result = [];
  for (const run of source) {
    const { isChecked: _discarded, ...style } = run.style;
    const previous = result.at(-1);
    if (previous && previous.end === run.start &&
      JSON.stringify(previous.style) === JSON.stringify(style)) {
      previous.end = run.end;
    } else {
      result.push({ start: run.start, end: run.end, style });
    }
  }
  return result;
}

const copied = copyParagraphRuns([
  { start: 0, end: 1, style: { decoratorStyle: 3, isChecked: true } },
  { start: 1, end: 2, style: { decoratorStyle: 3, isChecked: false } },
  { start: 2, end: 3, style: { decoratorStyle: 1 } },
]);
assert.deepEqual(copied, [
  { start: 0, end: 2, style: { decoratorStyle: 3 } },
  { start: 2, end: 3, style: { decoratorStyle: 1 } },
]);
assert.equal(copied[0].style.isChecked, undefined);

console.log('originalGroupPasteCheckboxReset=' +
  'm4c-copy-omits-checkbox-map-no-type28-decorator-kept-adjacent-runs-coalesced-unchecked');
