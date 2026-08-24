import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(startMarker, endMarker) {
  const start = canvas.indexOf(startMarker);
  const end = canvas.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return canvas.slice(start, end);
}

const load = section('  private async loadNoteData(): Promise<void> {',
  '  private async readPersistentHistory(');
assert.match(load,
  /private async loadNoteData\(\): Promise<void> \{\s+if \(!this\.lifecycleActive\) \{\s+return;\s+\}\s+this\.partialEraserPreview\.cancel\(\);/,
  'disposed initial entry is rejected before generation mutation');
const mainGuards = (load.match(/if \(!this\.lifecycleActive \|\| generation !== this\.pageLoadGeneration \|\|\s+this\.currentPage\.pageId !== targetPageId\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(mainGuards >= 2, true, 'initial success/history guards include lifecycle');

const switchBody = section('  private async switchPageData(): Promise<void> {',
  '  private enterLoadFailureState(): void {');
assert.match(switchBody,
  /private async switchPageData\(\): Promise<void> \{\s+if \(!this\.lifecycleActive\) \{\s+return;\s+\}\s+this\.cancelActiveInteraction\(\);/,
  'disposed switch entry is rejected');
assert.match(switchBody,
  /if \(!this\.lifecycleActive \|\| generation !== this\.pageLoadGeneration \|\|\s+this\.currentPage\.pageId !== targetPageId\) \{\s+return;\s+\}\s+this\.hydrateOriginalStrokeAudioStarts/,
  'switch success guard includes lifecycle');
assert.match(switchBody,
  /\} catch \(e\) \{\s+if \(generation === this\.pageLoadGeneration && !this\.lifecycleActive\) \{\s+return;\s+\}\s+if \(generation === this\.pageLoadGeneration\) \{\s+if \(previousPageSaved\) \{/,
  'same-generation disposed switch failure skips rollback/toast');

console.log('D02_CANVAS_LOAD_SWITCH_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
