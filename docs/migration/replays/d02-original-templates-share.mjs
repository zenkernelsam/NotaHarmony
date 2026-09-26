// D02 原版 1.4.2 模板管理器面 + 分享面板差 — Phase 789
// 钉住 interactive 语义文案、模板管理器页签/操作族、
// ui_share__ 五格式 multi 变体与 gallery_* 发布段。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const lib = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('interactive-template semantics pinned (editable vs background image)',
  s142.includes('interactive_template_on">Objects (e.g. text, ink) will be editable')
  && s142.includes('interactive_template_off">This template will be a note background image'));
check('template manager tabs + empty states',
  ['basic_templates', 'my_templates', 'favorites', 'new_template',
    'no_custom', 'no_favorites', 'no_recents']
    .every((k) => s142.includes(`ui_templates__${k}">`)));
check('template CRUD: import/edit/delete-with-note-safety',
  s142.includes('ui_templates__import">')
  && s142.includes('delete_template_confirm">Notes you already made')
  && s142.includes('ui_templates__edit_note_cover">'));
check('share sheet five formats; four with multi variants (link single)',
  ['jpg', 'png', 'pdf', 'note'].every((f) =>
    s142.includes(`ui_share__chip_${f}">`)
    && s142.includes(`ui_share__chip_${f}_multi">`))
  && s142.includes('ui_share__chip_link">')
  && !s142.includes('chip_link_multi'));
check('Harmony share sheet already covers all five formats (aligned)',
  ['jpg', 'png', 'pdf', 'note'].every((f) => lib.includes(`share_chip_${f}_multi`))
  && lib.includes('share_action_link'));
check('share-sheet gallery publish section is the new delta',
  s142.includes('ui_share__gallery_convert_to_template">')
  && s142.includes('single page background image')
  && s142.includes('ui_share__gallery_add_tag">')
  && !s103.includes('ui_share__gallery_'));
check('1.0.3 had both families; 1.4.2 adds interactive/CRUD/gallery keys',
  s103.includes('ui_templates__basic_templates">')
  && s103.includes('ui_share__chip_pdf_multi">')
  && !s103.includes('interactive_template')
  && !s103.includes('edit_note_cover')
  && !s103.includes('delete_template_confirm'));

console.log(`templates/share replay: ${checks.length}/${checks.length} checks green`);
