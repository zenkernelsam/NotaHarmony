// D02 小部件元数据/尺寸映射收口 — Phase 804
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const X103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/xml';
const X142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/xml';
const FORMS = JSON.parse(fs.readFileSync(
  'C:/HarmonyProject/NotaHarmony/note/src/main/resources/base/profile/forms_config.json', 'utf8'));

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const widgets = ['create_note', 'create_recording', 'folder_notes',
  'note_thumbnail', 'recent_notes'];
const wxml = (v, w) => fs.readFileSync(
  `${v === '103' ? X103 : X142}/app_widgets__${w}_widget_info.xml`, 'utf8');

check('5 widget-info files identical across versions',
  widgets.every((w) => wxml('103', w) === wxml('142', w)));

const cells = (w) => {
  const x = wxml('142', w);
  return `${x.match(/targetCellWidth="(\d+)"/)[1]}x${x.match(/targetCellHeight="(\d+)"/)[1]}`;
};
check('original target cells: create_note/recording/thumbnail=2x2, recent/folder=4x2',
  cells('create_note') === '2x2' && cells('create_recording') === '2x2'
  && cells('note_thumbnail') === '2x2' && cells('recent_notes') === '4x2'
  && cells('folder_notes') === '4x2'
  && widgets.every((w) => wxml('142', w).includes('widgetCategory="home_screen"'))
  && widgets.every((w) => wxml('142', w).includes('resizeMode="vertical|horizontal"')));

check('Harmony 5 forms cover the original widget inventory',
  FORMS.forms.length === 5
  && ['new_note_card', 'new_recording_card', 'note_thumbnail_card',
    'recent_notes_card', 'folder_notes_card']
    .every((n) => FORMS.forms.some((f) => f.name === n)));

const form = (n) => FORMS.forms.find((f) => f.name === n);
check('2x2 widgets exact: new_note/new_recording/note_thumbnail default 2*2',
  form('new_note_card').defaultDimension === '2*2'
  && form('new_recording_card').defaultDimension === '2*2'
  && form('note_thumbnail_card').defaultDimension === '2*2');

check('4x2 list widgets use 2*4 default (Harmony has no 4*2 dim) + multi-dim support',
  form('recent_notes_card').defaultDimension === '2*4'
  && form('folder_notes_card').defaultDimension === '2*4'
  && form('recent_notes_card').supportDimensions.length >= 3
  && form('folder_notes_card').supportDimensions.length >= 3);

check('all forms home-screen arkts cards with localized display names',
  FORMS.forms.every((f) => f.uiSyntax === 'arkts'
    && f.displayName.startsWith('$string:form_')
    && f.description.startsWith('$string:form_')));

console.log(`widget-metadata replay: ${checks.length}/${checks.length} checks green`);
