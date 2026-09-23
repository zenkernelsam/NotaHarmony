// Phase 641 — 编辑器右上角 Share 入口与分享格式面板（原版 x90.g 顶栏 →
// b7d/v6d 分享面板 → s6d 五格式枚举）。
// 原版派发链（decompiled_1.0.3）：
//   x90.g 顶栏组合：undo/redo 图标块（p9f）之后，
//     `if (lc4.a(ac4.L)) m18.i(function3, bfd.o(md8Var, 48.0f), ..., cq.b, ...)`
//     —— ac4.L = NOTE_SHARE（zb4.L = PRODUCTION 档，lc4.a 对 PRODUCTION 默认
//     返回 true），cq.b = ke1(15) 渲染 ui_designsystem__share 图标 +
//     feature_note__toprighttoolbar_share_action 无障碍文案。
//   点击 → 分享面板 b7d/v6d：格式枚举 s6d = LINK、PDF、NOTE、JPG、PNG
//     （atc case3~7 各自 share_link/share_pdf/share_note/share_jpg/share_png
//     图标）；单笔记默认选中 LINK（b7d: list.size()>1 ? PDF : LINK），
//     LINK 依赖账号/链接后端。
// Harmony 对齐（fail-closed 子集，见 ADR-0608）：
//   * EditorToolbar 在 Redo 之后渲染 48vp Share 按钮（↗ 图标 +
//     cd_share_action 无障碍），点击打开 bindSheet 分享面板；
//   * 面板按 s6d 原序列出 LINK/PDF/NOTE/JPG/PNG 五行；NOTE 行可点，
//     复用库级 NoteExporter.exportToFile 管线（.note 包 + 系统保存对话框 +
//     export_done/export_failed toast）；LINK/PDF/JPG/PNG 置灰并标注
//     暂不支持（PDF/JPG/PNG 需页级栅格化器，LINK 需账号后端）；
//   * NotePage.onShareNote 走 photoImportLeaseActive/pageOperationBusy/
//     historyPending 门禁后调 shareNoteAsFile()。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const x90 = fs.readFileSync(`${originalRoot}x90.java`, 'utf8');
const ke1 = fs.readFileSync(`${originalRoot}ke1.java`, 'utf8');
const ac4 = fs.readFileSync(`${originalRoot}ac4.java`, 'utf8');
const zb4 = fs.readFileSync(`${originalRoot}zb4.java`, 'utf8');
const lc4 = fs.readFileSync(`${originalRoot}lc4.java`, 'utf8');
const s6d = fs.readFileSync(`${originalRoot}s6d.java`, 'utf8');
const atc = fs.readFileSync(`${originalRoot}atc.java`, 'utf8');
const b7d = fs.readFileSync(`${originalRoot}b7d.java`, 'utf8');

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const strBase = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const strZh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据：顶栏 Share 图标 ---
check(x90.includes('if (lc4.a(ac4.L))'),
  'x90.g gates the share icon behind the NOTE_SHARE flag');
check(x90.indexOf('new p9f(wrdVar, i8)') < x90.indexOf('cq.b, uz4Var2'),
  'share icon renders after the undo/redo icon block in the top bar');
check(ke1.includes('R.drawable.ui_designsystem__share') &&
  ke1.includes('R.string.feature_note__toprighttoolbar_share_action'),
  'ke1 case 15 renders the share icon with the original a11y label');
check(ac4.includes('ac4 ac4Var = new ac4("NOTE_SHARE", 0, zb4Var, ntbVar, null)') &&
  ac4.includes('zb4 zb4Var = zb4.L'),
  'NOTE_SHARE is registered at the PRODUCTION tier');
check(zb4.includes('new zb4("PRODUCTION", 3)'),
  'zb4.L = PRODUCTION ordinal 3');
check(lc4.includes('if (iOrdinal != 3)') && lc4.includes('return true;'),
  'lc4.a enables production-tier flags by default');
check(s6d.includes('LINK(R.string.ui_share__chip_link') &&
  s6d.includes('PDF(R.string.ui_share__chip_pdf') &&
  s6d.includes('NOTE(R.string.ui_share__chip_note') &&
  s6d.includes('JPG(R.string.ui_share__chip_jpg') &&
  s6d.includes('PNG(R.string.ui_share__chip_png'),
  's6d enumerates LINK, PDF, NOTE, JPG, PNG share formats');
check(s6d.indexOf('LINK(') < s6d.indexOf('PDF(') &&
  s6d.indexOf('PDF(') < s6d.indexOf('NOTE(') &&
  s6d.indexOf('NOTE(') < s6d.indexOf('JPG(') &&
  s6d.indexOf('JPG(') < s6d.indexOf('PNG('),
  'original share format order is LINK, PDF, NOTE, JPG, PNG');
check(atc.includes('R.drawable.ui_designsystem__share_pdf') &&
  atc.includes('R.drawable.ui_designsystem__share_note') &&
  atc.includes('R.drawable.ui_designsystem__share_jpg') &&
  atc.includes('R.drawable.ui_designsystem__share_png'),
  'atc cases 4-7 render per-format share icons');
check(b7d.includes('list.size() > 1 ? s6d.PDF : s6d.LINK'),
  'single-note share defaults to LINK upstream (registered divergence)');

// --- Harmony：工具栏入口 ---
check(toolbar.includes("Button('↗')") && toolbar.includes('showShareSheet = true'),
  'EditorToolbar renders a share button that opens the share sheet');
check(toolbar.indexOf('cd_redo_action') < toolbar.indexOf('cd_share_action'),
  'share button sits after the redo button (original ordering)');
check(toolbar.includes("accessibilityText($r('app.string.cd_share_action'))"),
  'share button carries the original-aligned a11y label');
check(toolbar.includes('onShareNote: () => void'),
  'EditorToolbar exposes the NOTE-format export callback');
check(toolbar.includes('.bindSheet(this.showShareSheet, this.buildShareSheet()'),
  'share panel binds as a sheet on the toolbar');
check(toolbar.indexOf("ShareFormatRow($r('app.string.share_link'), false)") <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_pdf'), false)") &&
  toolbar.indexOf("ShareFormatRow($r('app.string.share_pdf'), false)") <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_note'), true)") &&
  toolbar.indexOf("ShareFormatRow($r('app.string.share_note'), true)") <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_jpg'), false)") &&
  toolbar.indexOf("ShareFormatRow($r('app.string.share_jpg'), false)") <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_png'), false)"),
  'share sheet lists all five formats in the original s6d order');
check(toolbar.includes("ShareFormatRow($r('app.string.share_note'), true)"),
  'only the NOTE format row is enabled');
check(toolbar.includes('.opacity(supported ? 1 : 0.4)') &&
  toolbar.includes('share_format_unsupported'),
  'unsupported formats render dimmed with an unsupported caption');
check(toolbar.includes('this.showShareSheet = false;\n      this.onShareNote();'),
  'tapping NOTE closes the sheet and exports');

// --- Harmony：NotePage 接线与导出管线 ---
check(notePage.includes('onShareNote: () => {') &&
  notePage.includes('this.shareNoteAsFile();'),
  'NotePage wires onShareNote to the export path');
check(notePage.indexOf('onShareNote: () => {') > notePage.indexOf('onRedo: () => {'),
  'onShareNote is registered alongside undo/redo callbacks');
check(notePage.includes('private shareNoteAsFile(): void {') &&
  notePage.includes('new NoteExporter(DatabaseManager.getInstance(), this.persistence)') &&
  notePage.includes('exporter.exportToFile(context, this.noteId, this.noteTitle)'),
  'shareNoteAsFile exports the open note through the library-grade pipeline');
check(notePage.includes("import { NoteExporter } from '../../data/NoteExporter';"),
  'NotePage imports NoteExporter');
check(notePage.includes("$r('app.string.export_done') : $r('app.string.export_failed')"),
  'export result reuses the existing done/failed toasts');
check(exporter.includes('async exportToFile(context: common.UIAbilityContext, noteId: string, title: string)'),
  'exportToFile already drives the system save picker for .note packages');

// --- 字符串资源（双语） ---
for (const name of ['cd_share_action', 'share_sheet_title', 'share_link',
  'share_pdf', 'share_note', 'share_jpg', 'share_png', 'share_format_unsupported']) {
  check(strBase.includes(`"name": "${name}"`), `base locale defines ${name}`);
  check(strZh.includes(`"name": "${name}"`), `zh_CN locale defines ${name}`);
}

console.log(`D05_ORIGINAL_EDITOR_SHARE_REPLAY_OK TOTAL=${total} FAILED=0`);
