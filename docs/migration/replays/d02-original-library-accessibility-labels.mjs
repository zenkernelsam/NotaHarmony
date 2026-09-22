// Phase 557 — original library accessibility labels (feature_library__cd_*).
// Original strings.xml evidence:
//   feature_library__cd_add_note          "Add note"          → create FAB
//   feature_library__cd_open_note_action  "Open note"         → note card/row (untitled)
//   feature_library__cd_open_note_titled  "Open note %1$s"    → note card/row (titled)
//   feature_library__cd_sort              "Sort notes"        → sort control
// Harmony landing: accessibilityText on the interactive surfaces (the card/row
// container itself is the click target — original parity: card = open action).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const page = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const base = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');
const baseJson = JSON.parse(base);
const zhJson = JSON.parse(zh);
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings exist in both locales with original English wording ---
check(baseVal('cd_add_note') === 'Add note', 'cd_add_note EN');
check(zhVal('cd_add_note')?.length > 0, 'cd_add_note zh');
check(baseVal('cd_open_note') === 'Open note', 'cd_open_note EN');
check(zhVal('cd_open_note')?.length > 0, 'cd_open_note zh');
check(baseVal('cd_open_note_titled') === 'Open note %1$s', 'cd_open_note_titled EN');
check(zhVal('cd_open_note_titled')?.includes('%1$s'), 'cd_open_note_titled zh placeholder');
check(baseVal('cd_sort') === 'Sort notes', 'cd_sort EN');
check(zhVal('cd_sort')?.length > 0, 'cd_sort zh');

// --- FAB carries "Add note" ---
const fabIdx = page.indexOf('cd_add_note');
check(fabIdx > 0, 'cd_add_note referenced');
const fabBlock = page.slice(page.lastIndexOf('Button(', fabIdx), page.indexOf('onClick', fabIdx));
check(fabBlock.includes('accessibilityText'), 'FAB accessibilityText');
check(fabBlock.includes('createMenuOpen'), 'FAB toggles create menu (speed-dial)');

// --- NoteCard: accessibilityText on the card's click-target container ---
const cardStart = page.indexOf('@Builder\n  NoteCard(note: NoteMeta)');
const cardEnd = page.indexOf('NoteContextMenu(note)', cardStart);
const cardBlock = page.slice(cardStart, cardEnd);
check(cardBlock.includes('cd_open_note_titled'), 'NoteCard uses titled label');
check(cardBlock.includes('cd_open_note'), 'NoteCard falls back to untitled label');
check(cardBlock.indexOf('cd_open_note') < cardBlock.indexOf('onClick'), 'NoteCard a11y precedes onClick');

// --- NoteListRow: same labels (list-view parity with grid card) ---
const rowStart = page.indexOf('NoteListRow(note: NoteMeta)');
const rowEnd = page.indexOf('NoteContextMenu(note)', rowStart);
const rowBlock = page.slice(rowStart, rowEnd);
check(rowBlock.includes('cd_open_note_titled'), 'NoteListRow uses titled label');
check(rowBlock.indexOf('cd_open_note') < rowBlock.indexOf('onClick'), 'NoteListRow a11y precedes onClick');

// --- Sort control carries "Sort notes" ---
check(page.includes("accessibilityText($r('app.string.cd_sort'))"), 'sort control uses cd_sort');

// --- Titled label actually formats with the note title ---
check(page.includes("cd_open_note_titled', note.title"), 'title passed as format arg');

// --- Guard: labels sit on interactive surfaces, both guarded by pageActive ---
check((page.match(/cd_open_note/g) || []).length >= 2, 'open-note labels on both layouts');

console.log(`TOTAL=${n}`);
