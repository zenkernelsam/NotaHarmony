// D02 原版 1.4.2 封面/计划本选择器面 — Phase 782
// 钉住 10 封面预设键、4 计划本封面样式、week-start 双键、
// 学年计划本名、标题兜底值与尺子角度读数增量。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const covers = ['blue', 'blue_journal', 'brown', 'logo_pattern', 'maroon',
  'orange', 'purple_journal', 'sage', 'stickers', 'yellow'];
check('1.4.2 ships ten named cover presets (ui_notecovers__)',
  covers.every((c) => s142.includes(`ui_notecovers__preset_${c}">`)));
check('1.0.3 had no ui_notecovers__ keys',
  !s103.includes('ui_notecovers__'));
check('planner cover styles + academic planner + week-start keys',
  ['cover_arches', 'cover_lattice', 'cover_pinstripe', 'cover_scallop',
    'planner_academic_2026_2027', 'week_start_monday', 'week_start_sunday',
    'planners'].every((k) => s142.includes(`ui_planners__${k}">`)));
check('1.0.3 had no ui_planners__ keys',
  !s103.includes('ui_planners__'));
check('covers/ asset count matches ten presets (Phase 763 assets)',
  fs.readdirSync(`${r142}/resources/assets/covers`)
    .filter((f) => f.endsWith('.pdf')).length === 10);
check('note-title fallback "Note" + ruler angle labels are new',
  s142.includes('ui_notedefaults__default_note_title_fallback">Note<')
  && s142.includes('feature_note_ruler__angle_label">')
  && s142.includes('feature_note_ruler__angle_measure_label">Δ')
  && !s103.includes('feature_note_ruler__'));
check('1.0.3 already had the ruler tool + units setting',
  s103.includes('ui_tools__ruler">') && s103.includes('feature_settings__ruler_units">'));

console.log(`covers/planners replay: ${checks.length}/${checks.length} checks green`);
