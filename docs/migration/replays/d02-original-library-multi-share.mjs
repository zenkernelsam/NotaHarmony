// Phase 674 — 原版多笔记分享（v6d.a isMultiNote + s6d _multi 标签 +
// lc4 Share 图标交付 + 多文件系统分享）。
// 原版证据（decompiled_1.0.3）：
//   b7d.java    构造器：K=noteIds 列表；v6d.a = list.size()>1；
//     默认格式 list.size()>1 → PDF 否则 LINK；i() 导出协程消费
//     v6d 整体（含 i=bg、j=rec、k=密码、l=页集）。
//   v6d.java    a=isMultiNote（toString 字段序确认）。
//   dih.java    a()：v6d.a=true → 跳过 e() 页范围 composable；
//     h()（PDF 选项）：同样 v6d.a 短路页范围但保留密码行与双开关；
//     d()（NOTE）录音开关；a 选项（JPG/PNG）背景开关；
//     b()（LINK）账号域权限行。
//   s6d.java    五格式枚举 + _multi chip/action 标签组。
//   strings.xml ui_share__chip_{pdf,note,jpg,png}_multi /
//     action_*_multi / multi_subject="Notes" /
//     subtitle_multi="Share a PDF, a note or an image."
//   ExportFileProvider.java  FileProvider 暴露 exports/ 内容 URI —
//     ACTION_SEND_MULTIPLE 的多文件交付机制。
//   l05/fj9/gj9  底栏 Share 图标（lc4.a(ac4.L) 旗标门控）。
// Harmony 对齐：MultiSelectActionBar 增 Share 按钮（lc4 旗标本期
// 交付）；MultiShareSheet = chip 行（_multi 标签、LINK 置灰）+
// 分格式选项（PDF=双开关+密码行、NOTE=录音、JPG/PNG=背景、无页
// 范围——v6d.a）+ Cancel/"Share Xs" 动作行；multiShare() 逐笔记
// 产出临时文件（.note=exportNote(includeRecordings)；PDF=全页
// renderPageExport→JPEG→buildPdf→可选 encryptPdfFile；JPG/PNG=
// 全页图象 page_NNN.<ext> zip——Phase 644 同构适配）→
// systemShare.SharedData 多 SharedRecord（utd+fileUri）→
// getWant→startAbility 系统分享面板。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const b7d = fs.readFileSync(`${originalRoot}sources/defpackage/b7d.java`, 'utf8');
const v6d = fs.readFileSync(`${originalRoot}sources/defpackage/v6d.java`, 'utf8');
const dih = fs.readFileSync(`${originalRoot}sources/defpackage/dih.java`, 'utf8');
const s6d = fs.readFileSync(`${originalRoot}sources/defpackage/s6d.java`, 'utf8');
const efp = fs.readFileSync(`${originalRoot}sources/com/gingerlabs/notability/data/library/state/ExportFileProvider.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const lib = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const pdfExporter = fs.readFileSync('note/src/main/ets/data/PagePdfExporter.ets', 'utf8');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
const check = (cond, label) => {
  total++;
  try { assert.ok(cond, label); }
  catch (e) { console.error(`FAILED: ${label}`); throw e; }
};

// ---------- 原版证据 ----------
check(b7d.includes('list.size() > 1 ? s6d.PDF : s6d.LINK'),
  'original b7d defaults multi-note share to PDF');
check(v6d.includes('boolean a'), 'original v6d.a field exists');
check(/if \(v6dVar\.a\) \{[\s\S]*?\} else \{[\s\S]*?e\(v6dVar/.test(dih),
  'original dih skips the page-range composable when isMultiNote');
check(stringsXml.includes('ui_share__chip_pdf_multi') &&
  stringsXml.includes('ui_share__chip_note_multi') &&
  stringsXml.includes('ui_share__chip_jpg_multi') &&
  stringsXml.includes('ui_share__chip_png_multi') &&
  stringsXml.includes('ui_share__action_pdf_multi') &&
  stringsXml.includes('ui_share__action_note_multi') &&
  stringsXml.includes('ui_share__multi_subject') &&
  stringsXml.includes('ui_share__subtitle_multi'),
  'original multi-note share strings present');
check(efp.includes('exports') && efp.includes('openFile'),
  'original ExportFileProvider delivers exported files as content URIs');
check(s6d.length > 0, 'original s6d format enum exists');

// ---------- Harmony 状态与入口 ----------
check(lib.includes('@State multiShareOpen: boolean = false;') &&
  lib.includes("@State multiShareFormat: string = 'pdf';") &&
  lib.includes('@State multiShareIncludeBackground: boolean = false;') &&
  lib.includes('@State multiShareIncludeRecording: boolean = true;') &&
  lib.includes('@State multiSharePassword: string | null = null;'),
  'multi-share state mirrors v6d multi defaults (PDF + bg=false + rec=true)');

const actBar = lib.indexOf('MultiSelectActionBar() {');
check(actBar >= 0 &&
  lib.slice(actBar, actBar + 3200).includes("Button($r('app.string.share'))") &&
  lib.slice(actBar, actBar + 3200).indexOf("app.string.share") <
    lib.slice(actBar, actBar + 3200).indexOf('duplicate_note') &&
  lib.slice(actBar, actBar + 3200).includes('this.multiShareOpen = true;'),
  'Share action opens the multi-share sheet (lc4 flag delivered)');

// ---------- 面板结构 ----------
check(lib.includes('.bindSheet(this.multiShareOpen, this.MultiShareSheet()'),
  'MultiShareSheet bound via bindSheet');
const sheet = lib.indexOf('MultiShareSheet() {');
check(sheet >= 0 &&
  lib.slice(sheet, sheet + 4200).includes('share_multi_subject') &&
  lib.slice(sheet, sheet + 4200).includes('share_multi_subtitle') &&
  lib.slice(sheet, sheet + 4200).includes('share_chip_pdf_multi') &&
  lib.slice(sheet, sheet + 4200).includes('share_chip_note_multi') &&
  lib.slice(sheet, sheet + 4200).includes('share_chip_jpg_multi') &&
  lib.slice(sheet, sheet + 4200).includes('share_chip_png_multi') &&
  lib.slice(sheet, sheet + 4200).includes('share_cancel'),
  'sheet renders multi_subject/subtitle + _multi chips + Cancel');
check(!lib.slice(sheet, sheet + 4200).includes('share_page_range'),
  'no page-range row in multi mode (v6d.a hides it)');
check(lib.slice(sheet, sheet + 4200).includes('share_include_background') &&
  lib.slice(sheet, sheet + 4200).includes('share_include_recording'),
  'include toggles preserved for multi (j6d semantics)');
check(lib.slice(sheet, sheet + 4200).includes('MultiSharePasswordRow()'),
  'PDF password row preserved for multi (dih.h keeps it)');
check(lib.slice(sheet, sheet + 4200).includes('share_link_unavailable'),
  'LINK stays fail-closed in multi share');
check(lib.includes("enabled(format !== 'link')") ||
  lib.includes("enabled(this.multiShareFormat !== 'link'"),
  'LINK chip/action disabled');

// ---------- 密码行 ----------
const pwRow = lib.indexOf('MultiSharePasswordRow() {');
check(pwRow >= 0 &&
  lib.slice(pwRow, pwRow + 3400).includes('share_password_enter') &&
  lib.slice(pwRow, pwRow + 3400).includes('share_password_confirm') &&
  lib.slice(pwRow, pwRow + 3400).includes('share_password_mismatch') &&
  lib.slice(pwRow, pwRow + 3400).includes('InputType.Password') &&
  lib.slice(pwRow, pwRow + 3400).includes('multiSharePasswordDraft.length > 0'),
  'password entry mirrors kw1/kv1 (empty-draft Save disabled + match check)');

// ---------- 分发与交付 ----------
const mShare = lib.indexOf('private async multiShare(): Promise<void> {');
check(mShare >= 0, 'multiShare exists');
const mBody = lib.slice(mShare, mShare + 8000);
check(mBody.includes('exporter.exportNote(id,\n            includeRecording)'),
  'NOTE export threads includeRecording per note');
check(mBody.includes('pageRepo.getPages(id)') &&
  mBody.includes('renderer.renderPageExport(id,'),
  'PDF/image export renders all pages per note (v6d.a → no subset)');
check(mBody.includes('buildPdf(imagePages)') &&
  mBody.includes('encryptPdfFile(path, encPath, password)'),
  'PDF built per note and encrypted with the shared password (v6d.k)');
check(mBody.includes('new ZipWriter()') && mBody.includes('page_'),
  'JPG/PNG multi export zips whole-note pages per note (P644 adaptation)');
check(mBody.includes('uniformTypeDescriptor.UniformDataType.PDF') &&
  mBody.includes('uniformTypeDescriptor.UniformDataType.FILE') &&
  mBody.includes('uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE'),
  'SharedRecord utd per format');
check(mBody.includes('fileUri.getUriFromPath'),
  'file URIs produced for share records');
check(mBody.includes('new systemShare.SharedData(records[0])') &&
  mBody.includes('shared.addRecord(records[i])') &&
  mBody.includes('systemShare.getWant(shared)') &&
  mBody.includes('context.startAbility(want)'),
  'ACTION_SEND_MULTIPLE equivalent via systemShare multi-record want');
check(mBody.includes("app.string.multi_share_failed"),
  'failure path toasts multi_share_failed');
check(mBody.includes("this.multiShareOpen = false"),
  'sheet closes after successful share dispatch');

// ---------- 导出器 ----------
check(pdfExporter.includes('export function encryptPdfFile'),
  'encryptPdfFile exported for multi-PDF reuse');

// ---------- 字符串 ----------
for (const key of ['"share_multi_subject"', '"share_multi_subtitle"',
  '"share_chip_pdf_multi"', '"share_chip_note_multi"',
  '"share_chip_jpg_multi"', '"share_chip_png_multi"',
  '"share_action_pdf_multi"', '"share_action_note_multi"',
  '"share_action_jpg_multi"', '"share_action_png_multi"',
  '"multi_share_failed"']) {
  check(baseStrings.includes(key) && zhStrings.includes(key),
    `${key} localized in both locales`);
}

console.log(`D02_ORIGINAL_LIBRARY_MULTI_SHARE_OK TOTAL=${total} FAILED=0`);
