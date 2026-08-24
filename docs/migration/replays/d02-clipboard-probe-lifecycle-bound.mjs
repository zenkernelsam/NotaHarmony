import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private canProbeOriginalClipboardImage(): boolean {');
const end = canvas.indexOf('\n  private ', start + 1);
assert.ok(start !== -1 && end > start);
const body = canvas.slice(start, end);

const returnKeyword = body.indexOf('return ');
const lifecycleIndex = body.indexOf('this.lifecycleActive', returnKeyword);
assert.ok(returnKeyword !== -1 && lifecycleIndex > returnKeyword,
  'lifecycle must be the first returned condition');

assert.match(body, /private canProbeOriginalClipboardImage\(\): boolean \{\s+return this\.lifecycleActive && this\.loaded && !this\.dataLoading && !this\.dataLoadFailed &&\s+!this\.historyBusy &&\s+this\.persistence\.isReady\(\) && this\.loadedPageId\.length > 0;/);

const refreshStart = canvas.indexOf('  private refreshSystemClipboardImageAvailability(): void {');
const refreshEnd = canvas.indexOf('\n  private async ', refreshStart);
assert.ok(refreshStart !== -1 && refreshEnd > refreshStart);
const refresh = canvas.slice(refreshStart, refreshEnd);
assert.match(refresh, /isOriginalClipboardImageAvailable\(\)\.then\(\(available: boolean\): void => \{\s+if \(probeGeneration === this\.systemClipboardImageProbeGeneration &&\s+this\.canProbeOriginalClipboardImage\(\)\) \{\s+this\.systemClipboardImageAvailable = available;/);

console.log('D02_CLIPBOARD_PROBE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
