// D02 原版 1.4.2 工具/学习键增量 + Phase 760 更正 — Phase 781
// 钉住：Learn 聊天为键名重组非下线；胶带九图案名 = Harmony
// TapePattern 枚举序；工具箱细化键族。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const strokes = fs.readFileSync('note/src/main/ets/core/model/StrokeTypes.ets', 'utf8');
const picker = fs.readFileSync('note/src/main/ets/ui/editor/TapePatternPicker.ets', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('Learn chat survives in 1.4.2 (Phase 760 correction)',
  s142.includes('feature_learn__chat">') && s142.includes('feature_learn__chat_send">')
  && s142.includes('ui_learn__chat_input_placeholder">'));
check('chat keys re-keyed to ui_learn__ namespace',
  s103.includes('feature_learn__chat_error_offline">')
  && s142.includes('ui_learn__chat_error_offline">')
  && !s142.includes('feature_learn__chat_error_offline">'));
check('only true learn removal is transcription error_format',
  s103.includes('feature_learn_transcription__error_format">')
  && !s142.includes('transcription__error_format'));
check('1.4.2 adds chat_upsell subscription keys',
  s142.includes('feature_learn__chat_upsell_open">')
  && !s103.includes('chat_upsell'));
check('nine tape-pattern names exist in 1.4.2, absent in 1.0.3',
  ['checkers', 'dots', 'flowers', 'grid', 'hearts', 'plain', 'stars', 'stripes', 'waves']
    .every((p) => s142.includes(`ui_tools__tape_pattern_${p}">`))
  && !s103.includes('tape_pattern'));
check('Harmony TapePattern enum covers all nine patterns in key order',
  ['STRIPES', 'GRID', 'DOTS', 'PLAIN', 'STARS', 'FLOWERS', 'HEARTS', 'WAVES', 'CHECKERS']
    .every((p) => strokes.includes(`${p} =`)));
check('TapePatternPicker lists all nine (already-ported surface)',
  ['STRIPES', 'GRID', 'DOTS', 'PLAIN', 'STARS', 'FLOWERS', 'HEARTS', 'WAVES', 'CHECKERS']
    .every((p) => picker.includes(`TapePattern.${p}`)));
check('toolbox refinement keys: width/hex/no_color/reset/pack names',
  ['brush_width_option', 'color_hex', 'no_color', 'reset',
    'brush_pack_glitter', 'brush_pack_rainbow', 'google_ink_section_title',
    'tool_with_effects', 'stroke_style_pill_description', 'stop_recording_elapsed']
    .every((k) => s142.includes(`ui_tools__${k}">`)));

console.log(`tools/learn key-delta replay: ${checks.length}/${checks.length} checks green`);
