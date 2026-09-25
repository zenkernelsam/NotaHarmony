// Phase 732 — widget 暗色色板（values-night）移植
// 证据：values-night/colors.xml 11 夜值 + recording_button 无夜键回退。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

// === base 昼值 12 键 ===
const base = read('note/src/main/resources/base/element/color.json');
const basePairs = {
  'app_widgets__widget_bg': '#ffffff',
  'app_widgets__widget_create_label': '#171a20',
  'app_widgets__widget_divider': '#e8ebf0',
  'app_widgets__widget_note_button': '#4278ff',
  'app_widgets__widget_note_tile_bg': '#ecf2ff',
  'app_widgets__widget_on_accent': '#ffffff',
  'app_widgets__widget_placeholder_bg': '#f6f6f8',
  'app_widgets__widget_placeholder_icon': '#c8cfdb',
  'app_widgets__widget_recording_button': '#ffa629',
  'app_widgets__widget_recording_tile_bg': '#fff6ea',
  'app_widgets__widget_subject_bg': '#524278ff',
  'app_widgets__widget_text': '#0c0d11',
};
for (const [k, v] of Object.entries(basePairs)) {
  check(`base ${k}=${v}`,
    new RegExp(`"name":\\s*"${k}"[\\s\\S]*?"value":\\s*"${v.replace('#', '#')}"`).test(base));
}

// === dark 夜值 11 键（recording_button 不应存在——原版无夜键回退昼值） ===
const dark = read('note/src/main/resources/dark/element/color.json');
const darkPairs = {
  'app_widgets__widget_bg': '#1c1d22',
  'app_widgets__widget_create_label': '#ffffff',
  'app_widgets__widget_divider': '#404856',
  'app_widgets__widget_note_button': '#5ba8f5',
  'app_widgets__widget_note_tile_bg': '#122231',
  'app_widgets__widget_on_accent': '#0c0d11',
  'app_widgets__widget_placeholder_bg': '#1f242b',
  'app_widgets__widget_placeholder_icon': '#616b7d',
  'app_widgets__widget_recording_tile_bg': '#332108',
  'app_widgets__widget_subject_bg': '#525ba8f5',
  'app_widgets__widget_text': '#ffffff',
};
for (const [k, v] of Object.entries(darkPairs)) {
  check(`dark ${k}=${v}`,
    new RegExp(`"name":\\s*"${k}"[\\s\\S]*?"value":\\s*"${v}"`).test(dark));
}
check('dark 无 recording_button（原版无夜键回退）',
  !/widget_recording_button/.test(dark));

// === 卡片挂载 ===
const nn = read('note/src/main/ets/noteformability/pages/NewNoteCard.ets');
check('NewNoteCard create_label/night tile/note_button/on_accent',
  /widget_create_label/.test(nn) && /widget_note_tile_bg/.test(nn) &&
  /widget_note_button/.test(nn) && /widget_on_accent/.test(nn));
const noHexAttr = (src) => !/\.(fontColor|backgroundColor|fillColor|color|border)\([^)]*'#[0-9a-fA-F]/.test(src);
check('NewNoteCard 无残留昼值 hex 属性', noHexAttr(nn));

const nr = read('note/src/main/ets/noteformability/pages/NewRecordingCard.ets');
check('NewRecordingCard create_label/recording_tile/recording_button/on_accent',
  /widget_create_label/.test(nr) && /widget_recording_tile_bg/.test(nr) &&
  /widget_recording_button/.test(nr) && /widget_on_accent/.test(nr));
check('NewRecordingCard 无残留昼值 hex 属性', noHexAttr(nr));

const rn = read('note/src/main/ets/noteformability/pages/RecentNotesCard.ets');
check('RecentNotesCard widget_text×2/divider×3/placeholder 两键/bg',
  (rn.match(/widget_text/g) || []).length === 2 &&
  (rn.match(/widget_divider/g) || []).length === 3 &&
  /widget_placeholder_bg/.test(rn) && /widget_placeholder_icon/.test(rn) &&
  /widget_bg/.test(rn));
check('RecentNotesCard 无残留昼值 hex 属性', noHexAttr(rn));

const fn = read('note/src/main/ets/noteformability/pages/FolderNotesCard.ets');
check('FolderNotesCard widget_text×2/divider×3/placeholder 两键/bg',
  (fn.match(/widget_text/g) || []).length === 2 &&
  (fn.match(/widget_divider/g) || []).length === 3 &&
  /widget_placeholder_bg/.test(fn) && /widget_placeholder_icon/.test(fn) &&
  /widget_bg/.test(fn));
check('FolderNotesCard 无残留昼值 hex 属性', noHexAttr(fn));

const tn = read('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets');
check('NoteThumbnailCard placeholder 两键 + widget_bg',
  /widget_placeholder_bg/.test(tn) && /widget_placeholder_icon/.test(tn) &&
  /widget_bg/.test(tn));
check('NoteThumbnailCard 保留 ✎ 白字与 8000 scrim',
  /#ffffff/.test(tn) && /#80000000/.test(tn));

// === 文档 ===
const adr = read('docs/migration/adr/ADR-0680-original-widget-night-palette.md');
check('ADR-0680 存在', adr.length > 400);
check('ADR 覆盖夜值表与 on_accent 翻转', /5ba8f5|on_accent/.test(adr));
check('ADR 说明 recording_button 无夜键', /recording_button/.test(adr));

const ev = read('docs/migration/evidence/original-widget-night-palette-jadx-2026-09-25.md');
check('证据文档存在', /values-night/.test(ev) && /1c1d22/.test(ev));

const report = read('docs/migration/reports/phase-732-original-widget-night-palette.md');
check('中文报告存在', report.length > 400);

console.log(`D02_ORIGINAL_WIDGET_NIGHT_PALETTE_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
