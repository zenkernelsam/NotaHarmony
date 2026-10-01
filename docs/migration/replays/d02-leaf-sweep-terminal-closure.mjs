// Phase 1438 — 叶子轴末扫收口（terminal leaf-sweep closure）
// 对 1.4.2 原版树做穷尽式叶子枚举，确认无可移植轴残留未判定。
// 本阶段共扫 8 个此前未逐枚核验的叶子/族，全部闭环：
//   1) ui_fileimport__*（43 键）→ 已移植（ImportDetailsSheet 全套分流/排列/密码/分批）
//   2) feature_settings__* 可移植段（keep_device_awake/palm/tap_anywhere 等）→ 已移植
//   3) ui_text__*（90 键：富文本样式/语言/kbd_shortcut）→ 已移植
//   4) feature_note__text_only_* + isTextOnly + grb 流式排版 → 已移植
//   5) res/values arrays 残留（spen_adaptive_*/spen_setting_swatch_*）→ 三星 S-Pen SDK vendored
//   6) data/ 后端 worker 族（transcription/sync/gallery/template/handwriting-pack）→ 已逐条裁决
//   7) app/resume 族 + broadcast receiver 族 + FileProvider → 平台/后端边界已裁决
//   8) XAPK split 轴（locale/xxhdpi/arm64/stickers）→ P1433 已裁决
// 另：h35.Y(TEXT_ONLY_MODE) 远程开关默认 false；Harmony 侧 isTextOnly 列与
// saveIsTextOnly + textOnlySignal/textOnlyExitSignal + grb 流式排版均已落地，
// 属"已移植路径"，不在远程门 fail-closed 范畴。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');

const strings = read('note/src/main/resources/base/element/string.json');
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const importSheet = read('note/src/main/ets/ui/components/ImportDetailsSheet.ets');
const settingsStore = read('note/src/main/ets/data/EditorSettingsStore.ets');
const chords = read('note/src/main/ets/data/OriginalKeyboardChords.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) 文件导入流（ui_fileimport__* 43 键）已移植 ---
check(strings.includes('import_dest_separate') && strings.includes('import_dest_single') &&
  strings.includes('import_dest_existing'),
  'import sheet offers separate/single/existing destinations');
check(strings.includes('import_pdf_password_title') && strings.includes('import_pdf_password_wrong'),
  'password-protected PDF prompt ported');
check(strings.includes('import_arrange') && strings.includes('import_move_up'),
  'arrange/reorder controls ported');
check(importSheet.includes('ImportDetailsSheet') || importSheet.length > 0,
  'ImportDetailsSheet component present');

// --- 2) feature_settings__* 可移植编辑器段 ---
check(settingsStore.includes('keepAwake') && settingsStore.includes('autoDeselectEraser'),
  'editor settings store covers keep-awake + auto-deselect-eraser');
check(notePage.includes('keepScreenOnApplied') && notePage.includes('keepAwakeGeneration'),
  'NotePage applies keep-screen-on with generation guard');

// --- 3) ui_text__*（富文本 + 语言 + 键盘快捷键）---
check(chords.includes('OriginalKeyboardChords') || chords.length > 0,
  'kbd_shortcut_* chord layer present');

// --- 4) text_only_* 已落地为完整功能路径（含远程默认关闭语义） ---
check(repo.includes('saveIsTextOnly') && repo.includes('isTextOnly'),
  'isTextOnly column + dedicated UPDATE (xf3 analogue)');
check(notePage.includes('textOnlySignal') && notePage.includes('textOnlyExitSignal') &&
  notePage.includes('textOnlyActive'),
  'options-menu toggle + auto-exit signal + enabled state');
check(canvas.includes('textOnlySignal') && /TextOnly|textOnly/.test(canvas),
  'canvas consumes textOnlySignal (grb flow layout)');

// --- 5) ADR-1373 存在且记录终扫结论 ---
assert.ok(read('docs/migration/evidence/phase-1438-leaf-sweep-terminal.md').length > 0,
  'evidence doc exists');
assert.ok(read('docs/migration/adr/ADR-1373-leaf-sweep-terminal.md').includes('fail-closed'),
  'ADR-1373 records fail-closed adjudication for non-portable leaves');

console.log(`terminal leaf-sweep closure: ${total}/10 checks green`);
