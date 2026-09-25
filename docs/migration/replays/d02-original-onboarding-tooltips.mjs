// D02 原版引导气泡链移植 — Phase 712（ADR-0660）。
// 原版 pq9 枚举 12 条 + hq9 onboardingTooltipSeen Set<String> 持久化 +
// fsi.h/zy7/k9f/js7 渲染-定位-关闭链。Harmony 移植 11 条
// （FIRST_TRANSCRIPT 隶属 feature_learn 边界，ADR-0652 fail-closed 不带入）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const pq9 = read(`${JADX}/sources/defpackage/pq9.java`);
const hq9 = read(`${JADX}/sources/defpackage/hq9.java`);
const rh8 = read(`${JADX}/sources/defpackage/rh8.java`);
const x90 = read(`${JADX}/sources/defpackage/x90.java`);
const enh = read(`${JADX}/sources/defpackage/enh.java`);
const ajh = read(`${JADX}/sources/defpackage/ajh.java`);
const ipi = read(`${JADX}/sources/defpackage/ipi.java`);
const gaj = read(`${JADX}/sources/defpackage/gaj.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版枚举与持久化 ---
for (const k of ['NEW_NOTE', 'FIRST_TRAY_OPENED', 'FIRST_INK_INSERT', 'FIRST_IMAGE',
  'FIRST_RECORDING', 'FIRST_TRANSCRIPT', 'FIRST_TEXT', 'FIRST_IMPORT',
  'FIRST_UNDO_REDO', 'FIRST_HIGHLIGHTER', 'FIRST_NOTE_COMPLETED', 'COMPACT_ORGANIZE']) {
  check(pq9.includes(`"${k}"`), `pq9 枚举 ${k}`);
}
check(hq9.includes('"onboardingTooltipSeen"'), 'hq9 seen 集合键名');
check(hq9.includes('pq9.valueOf'), 'hq9 枚举名容错读回');

// --- 原版站点与方位 ---
check(x90.includes('fsi.h(pq9.N, 3'), 'x90 页管理器气泡 pos3(左)');
check(x90.includes('fsi.h(pq9.O, 3'), 'x90 undo/redo 气泡 pos3(左)');
check(enh.includes('fsi.h(pq9Var, 2'), 'enh 紧凑整理气泡 pos2(下)');
check(ajh.includes('fsi.h(pq9.P'), 'ajh 首条笔记完成气泡');
check(ipi.includes('pq9.J'), 'ipi 样式托盘气泡');
check(gaj.includes('pq9.L'), 'gaj 录音回放气泡');
check(rh8.includes('pq9.I') && rh8.includes('pq9.K'),
  'rh8 NEW_NOTE/INK_INSERT 状态机');
check(rh8.includes('!set3.contains(pq9.L) && set3.contains(pq9Var)') ||
  rh8.includes('contains(pq9.L)'), 'rh8 录音气泡 NEW_NOTE 前置');

// --- 原版文案 ---
for (const s of ['new_note_tooltip_text', 'first_tray_opened_tooltip_text',
  'first_ink_insert_tooltip_text', 'first_image_tooltip_text',
  'first_recording_tooltip_text', 'first_text_tooltip_text',
  'first_import_tooltip_text', 'first_undo_redo_tooltip_text',
  'first_highlighter_tooltip_text', 'first_note_completed_tooltip_text',
  'compact_organize_tooltip_text', 'got_it']) {
  check(strings.includes(`data_onboarding__${s}`),
    `原版字符串 data_onboarding__${s}`);
}

// --- Harmony 存储层 ---
const store = read('note/src/main/ets/data/OnboardingTooltipStore.ets');
check(store.includes('onboardingTooltipSeen'), 'Harmony seen 键名对齐');
for (const k of ['NEW_NOTE', 'FIRST_TRAY_OPENED', 'FIRST_INK_INSERT', 'FIRST_IMAGE',
  'FIRST_RECORDING', 'FIRST_TEXT', 'FIRST_IMPORT', 'FIRST_UNDO_REDO',
  'FIRST_HIGHLIGHTER', 'FIRST_NOTE_COMPLETED', 'COMPACT_ORGANIZE']) {
  check(store.includes(`'${k}'`), `Harmony 枚举 ${k}`);
}
check(store.includes('markSeen') && store.includes('getSeenKinds') &&
  store.includes('isOnboardingTooltipKind'), 'store markSeen/读取/容错');
check(!store.includes("FIRST_TRANSCRIPT = '"), 'FIRST_TRANSCRIPT 不进入本链');

// --- Harmony 气泡组件 ---
const bubble = read('note/src/main/ets/ui/components/OnboardingTipBubble.ets');
check(bubble.includes('data_onboarding__got_it'), '气泡 Got it 按钮');
check(bubble.includes('onGotIt'), '气泡关闭回调');

// --- Harmony 编辑器工具栏锚点 ---
const tb = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
check((tb.match(/bindPopup/g) || []).length >= 4, '工具栏 ≥4 处 bindPopup');
check(tb.includes('noteHasContent') && tb.includes('FIRST_IMPORT'),
  'FIRST_IMPORT 站点（x90 z7）');
check(tb.includes('onCanUndoTip') && tb.includes('FIRST_UNDO_REDO'),
  'FIRST_UNDO_REDO 站点（x90 gl8Var5）');
check(tb.includes('showTipNewNote') && tb.includes('showTipTray'),
  'NEW_NOTE/FIRST_TRAY_OPENED 锚点');
check(tb.includes('tipSeen(OnboardingTooltipKind.NEW_NOTE)') &&
  tb.includes('FIRST_TRAY_OPENED'), 'TRAY 前置 NEW_NOTE（ipi/ys2）');
check(tb.includes("toolId === 'text'") && tb.includes('FIRST_TEXT'),
  'FIRST_TEXT 工具选中触发');
check(tb.includes('ToolType.HIGHLIGHTER') && tb.includes('FIRST_HIGHLIGHTER'),
  'FIRST_HIGHLIGHTER 工具选中触发');
check((tb.match(/Placement\.Left/g) || []).length >= 2 &&
  (tb.match(/Placement\.Bottom/g) || []).length >= 2,
  '工具栏方位 pos3→Left ×2 / 默认→Bottom');
check((tb.match(/autoCancel: false/g) || []).length >= 4 &&
  (tb.match(/mask: false/g) || []).length >= 4,
  '非模态 + 仅 Got it 关闭（js7）');

// --- Harmony 画布元素锚点 ---
const cv = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
check(cv.includes('tipInkBounds') && cv.includes('FIRST_INK_INSERT'),
  'FIRST_INK_INSERT 墨迹锚点');
check(cv.includes('tipImageBounds') && cv.includes('FIRST_IMAGE'),
  'FIRST_IMAGE 对象锚点');
check(cv.includes('refreshElementTips') && cv.includes('tipOverlayPosition'),
  '画布气泡刷新 + k9f 回退定位');
check(cv.includes('dismissOnboardingTip'), '画布 Got it → markSeen');

// --- Harmony 录音气泡 ---
const np = read('note/src/main/ets/ui/editor/NotePage.ets');
check(np.includes('showRecordingTip') && np.includes('FIRST_RECORDING'),
  'FIRST_RECORDING 录音按钮锚点');
check(np.includes('tipSeen(OnboardingTooltipKind.NEW_NOTE)'),
  '录音气泡 NEW_NOTE 前置（rh8 z6）');
check(np.includes('noteHasContent: !this.emptyNoteActions'),
  '页内容存在性直通工具栏');

// --- Harmony 库侧锚点 ---
const lp = read('note/src/main/ets/ui/library/LibraryPage.ets');
check(lp.includes('libraryTipVisible') && lp.includes('FIRST_NOTE_COMPLETED'),
  'FIRST_NOTE_COMPLETED 首卡锚点');
check(lp.includes('COMPACT_ORGANIZE') && lp.includes('Placement.Bottom'),
  'COMPACT_ORGANIZE Folders 入口锚点');
check(lp.includes('Placement.Right'), '首卡 pos4→Right');

// --- Harmony 本地化 ---
const base = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
for (const s of ['new_note_tooltip_text', 'first_tray_opened_tooltip_text',
  'first_ink_insert_tooltip_text', 'first_image_tooltip_text',
  'first_recording_tooltip_text', 'first_text_tooltip_text',
  'first_import_tooltip_text', 'first_undo_redo_tooltip_text',
  'first_highlighter_tooltip_text', 'first_note_completed_tooltip_text',
  'compact_organize_tooltip_text', 'got_it']) {
  check(base.includes(`"data_onboarding__${s}"`), `base ${s}`);
  check(zh.includes(`"data_onboarding__${s}"`), `zh_CN ${s}`);
}

// --- 文档 ---
check(read('docs/migration/adr/ADR-0660-original-onboarding-tooltips.md')
  .includes('onboardingTooltipSeen'), 'ADR-0660 声明 seen 集语义');
check(read('docs/migration/evidence/original-onboarding-tooltips-jadx-2026-09-26.md')
  .includes('pq9'), '证据文档');

console.log(`D02_ORIGINAL_ONBOARDING_TOOLTIPS_OK TOTAL=${total} FAILED=0`);
