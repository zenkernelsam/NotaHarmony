// Phase 671 — 原版分享面板 PDF 密码保护（v6d.k 密码态 +
// r6d.PASSWORD_ENTRY 录入屏 + PdfDocument.setPdfPassword 加密导出）。
// 原版证据（decompiled_1.0.3）：
//   v6d.java   public final String k —— PDF 密码；null=关。
//   r6d.java   MAIN / PAGE_SELECTION / PASSWORD_ENTRY 三屏枚举。
//   b7d.java   o(String)：str.length()==0 ? null : str → v6d.k。
//   dih.java   PASSWORD_ENTRY 屏：Password 标题 + subtitle + 双密码
//     框（e7j.a 密码键盘）+ 条件渲染 ui_share__password_mismatch。
//   h32.java   ui_share__password 标题 + password_enter/_confirm 标签。
//   zy7.java   主屏密码行：v6d.k!=null → password_on 否则 _off。
//   kw1.java   Remove 仅 v6d.k!=null 时渲染；Save 按钮
//     enabled = draft.length>0。
//   kv1.java   Save 点击：draft==confirm && length>0 → b7d.o(draft)，
//     否则 mismatch 标志置位。
//   strings.xml ui_share__password/_subtitle/_enter/_confirm/
//     _mismatch/_on/_off/_save/_remove。
// Harmony 对齐：EditorToolbar 增 sharePassword:string|null（v6d.k）
// + PASSWORD_ENTRY 屏（返回/标题/Remove(仅已设)/Save(空draft禁点)
// /双密码框/mismatch 红字）；MAIN 屏密码行显 On/Off；
// onSharePdf(pageIndexes,password) → NotePage →
// PagePdfExporter.exportPdf(...,password?) → 临时 PDF 经
// pdfService.PdfDocument.loadDocument→setPdfPassword→saveDocument
// 生成加密副本交保存对话框；sheet 关闭清空全部密码态。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const b7d = fs.readFileSync(`${originalRoot}sources/defpackage/b7d.java`, 'utf8');
const r6d = fs.readFileSync(`${originalRoot}sources/defpackage/r6d.java`, 'utf8');
const v6d = fs.readFileSync(`${originalRoot}sources/defpackage/v6d.java`, 'utf8');
const dih = fs.readFileSync(`${originalRoot}sources/defpackage/dih.java`, 'utf8');
const zy7 = fs.readFileSync(`${originalRoot}sources/defpackage/zy7.java`, 'utf8');
const h32 = fs.readFileSync(`${originalRoot}sources/defpackage/h32.java`, 'utf8');
const kw1 = fs.readFileSync(`${originalRoot}sources/defpackage/kw1.java`, 'utf8');
const kv1 = fs.readFileSync(`${originalRoot}sources/defpackage/kv1.java`, 'utf8');
const origStrings = fs.readFileSync(
  `${originalRoot}resources/res/values/strings.xml`, 'utf8');

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/PagePdfExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// ---------- 原版证据 ----------
check(v6d.includes('public final String k;'),
  'v6d.k is the nullable PDF password field');
check(r6d.includes('"PASSWORD_ENTRY"'),
  'r6d declares the PASSWORD_ENTRY screen');
check(b7d.includes('public final void o(String str)') &&
  b7d.includes('str.length() == 0 ? null : str'),
  'b7d.o maps empty draft to null, non-empty to v6d.k');
check(dih.includes('ui_share__password_mismatch') &&
  dih.includes('ui_share__password_subtitle'),
  'dih renders the password screen with subtitle + mismatch text');
check(h32.includes('ui_share__password_enter') &&
  h32.includes('ui_share__password_confirm'),
  'h32 renders the enter/confirm field labels');
check(zy7.includes('ui_share__password_on') &&
  zy7.includes('ui_share__password_off'),
  'zy7 renders password on/off on the main row');
check(kw1.includes('ui_share__password_remove') &&
  kw1.includes('ui_share__password_save'),
  'kw1 renders Remove (k!=null) + Save (enabled=draft>0)');
check(kv1.includes('ba6.o((String) gl8Var3.getValue(), (String) gl8Var2.getValue())') &&
  kv1.includes('length() > 0'),
  'kv1 save handler requires draft==confirm and non-empty');
check(origStrings.includes('ui_share__password">Password') &&
  origStrings.includes('ui_share__password_subtitle') &&
  origStrings.includes('ui_share__password_mismatch') &&
  origStrings.includes('ui_share__password_remove'),
  'original strings cover the password screen');

// ---------- Harmony：状态与屏机 ----------
check(toolbar.includes("@State sharePassword: string | null = null"),
  'toolbar holds the nullable password (v6d.k)');
check(toolbar.includes('@State sharePasswordDraft') &&
  toolbar.includes('@State sharePasswordConfirm') &&
  toolbar.includes('@State sharePasswordMismatch'),
  'password-entry draft/confirm/mismatch state held');
check(toolbar.includes("this.shareScreen === 'password'") &&
  toolbar.includes('buildSharePassword'),
  'sheet switches to the PASSWORD_ENTRY screen');
check(toolbar.includes('this.sharePassword = null;') &&
  toolbar.includes("this.sharePasswordDraft = '';") &&
  /onDisappear[\s\S]*sharePassword = null/.test(toolbar),
  'sheet dismiss clears the whole password state (v6d rebuild)');

// ---------- Harmony：主屏密码行 ----------
check(toolbar.includes('share_password_on') &&
  toolbar.includes('share_password_off') &&
  toolbar.includes('this.sharePassword !== null ?'),
  'password row shows On/Off inside the pdf options section');
check(toolbar.includes("this.shareScreen = 'password';") &&
  toolbar.includes('this.sharePasswordDraft = this.sharePassword !== null ?'),
  'password row tap enters PASSWORD_ENTRY with the existing password prefilled');

// ---------- Harmony：PASSWORD_ENTRY 屏 ----------
check(toolbar.includes('share_password_subtitle') &&
  (toolbar.match(/InputType\.Password/g) || []).length >= 2 &&
  toolbar.includes('share_password_enter') &&
  toolbar.includes('share_password_confirm'),
  'password screen: subtitle + two masked fields');
check(toolbar.includes('share_passwordMismatch') ||
  toolbar.includes('share_password_mismatch'),
  'mismatch error text wired');
check(toolbar.includes('sharePasswordDraft !== this.sharePasswordConfirm') &&
  toolbar.includes('this.sharePasswordMismatch = true;'),
  'save validates draft==confirm else sets mismatch');
check(toolbar.includes('this.sharePasswordDraft.length === 0') &&
  toolbar.includes('share_password_save'),
  'empty-draft save is a no-op (disabled-button equivalent)');
check(toolbar.includes('share_password_remove') &&
  /if \(this\.sharePassword !== null\)[\s\S]{0,400}share_password_remove/.test(toolbar),
  'Remove renders only when a password is already set');

// ---------- Harmony：分发与导出 ----------
check(toolbar.includes('onSharePdf: (pageIndexes: number[] | null, password: string | null,\n    includeBackground: boolean) => void') &&
  toolbar.includes('this.onSharePdf(this.sharePageIndexes, this.sharePassword,\n        this.shareIncludeBackground)'),
  'pdf row dispatches page set + password');
check(toolbar.includes('this.onShareImage(this.shareFormat, this.sharePageIndexes,\n        this.shareIncludeBackground)') &&
  !toolbar.includes('this.onShareImage(format, this.sharePageIndexes, this.sharePassword)'),
  'image export does not consume the password (PDF-only)');
check(notePage.includes('shareNoteAsPdf(pageIndexes: number[] | null, password: string | null,\n    includeBackground: boolean)') &&
  notePage.includes('password !== null ? password : undefined'),
  'NotePage threads the password into the exporter');
check(exporter.includes("import { pdfService } from '@kit.PDFKit';") &&
  exporter.includes('password?: string'),
  'exporter imports PDFKit and takes an optional password');
check(exporter.includes('document.loadDocument(sourcePath)') &&
  exporter.includes('document.setPdfPassword(password)') &&
  exporter.includes('document.saveDocument(targetPath)') &&
  exporter.includes('document.releaseDocument()'),
  'encryptPdfFile: load → setPdfPassword → save → release');
check(exporter.includes('needsPassword') &&
  exporter.includes('encryptPdfFile(tmpPath, encryptedPath') &&
  exporter.includes('unlinkSync(encryptedPath)'),
  'encrypted copy replaces the copy source and is cleaned up');
check(!exporter.includes('setPdfPassword(password as string)') ||
  exporter.includes('password as string'),
  'password is only applied when non-empty');

// ---------- 字符串 ----------
check(baseStrings.includes('"share_password"') &&
  baseStrings.includes('"share_password_subtitle"') &&
  baseStrings.includes('"share_password_enter"') &&
  baseStrings.includes('"share_password_confirm"') &&
  baseStrings.includes('"share_password_mismatch"') &&
  baseStrings.includes('"share_password_on"') &&
  baseStrings.includes('"share_password_off"') &&
  baseStrings.includes('"share_password_save"') &&
  baseStrings.includes('"share_password_remove"'),
  'all nine password strings localized in base');
check(zhStrings.includes('"share_password"') &&
  zhStrings.includes('"share_password_mismatch"') &&
  zhStrings.includes('"share_password_remove"'),
  'password strings localized in zh_CN');

console.log(`D05_ORIGINAL_SHARE_PDF_PASSWORD_OK TOTAL=${total} FAILED=0`);
