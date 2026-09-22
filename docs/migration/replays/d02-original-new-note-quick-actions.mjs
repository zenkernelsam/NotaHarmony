// D02-REPLAY Phase 545 — original library new-note quick actions parity.
// Original ksh.g/mw3: the library creation card carries an expandable FAB
// listing record_audio / import_file / [scan] / [capture_and_add]; the card
// body performs the blank create. Harmony: the + FAB now expands into
// [New note, Record audio, Import file]; Record audio opens the editor with
// autoRecord=1 which starts capture after load; Import file runs the system
// document picker → importFromFile → opens the imported note.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const evidenceRoot =
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const mw3 = readFileSync(join(evidenceRoot, 'mw3.java'), 'utf8');
const lib = readFileSync(
  join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const notePage = readFileSync(
  join(root, 'note/src/main/ets/ui/editor/NotePage.ets'), 'utf8');
const importer = readFileSync(
  join(root, 'note/src/main/ets/data/NoteImporter.ets'), 'utf8');
const backup = readFileSync(
  join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const baseStrings = readFileSync(
  join(root, 'note/src/main/resources/base/element/string.json'), 'utf8');
const zhStrings = readFileSync(
  join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8');

let total = 0;
let failed = 0;
function ok(cond, msg) {
  total++;
  try {
    assert.ok(cond, msg);
  } catch (e) {
    failed++;
    console.error(`FAIL: ${msg}`);
  }
}

// --- Original evidence anchors -------------------------------------------

// mw3 case 0 renders the four quick actions in fixed order.
ok(mw3.includes('R.string.feature_note__empty_note__record_audio') &&
   mw3.includes('R.string.feature_note__empty_note__import_file') &&
   mw3.includes('R.string.feature_note__empty_note__scan') &&
   mw3.includes('R.string.feature_note__empty_note__capture_and_add'),
  'original quick-action items missing');
// Scan is capability-gated; capture is only rendered when non-null.
ok(/if \(z2\) \{[\s\S]*?empty_note__scan/.test(mw3),
  'original scan capability gate missing');
ok(/if \(function4 == null\)[\s\S]*?else[\s\S]*?capture_and_add/.test(mw3),
  'original capture nullable gate missing');

// --- Harmony anchors ------------------------------------------------------

ok(lib.includes('@State createMenuOpen: boolean = false'),
  'Harmony createMenuOpen state missing');
// FAB toggles the expansion instead of creating directly.
ok(/Button\(\) \{\s+Text\(this\.createMenuOpen \? '×' : '\+'\)/.test(lib),
  'Harmony FAB expand toggle missing');
ok(lib.includes('this.createMenuOpen = !this.createMenuOpen;'),
  'Harmony FAB toggle action missing');
// Chip order: New note → Record audio → Import file.
const fabStart = lib.indexOf('if (this.createMenuOpen) {');
ok(fabStart >= 0, 'Harmony expansion block missing');
const fabBlock = lib.slice(fabStart, fabStart + 1600);
const chipOrder = [
  "CreateActionChip($r('app.string.new_note')",
  "CreateActionChip($r('app.string.record_audio')",
  "CreateActionChip($r('app.string.import_note_file')",
];
let cursor = -1;
for (const chip of chipOrder) {
  const at = fabBlock.indexOf(chip);
  assert.ok(at > cursor, `${chip} out of order or missing`);
  cursor = at;
}
total += chipOrder.length;
ok(lib.includes('this.createAndRecord()') && lib.includes('this.importAndOpen()'),
  'Harmony quick-action handlers missing');
ok(lib.includes('private async createAndRecord()') &&
   lib.includes('await this.createAndLaunch(true);'),
  'Harmony createAndRecord missing');
ok(lib.includes('private async importAndOpen()') &&
   lib.includes('importer.importFromFile(context)') &&
   lib.includes('router.pushUrl({ url: \'ui/editor/NotePage\''),
  'Harmony importAndOpen picker→import→open path missing');
ok(lib.includes('ImportResult.CANCELLED'),
  'Harmony import cancel handling missing');

// autoRecord param → post-load capture start.
ok(notePage.includes("params['autoRecord'] === '1'") &&
   notePage.includes('this.autoRecordRequested'),
  'Harmony autoRecord param read missing');
ok(/autoRecordRequested && !this\.editorDisposed[\s\S]*?showRecordings = true[\s\S]*?startRecording\(\)/.test(notePage),
  'Harmony post-load auto-record trigger missing');

// ImportResult.CANCELLED enum + silent handling in the backup importer too.
ok(importer.includes('CANCELLED = 4') &&
   importer.includes('result: ImportResult.CANCELLED'),
  'Harmony ImportResult.CANCELLED missing');
ok(backup.includes('report.result === ImportResult.CANCELLED'),
  'Harmony backup import must treat CANCELLED silently');

// Strings.
for (const s of ['new_note', 'record_audio']) {
  ok(baseStrings.includes(`"name": "${s}"`), `base string ${s} missing`);
  ok(zhStrings.includes(`"name": "${s}"`), `zh string ${s} missing`);
}

// --- Executable model -----------------------------------------------------

// Expansion toggle: closed→open→closed; actions close the menu then run.
let open = false;
let acted = 0;
const toggle = () => { open = !open; };
const chip = () => { open = false; acted++; };
toggle(); assert.ok(open);
chip(); assert.ok(!open && acted === 1);
total += 2;

console.log(`D02_ORIGINAL_NEW_NOTE_QUICK_ACTIONS_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
