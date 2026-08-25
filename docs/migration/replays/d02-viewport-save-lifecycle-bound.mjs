import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const scheduleStart = canvas.indexOf('  private scheduleViewportSave(): void {');
const saveStart = canvas.indexOf('  private async saveViewportState(', scheduleStart);
const saveEnd = canvas.indexOf('  // 缩放控制条操作', saveStart);
assert.ok(scheduleStart !== -1 && saveStart > scheduleStart && saveEnd > saveStart,
  'viewport save section exists');

const schedule = canvas.slice(scheduleStart, saveStart);
assert.match(schedule,
  /const generation: number = this\.pageLoadGeneration;\s+this\.viewportSaveTimer = setTimeout/,
  'debounced request captures generation at trigger time');
assert.match(schedule,
  /this\.saveViewportState\(generation\);\s+\}, 500\);/,
  'timer invokes bound save');

const save = canvas.slice(saveStart, saveEnd);
assert.match(save,
  /private async saveViewportState\(requestedGeneration: number,\s+allowDisposedFinalSave: boolean = false\): Promise<void> \{\s+if \(!this\.lifecycleActive && !allowDisposedFinalSave \|\|\s+!allowDisposedFinalSave && \(this\.photoImportBusy \|\| this\.historyBusy\) \|\|\s+requestedGeneration !== this\.pageLoadGeneration\) \{\s+return;\s+\}\s+try \{/,
  'ordinary write requires active lifecycle, no mutation lease, and same generation; disposed final save remains exempt');

const dbInit = save.indexOf('await db.initialize(context);');
const write = save.indexOf('await noteRepo.saveViewState(');
assert.ok(dbInit > 0 && write > dbInit && write < save.indexOf('    } catch (e) {', dbInit),
  'guard precedes database initialization and durable view-state write');

const disposeStart = canvas.indexOf('aboutToDisappear(): void {');
const disposeEnd = canvas.indexOf('private async loadOriginalInkAudioStarts', disposeStart);
assert.ok(disposeStart !== -1 && disposeEnd > disposeStart);
const dispose = canvas.slice(disposeStart, disposeEnd);
assert.match(dispose, /this\.lifecycleActive = false;/);
assert.match(dispose, /this\.saveViewportState\(this\.pageLoadGeneration, true\);/,
  'teardown final save remains allowed despite disposal');
assert.match(dispose, /if \(this\.viewportSaveTimer >= 0\) \{[\s\S]*?clearTimeout/,
  'dispose still cancels pending timer as first defense');

console.log('D02_VIEWPORT_SAVE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
