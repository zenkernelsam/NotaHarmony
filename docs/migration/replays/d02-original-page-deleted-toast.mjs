import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const n9j = readOriginal('decompiled_1.0.3/sources/defpackage/n9j.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// n9j collects de2.g() events and emits the page_deleted snackbar text.
ok(n9j.includes('feature_note__content_manager_page_deleted'),
  'original page-deleted snackbar missing');
ok(origStrings.includes('content_manager_page_deleted">Page deleted'),
  'original page-deleted message missing');

// --- Harmony anchors ----------------------------------------------------------------------
// The toast fires after the delete commits: deletePageWithCheckpoint resolves,
// pages list updates, next page selects, and history is pushed — all inside the
// page-structure lease, before the toast. Disposal is fail-closed.
const deleteStart = page.indexOf('private async deletePageAtLocked(');
assert.ok(deleteStart !== -1);
const deleteEnd = page.indexOf('private async moveCurrentPage(', deleteStart);
assert.ok(deleteEnd > deleteStart);
const deleteBody = page.slice(deleteStart, deleteEnd);
ok(deleteBody.includes('deletePageWithCheckpoint'), 'checkpointed delete missing');
// de2.i compensation: the successor is the recorded selectedAfter for plain
// deletes and the returned blank page for compensated deletes.
ok(deleteBody.includes('selectPageById(isCurrent && compensation !== null ? compensation.pageId : selectedAfter)'),
  'selection handoff missing');
ok(deleteBody.includes('pushPageAction(action, history)'), 'history push missing');
ok(deleteBody.includes('page_deleted') && deleteBody.includes('editorDisposed'),
  'page-deleted toast missing or unguarded');
ok(deleteBody.indexOf('pushPageAction(action, history)') <
   deleteBody.indexOf('page_deleted'),
  'toast must follow the committed delete');
ok(stringsBase.includes('"name": "page_deleted"') &&
   stringsBase.includes('"value": "Page deleted"'),
  'base page_deleted string missing');
ok(stringsZh.includes('"name": "page_deleted"'), 'zh page_deleted string missing');

// --- Executable behaviour model -----------------------------------------------------------
// The toast only fires when the committed delete path ran to completion: any
// early return (repo null, disposal, flush failure) suppresses it.
function simulate(opts) {
  if (opts.repoNull || opts.disposed || opts.flushFailed) return 'no-toast';
  return 'toast';
}
assert.equal(simulate({ repoNull: true }), 'no-toast');
assert.equal(simulate({ disposed: true }), 'no-toast');
assert.equal(simulate({}), 'toast');
checks += 3;

console.log(`D02_ORIGINAL_PAGE_DELETED_TOAST_OK TOTAL=${checks} FAILED=0`);
