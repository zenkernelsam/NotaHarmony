import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async loadPages(): Promise<void> {');
const end = page.indexOf('  // Original title commits are serialized', start);
assert.ok(start !== -1 && end > start, 'loadPages section exists');
const body = page.slice(start, end);

assert.match(body,
  /const loadGeneration: number = \+\+this\.pageLoadGeneration;\s+if \(this\.editorDisposed \|\| this\.pageLoadInFlight\) \{\s+return;\s+\}/,
  'dispose-before-entry race is rejected before in-flight state');

const pagesPublish = body.indexOf('      } else {\n        this.pages = loaded;\n      }');
const postPagesGuard = body.indexOf('if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {', pagesPublish);
assert.ok(pagesPublish >= 0 && postPagesGuard > pagesPublish,
  'pages publication is followed by combined disposal/generation guard');

const recoveryAwait = body.indexOf('await this.pageRepo.addPage(this.noteId, defaultPage);');
const recoveryPublish = body.indexOf('this.pages = [assignedPage];');
const recoveryGuard = body.indexOf(
  'if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {',
  recoveryAwait,
);
assert.ok(recoveryAwait >= 0 && recoveryPublish > recoveryAwait);
assert.ok(recoveryGuard > recoveryAwait && recoveryGuard < recoveryPublish,
  'zero-page recovery publication is gated immediately after addPage await');

const backgroundAwait = body.indexOf('await this.pageRepo.getNoteBackground(this.noteId);');
const guardEnd = body.indexOf('}', postPagesGuard);
assert.ok(backgroundAwait > guardEnd, 'guard precedes note background await');

const catchIndex = body.indexOf('    } catch (e) {');
assert.match(body.slice(catchIndex),
  /if \(loadGeneration !== this\.pageLoadGeneration \|\| this\.editorDisposed\) \{\s+return;\s+\}/,
  'failure continuation retains disposal guard');

console.log('D02_EDITOR_LOAD_DISPOSAL_RACE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
