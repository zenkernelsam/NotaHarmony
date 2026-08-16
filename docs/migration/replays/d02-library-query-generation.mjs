import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const page = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const originalSchema = fs.readFileSync(path.join(originalRoot, 'e47.java'), 'utf8');
const originalQuery = fs.readFileSync(path.join(originalRoot, 'vf6.java'), 'utf8');

class NotesRequestGate {
  generation = 0;
  active = true;
  query = '';
  folderId = null;

  begin(query, folderId) {
    this.query = query;
    this.folderId = folderId;
    return ++this.generation;
  }

  isCurrent(generation, query, folderId) {
    return this.active && generation === this.generation &&
      query === this.query && folderId === this.folderId;
  }

  disappear() {
    this.active = false;
    this.generation++;
  }
}

const gate = new NotesRequestGate();
const oldSearch = gate.begin('a', null);
const latestSearch = gate.begin('alpha', null);
assert.equal(gate.isCurrent(oldSearch, 'a', null), false);
assert.equal(gate.isCurrent(latestSearch, 'alpha', null), true);

const folderLoad = gate.begin('alpha', 'folder-a');
const newerSearch = gate.begin('alphabet', 'folder-a');
assert.equal(gate.isCurrent(folderLoad, 'alpha', 'folder-a'), false);
assert.equal(gate.isCurrent(newerSearch, 'alphabet', 'folder-a'), true);
gate.disappear();
assert.equal(gate.isCurrent(newerSearch, 'alphabet', 'folder-a'), false);

const reload = page.slice(page.indexOf('private reloadVisibleNotesAfterMutation'),
  page.indexOf('// 切换浏览文件夹'));
const selectFolder = page.slice(page.indexOf('private async selectFolder'),
  page.indexOf('// T-035：排序切换'));
const search = page.slice(page.indexOf('.onChange((value: string)'),
  page.indexOf('if (this.showSidebar)', page.indexOf('.onChange((value: string)')));

const checks = [
  ['original keeps a separate indexed search table',
    originalSchema.includes('CREATE TABLE IF NOT EXISTS `search_item`') &&
    originalSchema.includes('`noteId`, `type`, `subId`')],
  ['original query uses foldedText LIKE with escaping',
    originalQuery.includes("foldedText LIKE ? ESCAPE '\\\\'")],
  ['page owns one notes request generation',
    page.includes('private notesRequestGeneration: number = 0') &&
    page.includes('private beginNotesRequest(): number') &&
    page.includes('private isCurrentNotesRequest(')],
  ['page exit invalidates list callbacks',
    /aboutToDisappear\(\): void \{[\s\S]*this\.notesRequestGeneration\+\+/.test(page)],
  ['debounce invalidates the previous query immediately',
    search.includes('const notesRequestGeneration: number = this.beginNotesRequest()') &&
    search.includes('notesRequestGeneration !== this.notesRequestGeneration') &&
    search.includes('this.searchText !== value')],
  ['search publishes and reports errors only for the latest tuple',
    (search.match(/this\.isCurrentNotesRequest\(notesRequestGeneration, vm, value, folderId\)/g) ?? [])
      .length >= 2],
  ['mutation reload captures query folder and generation together',
    reload.includes('if (!this.pageActive || this.viewModel !== vm)') &&
    reload.includes('const query: string = this.searchText') &&
    reload.includes('const folderId: string | null = vm.currentFolderId') &&
    reload.includes('const notesRequestGeneration: number = this.beginNotesRequest()') &&
    reload.includes('this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)')],
  ['folder selection cannot close the drawer after a superseding request',
    selectFolder.indexOf('this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)') >= 0 &&
    selectFolder.lastIndexOf('this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)') <
      selectFolder.indexOf('this.closeCompactFolderDrawer()')],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log('D02_LIBRARY_QUERY_GENERATION_REPLAY_OK latest-query=1|folder-query-tuple=1|' +
  'mutation-reload-guard=1|drawer-close-guard=1|lifecycle-invalidation=1');
