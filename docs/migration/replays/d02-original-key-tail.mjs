// D02 原版 1.4.2 字符串尾部族合并登记 — Phase 790
// 钉住 ui_text__/toolbox/transcription/permissions/designsystem
// 五个尾部族的关键键与 1.0.3 缺席证明。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('ui_text__: font-panel nav + hyperlink edit + five kbd-shortcut a11y labels',
  ['back_to_font_styles', 'clear_link_title', 'confirm_hyperlink',
    'kbd_shortcut_bullet_list', 'kbd_shortcut_checkbox_list',
    'kbd_shortcut_numbered_list', 'kbd_shortcut_increase_font_size',
    'kbd_shortcut_decrease_font_size']
    .every((k) => s142.includes(`ui_text__${k}">`)));
check('feature_note_toolbox__: add-media/sticker + phone tools a11y',
  ['add_media', 'add_sticker', 'more_tools', 'cd_hide_tools',
    'cd_playback_position', 'phone_all_tools_description']
    .every((k) => s142.includes(`feature_note_toolbox__${k}">`)));
check('learn_transcription__: viewer + quality feedback + error keys',
  ['smart_notes', 'search', 'copy', 'transcript_accurate',
    'transcript_inaccurate', 'error_bad_file_format',
    'error_file_too_large', 'error_no_network']
    .every((k) => s142.includes(`feature_learn_transcription__${k}">`)));
check('ui_permissions__: calendar rationale + camera lock semantics',
  ['calendar_access_rationale', 'calendar_access_required',
    'camera_capture_failed', 'camera_needs_unlock']
    .every((k) => s142.includes(`ui_permissions__${k}">`)));
check('ui_designsystem__: bottom-sheet a11y + beta/early-access badges',
  ['bottom_sheet_expand_description', 'bottom_sheet_collapse_description',
    'bottom_sheet_dismiss_description', 'beta', 'early_access']
    .every((k) => s142.includes(`ui_designsystem__${k}">`)));
check('all five families absent in 1.0.3 where new',
  !s103.includes('kbd_shortcut_bullet_list')
  && !s103.includes('transcript_accurate')
  && !s103.includes('calendar_access_rationale')
  && !s103.includes('early_access">'));
// note: bottom_sheet_* a11y labels existed in 1.0.3 already.

console.log(`key-tail replay: ${checks.length}/${checks.length} checks green`);
