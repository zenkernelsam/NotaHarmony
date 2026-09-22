// D02-REPLAY Phase 543 — original note-open failure dialogs parity.
// Original u49.java renders u49.a(dismiss, titleRes, messageRes, buttonRes) as
// an AlertDialog for each vc9 failure state: rc9 load_failed, qc9
// download_failed, pc9 access_denied, uc9 note_deleted — the single button and
// outside dismissal both invoke the same dismiss callback (u8 wrapper).
// Harmony: deleted/missing note → 'deleted' dialog, load throw → 'failed'
// dialog; dismissal routes back exactly once.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const evidenceRoot =
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const u49 = readFileSync(join(evidenceRoot, 'u49.java'), 'utf8');
const page = readFileSync(
  join(root, 'note/src/main/ets/ui/editor/NotePage.ets'), 'utf8');
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

// u49.a signature: (dismiss Function0, title, message, button string res).
ok(/public static final void a\(Function0 function0, int i, int i2, int i3, t42 t42Var, int i4\)/.test(u49),
  'original u49.a dialog signature missing');
// All four failure kinds render the same dialog helper.
ok(u49.includes('R.string.feature_note__load_failed_title') &&
   u49.includes('R.string.feature_note__load_failed_message') &&
   u49.includes('R.string.feature_note__load_failed_button'),
  'original load_failed dialog resources missing');
ok(u49.includes('R.string.feature_note__download_failed_title') &&
   u49.includes('R.string.feature_note__download_failed_message'),
  'original download_failed dialog resources missing');
ok(u49.includes('R.string.feature_note__access_denied_title') &&
   u49.includes('R.string.feature_note__access_denied_message') &&
   u49.includes('R.string.feature_note__access_denied_button'),
  'original access_denied dialog resources missing');
ok(u49.includes('R.string.feature_note__note_deleted_title') &&
   u49.includes('R.string.feature_note__note_deleted_message') &&
   u49.includes('R.string.feature_note__note_deleted_button'),
  'original note_deleted dialog resources missing');
// u8 wrapper: the confirm button and outside dismissal share one callback.
ok(/new u8\(function0, gl8Var, 20\)/.test(u49),
  'original shared dismiss callback (u8) missing');
// The dialog itself is the f2j.c alert with title + message slots.
ok(/f2j\.c\(function1, tl7\.U\(uz4Var2, i3\)/.test(u49),
  'original f2j.c alert dialog call missing');

// --- Harmony anchors ------------------------------------------------------

ok(page.includes("@State pageLoadFailureKind: string = ''"),
  'Harmony failure-kind state missing');
ok(page.includes("note === null || note.deletedAt !== null") &&
   page.includes("this.pageLoadFailureKind = 'deleted';"),
  'Harmony deleted/unavailable kind mapping missing');
ok(page.includes("this.pageLoadFailureKind = 'failed';"),
  'Harmony generic load-failed kind missing');
ok(page.includes('this.failureDialog.open();'),
  'Harmony failure dialog open missing');
ok(page.includes('struct NoteFailureDialog'),
  'Harmony NoteFailureDialog missing');
ok(page.includes('NoteFailureDialog({') &&
   page.includes("deleted: this.pageLoadFailureKind === 'deleted'"),
  'Harmony failure dialog kind wiring missing');
// Terminal semantics: dismiss routes back exactly once, on both the button
// and outside-tap (autoCancel + cancel callback) paths.
ok(page.includes('failureDismissHandled') &&
   /router\.back\(\)/.test(page.slice(page.indexOf('dismissLoadFailure'))),
  'Harmony single-dismiss router.back() missing');
ok(page.includes('autoCancel: true') && page.includes('cancel: (): void =>'),
  'Harmony outside-dismiss cancel wiring missing');
// Original has no retry affordance on this surface.
const failureBlock = page.slice(
  page.indexOf('} else if (this.pageLoadFailed) {'),
  page.indexOf('} else {', page.indexOf('} else if (this.pageLoadFailed) {')));
ok(!failureBlock.includes('loadPages()'),
  'Harmony must not keep an inline retry on the failure surface');
// Dialog copy parity: title/message/button per kind.
for (const s of ['note_unavailable_title', 'note_unavailable_message',
                 'note_load_failed_title', 'note_load_failed_message',
                 'note_load_failed_button']) {
  ok(baseStrings.includes(`"name": "${s}"`), `base string ${s} missing`);
  ok(zhStrings.includes(`"name": "${s}"`), `zh string ${s} missing`);
}
ok(page.includes("$r('app.string.note_unavailable_title')") &&
   page.includes("$r('app.string.note_unavailable_message')") &&
   page.includes("$r('app.string.note_load_failed_title')") &&
   page.includes("$r('app.string.note_load_failed_message')") &&
   page.includes("$r('app.string.note_load_failed_button')"),
  'Harmony dialog string wiring missing');
// Deleted dialog reuses the shared Done button (original
// note_deleted_button = "Done").
ok(page.includes("$r('app.string.done')"),
  'Harmony Done button reuse missing');

// --- Executable model -----------------------------------------------------

// vc9 state → dialog copy selection.
function dialogCopy(kind) {
  return kind === 'deleted'
    ? { title: 'note_unavailable_title', button: 'done' }
    : { title: 'note_load_failed_title', button: 'note_load_failed_button' };
}
assert.deepEqual(dialogCopy('deleted'),
  { title: 'note_unavailable_title', button: 'done' });
assert.deepEqual(dialogCopy('failed'),
  { title: 'note_load_failed_title', button: 'note_load_failed_button' });
total += 2;

// Dismiss is idempotent (u8 shared-callback parity).
let backs = 0;
let handled = false;
const dismiss = () => { if (handled) { return; } handled = true; backs++; };
dismiss(); dismiss();
assert.equal(backs, 1);
total += 1;

console.log(`D02_ORIGINAL_NOTE_OPEN_FAILURE_DIALOGS_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
