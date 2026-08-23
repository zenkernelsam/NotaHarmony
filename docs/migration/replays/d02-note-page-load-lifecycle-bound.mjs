import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const disappearStart = page.indexOf('aboutToDisappear(): void {');
const onBackStart = page.indexOf('\n  onBackPress()', disappearStart);
assert.notEqual(disappearStart, -1);
assert.ok(onBackStart > disappearStart);
const disappear = page.slice(disappearStart, onBackStart);
assert.match(disappear, /this\.pageLoadGeneration\+\+;/);

const loadStart = page.indexOf('private async loadPages(): Promise<void> {');
const saveStart = page.indexOf('// Original title commits are serialized', loadStart);
assert.ok(loadStart !== -1 && saveStart > loadStart);
const load = page.slice(loadStart, saveStart);
assert.match(load,
  /const loadGeneration: number = \+\+this\.pageLoadGeneration;/);
assert.match(load, /loadGeneration !== this\.pageLoadGeneration/);

const guardCount = (load.match(/loadGeneration !== this\.pageLoadGeneration/g) ?? []).length;
assert.equal(guardCount >= 3, true);
assert.match(load,
  /const note: NoteMeta \| null = await this\.noteRepo\.getNote\(this\.noteId\);\s+if \(loadGeneration !== this\.pageLoadGeneration\) \{\s+return;\s+\}/);
assert.match(load, /\} else \{\s+this\.pages = loaded;\s+\}\s+if \(loadGeneration !== this\.pageLoadGeneration\)/);
assert.match(load, /\} catch \(e\) \{\s+if \(loadGeneration !== this\.pageLoadGeneration\) \{\s+return;\s+\}/);
assert.match(load, /\} finally \{\s+if \(loadGeneration === this\.pageLoadGeneration\) \{\s+this\.pageLoading = false;\s+this\.pageLoadInFlight = false;\s+\}/);

console.log('D02_NOTE_PAGE_LOAD_LIFECYCLE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
