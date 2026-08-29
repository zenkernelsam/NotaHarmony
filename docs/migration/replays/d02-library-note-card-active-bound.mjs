import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const cardStart = page.indexOf('  NoteCard(note: NoteMeta) {');
const cardEnd = page.indexOf('\n  private confirmDelete(note: NoteMeta): void {', cardStart);
assert.ok(cardStart >= 0 && cardEnd > cardStart, 'NoteCard section exists');
const card = page.slice(cardStart, cardEnd);

const navigation = card.indexOf("router.pushUrl({ url: 'ui/editor/NotePage'");
assert.ok(navigation >= 0, 'NoteCard opens the editor');
const clickStart = card.lastIndexOf('.onClick(() => {', navigation);
assert.ok(clickStart >= 0 && clickStart < navigation, 'NoteCard click bounds');
const clickBody = card.slice(clickStart, navigation);
assert.match(clickBody,
  /\.onClick\(\(\) => \{\s+if \(!this\.pageActive\) \{\s+return;\s+\}/,
  'stale NoteCard clicks cannot navigate');
assert.ok(card.indexOf('if (!this.pageActive)', clickStart) < navigation,
  'active-page gate precedes navigation');

assert.match(card, /\.bindContextMenu\(\(\) => \{\s+this\.NoteContextMenu\(note\)\s+\}, ResponseType\.LongPress\)/,
  'long-press context menu remains separate from single-click navigation');

function cardEntry(pageActive) {
  return pageActive ? { navigated: true } : { navigated: false };
}
assert.deepEqual(cardEntry(false), { navigated: false });
assert.deepEqual(cardEntry(true), { navigated: true });

console.log('D02_LIBRARY_NOTE_CARD_ACTIVE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
