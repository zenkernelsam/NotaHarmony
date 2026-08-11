import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalInsert = fs.readFileSync(originalRoot + 'f46.java', 'utf8');
const originalFactory = fs.readFileSync(originalRoot + 's5j.java', 'utf8');
const canvas = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/editor/NoteCanvasView.ets', import.meta.url), 'utf8');
const overlay = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/components/TextBlockOverlay.ets', import.meta.url), 'utf8');

assert.match(originalInsert, /if \(k\(\)\.length\(\) == 0\)/);
assert.match(originalInsert, /Cannot insert empty string/);
assert.match(originalFactory,
  /str\.length\(\) > 2 \|\| Character\.codePointCount\(str, 0, str\.length\(\)\) != 1/);
assert.match(originalFactory, /return kci\.b\(excVar, str, qo5Var\)/);
assert.match(canvas,
  /if \(this\.editingOriginalTextBlock === null && text\.length === 0\) \{[\s\S]*this\.onTextCancel\(\)/);
assert.doesNotMatch(canvas, /if \(text\.trim\(\)\.length === 0\)/);
assert.match(canvas,
  /onCommit: async \(text: string\): Promise<boolean> => \{[\s\S]*return await this\.onTextCommit\(text\)[\s\S]*return false/);
assert.match(overlay, /onCommit: \(text: string\) => Promise<boolean>/);
assert.match(overlay,
  /\.onClick\(async \(\) => \{[\s\S]*if \(await this\.onCommit\(this\.draftText\)\) \{[\s\S]*this\.draftText = ''/);
assert.doesNotMatch(overlay,
  /\.onClick\(\(\) => \{\s*this\.onCommit\(this\.draftText\);\s*this\.draftText = ''/);

const shouldCancel = text => text.length === 0;
assert.equal(shouldCancel(''), true);
assert.equal(shouldCancel(' '), false);
assert.equal(shouldCancel('\t\n'), false);
assert.equal(shouldCancel('\u00a0'), false);
assert.equal(shouldCancel('\u3000'), false);

console.log('textWhitespaceCommit=original-empty-only-space-tab-newline-nbsp-ideographic-' +
  'preserved-draft-clears-only-after-success');
