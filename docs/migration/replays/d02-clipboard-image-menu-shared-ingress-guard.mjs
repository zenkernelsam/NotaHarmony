import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private ClipboardPasteContextMenu() {');
const end = canvas.indexOf('\n  // === 文本框 ===', start);
assert.ok(start >= 0 && end > start);
const menu = canvas.slice(start, end);

assert.match(menu,
  /MenuItem\(\{ content: \$r\('app\.string\.paste'\) \}\)\s+\.onClick\(\(\) => \{\s+if \(this\.photoImportBusy\) \{\s+return;\s+\}/);
assert.match(menu, /this\.startOriginalClipboardImagePaste\(\);/);
assert.match(canvas, /\.bindContextMenu\(this\.ClipboardPasteContextMenu, ResponseType\.LongPress\)/);

console.log(
  'D02_CLIPBOARD_IMAGE_MENU_SHARED_INGRESS_GUARD_REPLAY_OK TOTAL=3 FAILED=0');
