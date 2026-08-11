import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalReplace = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/awb.java', 'utf8');
const canvas = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/editor/NoteCanvasView.ets', import.meta.url), 'utf8');
const fixtures = fs.readFileSync(new URL(
  '../../../note/src/test/OriginalTextMutationPayloadEncoder.test.ets', import.meta.url), 'utf8');

assert.match(originalReplace,
  /if \(i2 < i3\) \{\s*th7VarS\.add\(u5j\.F\(x09Var, i2, i3 - i2, qo5Var\)\)/);
assert.match(originalReplace, /if \(str\.length\(\) > 0\) \{[\s\S]*s5j\.i\(x09Var, str, qo5Var, excVar\)/);
assert.match(originalReplace, /List listE = m18\.E\(th7VarS\)/);

assert.match(canvas,
  /if \(this\.editingOriginalTextBlock === null && text\.length === 0\)/);
assert.match(canvas,
  /this\.editingOriginalTextBlock\.richText !== text &&\s*decodeOperationId\(this\.editingOriginalTextBlock\.id\) === null/);
assert.match(canvas,
  /decodeOperationId\(this\.editingOriginalTextBlock\.id\) === null\)[\s\S]*this\.textBlockTool\.updateText\(this\.editingTextBlock, text\)[\s\S]*UndoableActionType\.REPLACE_ELEMENT/);
assert.match(canvas,
  /else if \(this\.editingOriginalTextBlock\.richText !== text\) \{[\s\S]*await this\.persistence\.previewOriginalTextEdit/);
assert.match(fixtures,
  /removes every character without inserting when an existing Block becomes empty/);
assert.match(fixtures,
  /planOriginalLocalTextMutation\(initialCharacters\(\), 'ABC', ''\)/);

function routeCommit({ isNew, canonical, before, after }) {
  if (isNew && after.length === 0) return 'cancel-new';
  if (before === after) return 'unchanged';
  return canonical ? 'original-crdt' : 'compat-snapshot';
}

assert.equal(routeCommit({ isNew: true, canonical: true, before: '', after: '' }), 'cancel-new');
assert.equal(routeCommit({ isNew: false, canonical: true, before: 'text', after: '' }), 'original-crdt');
assert.equal(routeCommit({ isNew: false, canonical: false, before: 'legacy', after: '' }), 'compat-snapshot');
assert.equal(routeCommit({ isNew: false, canonical: false, before: 'legacy', after: 'edited' }),
  'compat-snapshot');
assert.equal(routeCommit({ isNew: false, canonical: true, before: 'same', after: 'same' }), 'unchanged');

console.log('emptyExistingText=original-remove-all-preserves-block-new-empty-cancels-' +
  'opaque-compat-edit-canonical-preview-guard');
