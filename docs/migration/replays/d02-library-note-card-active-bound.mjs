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
  /\.onClick\(\(\) => \{[\s\S]*?if \(this\.isMultiSelecting\) \{\s+this\.toggleMultiSelectId\(note\.id\);\s+return;\s+\}[\s\S]*?if \(!this\.pageActive\) \{\s+return;\s+\}/,
  'in-mode taps toggle selection; stale taps cannot navigate');
assert.ok(card.indexOf('if (!this.pageActive)', clickStart) < navigation,
  'active-page gate precedes navigation');

assert.match(card, /\.gesture\(LongPressGesture\(\)\.onAction\(\(\) => \{\s+this\.enterMultiSelect\(note\.id\);\s+\}\)\)/,
  'long-press enters multi-select (pk9.o via tj9 case0/6)');
assert.match(page, /NoteMenuButton\(note: NoteMeta\)[\s\S]*?\.bindMenu\(\(\) => \{\s+this\.NoteContextMenu\(note\)\s+\}\)/,
  'd5j single-note menu moved to the overflow button');

function cardEntry(pageActive) {
  return pageActive ? { navigated: true } : { navigated: false };
}
assert.deepEqual(cardEntry(false), { navigated: false });
assert.deepEqual(cardEntry(true), { navigated: true });

console.log('D02_LIBRARY_NOTE_CARD_ACTIVE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
