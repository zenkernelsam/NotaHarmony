import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets', 'utf8').replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

assert.match(page, /private safeToast\(message: ResourceStr, expectedLifecycleGeneration\?: number\): void \{/);
const safeToast = body('private safeToast', 'private isInsecureHttp(): boolean {');
assert.ok(safeToast.indexOf('if (this.isDisposed(expectedLifecycleGeneration ?? this.lifecycleGeneration)) {') > -1,
  'safeToast uses captured generation');

const save = body('private async saveConfigOnce()', 'private normalizedDraft');
const persistIndex = save.indexOf('await WebDAVConfigStore.save(context, config);');
assert.notEqual(persistIndex, -1, 'persist await');

let cursor = persistIndex;
let checkedCalls = 0;
while (true) {
  cursor = save.indexOf('this.safeToast(', cursor + 1);
  if (cursor === -1) break;
  const parameterStart = cursor + 'this.safeToast('.length;
  let depth = 1;
  let callEnd = parameterStart;
  while (depth > 0 && callEnd < save.length) {
    if (save[callEnd] === '(') depth++;
    else if (save[callEnd] === ')') depth--;
    callEnd++;
  }
  const call = save.slice(parameterStart, callEnd - 1);
  assert.match(call, /,\s*lifecycleGeneration\s*$/, 'post-await save toast passes generation');
  checkedCalls++;
}
assert.ok(checkedCalls >= 3, 'all post-await feedback calls checked');

const outerCatchIndex = save.lastIndexOf('} catch (e) {');
const outerLogIndex = save.indexOf('console.error(', outerCatchIndex);
const outerToastIndex = save.indexOf('this.safeToast(', outerLogIndex);
const outerParameterStart = outerToastIndex + 'this.safeToast('.length;
let depth = 1;
let outerCallEnd = outerParameterStart;
while (depth > 0 && outerCallEnd < save.length) {
  if (save[outerCallEnd] === '(') depth++;
  else if (save[outerCallEnd] === ')') depth--;
  outerCallEnd++;
}
const outerCall = save.slice(outerParameterStart, outerCallEnd - 1);
assert.match(outerCall, /,\s*lifecycleGeneration\s*$/, 'late save failure passes generation');

console.log('D02_WEBDAV_SAVE_FEEDBACK_GENERATION_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
