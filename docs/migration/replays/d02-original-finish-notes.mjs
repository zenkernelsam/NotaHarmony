// D02 原版 1.4.2 Finish Notes AI 管线 + 配套键面 — Phase 786
// 钉住三段状态机、配额门控、finishNotesOffered 标志与配套键族。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const ezi = fs.readFileSync(`${r142}/sources/defpackage/ezi.java`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('finish-notes three-stage pipeline keys (upload/transcribe/generate)',
  ['status_uploading', 'status_transcribing', 'status_generating']
    .every((k) => s142.includes(`finish_notes_${k}">`)));
check('finish-notes menu entry + lifecycle + error keys',
  ['options_menu_finish_notes', 'finish_notes_finished', 'finish_notes_offline',
    'finish_notes_terminal_failure', 'finish_notes_transcription_failed',
    'finish_notes_edited_while_finishing', 'finish_notes_needs_more_content']
    .every((k) => s142.includes(`feature_note__${k}">`)));
check('finish-notes quota/subscription gating keys',
  s142.includes('finish_notes_quota_reached">')
  && s142.includes('finish_notes_upgrade_to_finish">'));
check('note state carries finishNotesOffered flag',
  ezi.includes('finishNotesOffered'));
check('1.0.3 had zero finish_notes keys',
  !s103.includes('finish_notes'));
check('page-manager a11y octet + cover entry + gif picker + paste-image',
  ['cd_select_page_numbered', 'cd_deselect_page_numbered',
    'cd_bookmark_page_numbered', 'cd_unbookmark_page_numbered',
    'cd_copy_pages', 'cd_delete_pages', 'cd_duplicate_pages',
    'cd_clear_page_number', 'content_manager_add_note_cover',
    'gif_picker_title', 'selection_menu_paste_image']
    .every((k) => s142.includes(`feature_note__${k}">`)));
check('page-manager a11y keys absent in 1.0.3 (new surface)',
  !s103.includes('cd_select_page_numbered')
  && !s103.includes('gif_picker_title'));

console.log(`finish-notes replay: ${checks.length}/${checks.length} checks green`);
