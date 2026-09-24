// Phase 660 — 加密 PDF 导入的密码处理（原版 ou5.onPasswordSubmitted 流程）。
// 原版证据（decompiled_1.0.3）：
//   w7a.java     PasswordPromptState(fileName, isRetry) —— 导入详情面板持有
//                的密码询问状态，isRetry 表示上次密码错误后的重试；
//   zvh.java     导入详情面板：w7aVar != null 时渲染密码对话框
//                zvh.e(fileName, isRetry, onPasswordSubmitted, onPasswordCancelled)，
//                回调以 o1(1, ou5, "onPasswordSubmitted(String)") /
//                n3(0, ou5, "onPasswordCancelled()") 绑定到 ou5 ViewModel；
//   ou5.java     ImportDetailsViewModel（持有 jv5/yq8/id7），接收提交/取消。
// Harmony 对齐：PDFKit loadDocument(path, password?) 命中加密返回
//   PARSE_ERROR_PASSWORD(3) → 调 PdfPasswordPrompt(fileName, attempt) 回调
//   （attempt=0 首问，>0 重试）→ PdfPasswordDialog 输入 → 带密码重载；
//   成功后 removeSecurity + saveDocument 落无密码暂存文件，作为后续资产与
//   渲染的有效字节（PdfBackgroundLoader 的 loadDocument(path) 无需密码）；
//   返回 null → CANCELLED 中止该文件；无回调 → CORRUPTED fail-closed；
//   finally 清理暂存 + 解密暂存两个临时文件。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const w7a = fs.readFileSync(`${originalRoot}sources/defpackage/w7a.java`, 'utf8');
const zvh = fs.readFileSync(`${originalRoot}sources/defpackage/zvh.java`, 'utf8');
const ou5 = fs.readFileSync(`${originalRoot}sources/defpackage/ou5.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const dialog = fs.readFileSync('note/src/main/ets/ui/components/PdfPasswordDialog.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const backup = fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');
const pdfDts = fs.readFileSync(
  'C:/Program Files/Huawei/DevEco Studio/sdk/default/hms/ets/api/@hms.officeservice.pdfservice.d.ts',
  'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：PasswordPromptState + 提交/取消回调绑定到 ou5 ---
check(w7a.includes('PasswordPromptState(fileName=') &&
  w7a.includes('isRetry='),
  'original w7a is PasswordPromptState(fileName, isRetry) — a retry flag exists');
check(zvh.includes('"onPasswordSubmitted", "onPasswordSubmitted(Ljava/lang/String;)V"') &&
  zvh.includes('"onPasswordCancelled", "onPasswordCancelled()V"'),
  'zvh binds onPasswordSubmitted(String)/onPasswordCancelled() onto ou5');
check(zvh.includes('w7aVar == null') &&
  zvh.includes('String str6 = w7aVar.a') &&
  zvh.includes('boolean z7 = w7aVar.b'),
  'zvh renders the password dialog only while PasswordPromptState is non-null');
check(zvh.includes('e(str6, z7, ix4Var5, function6, uz4Var, 0)') &&
  zvh.includes('public static final void e(String str, boolean z, ix4 ix4Var, Function0 function0'),
  'zvh.e(fileName, isRetry, onSubmitted, onCancelled) is the password dialog');
check(ou5.includes('public final yq8 K') && ou5.includes('public final jv5 L'),
  'ou5 is the import-details ViewModel that receives submit/cancel');

// --- Harmony PDFKit 能力：密码参数 + 密码错误码 + 去加密保存 ---
check(pdfDts.includes('loadDocument(path: string, password?: string'),
  'PDFKit loadDocument accepts an optional password');
check(pdfDts.includes('PARSE_ERROR_PASSWORD = 3') ||
  pdfDts.includes('PARSE_ERROR_PASSWORD'),
  'PDFKit reports password-required via PARSE_ERROR_PASSWORD');
check(pdfDts.includes('removeSecurity()') &&
  pdfDts.includes('saveDocument(path: string'),
  'PDFKit removeSecurity + saveDocument support decrypt-resave');

// --- 契约：PdfPasswordPrompt(fileName, attempt) 回调 ---
check(importer.includes('export type PdfPasswordPrompt =') &&
  importer.includes('(fileName: string, attempt: number) => Promise<string | null>'),
  'PdfPasswordPrompt(fileName, attempt) -> password | null is the import contract');
check(importer.includes('attempt=0 为首问') ||
  importer.includes('attempt=0'),
  'attempt=0 is the first prompt (isRetry=false upstream)');

// --- 解析层：parseImportedPdf 密码感知 ---
const parseFn = section(importer, 'function parseImportedPdf(',
  'interface ImportedImagePreparation');
check(parseFn.includes('password: string | null'),
  'parseImportedPdf takes a nullable password');
check(parseFn.includes('document.loadDocument(path, password)'),
  'parseImportedPdf retries loadDocument with the supplied password');
check(parseFn.includes('parsed === pdfService.ParseResult.PARSE_ERROR_PASSWORD') &&
  parseFn.includes('passwordRequired: true'),
  'PARSE_ERROR_PASSWORD maps to passwordRequired instead of a generic failure');
check(parseFn.includes('document.removeSecurity()') &&
  parseFn.includes('document.saveDocument(decryptedPath)') &&
  parseFn.includes('decryptedBytes'),
  'successful password parse decrypts and resaves the document bytes');
check(parseFn.includes('finally') && parseFn.includes('document.releaseDocument()'),
  'parseImportedPdf releases the PdfDocument in finally');

// --- 重试循环：stageAndParseImportedPdf ---
const stageFn = section(importer, 'private async stageAndParseImportedPdf(',
  '// 原版 cv5 图片分支');
check(stageFn.includes('while (true)') &&
  stageFn.includes('parseImportedPdf(stagingPath, decryptedPath, password)'),
  'staging loop re-parses with each submitted password');
check(stageFn.includes('password = await passwordPrompt(fileName, attempt)') &&
  stageFn.includes('attempt++'),
  'each retry re-prompts with an incremented attempt count');
check(stageFn.includes('password === null') &&
  stageFn.includes('result: ImportResult.CANCELLED'),
  'a null password maps to CANCELLED (onPasswordCancelled upstream)');
check(stageFn.includes('passwordPrompt === undefined') &&
  stageFn.includes('暂不支持导入'),
  'missing prompt fails closed as CORRUPTED rather than hanging');
check(stageFn.includes('unlinkSync(stagingPath)') &&
  stageFn.includes('unlinkSync(decryptedPath)'),
  'both staging files are cleaned up in finally');
check(stageFn.includes('parse.decryptedBytes === null ? data : parse.decryptedBytes'),
  'unencrypted imports keep the original bytes; decrypted bytes replace them');

// --- 分发透传：所有入口线程化回调 ---
check(importer.includes('async importFromFile(context: common.UIAbilityContext,') &&
  importer.includes('passwordPrompt?: PdfPasswordPrompt') &&
  importer.includes('sheetPrompt?: ImportSheetPrompt'),
  'importFromFile accepts optional password + import-sheet prompts');
check(importer.includes('async importFileIntoNoteFromPicker(context: common.UIAbilityContext,') &&
  importer.includes('noteId: string, passwordPrompt?: PdfPasswordPrompt') &&
  importer.includes('sheetPrompt?: ImportSheetPrompt'),
  'importFileIntoNoteFromPicker accepts optional password + import-sheet prompts');
check(importer.includes('async importFileIntoNote(noteId: string, data: Uint8Array, fileName: string,\n    passwordPrompt?: PdfPasswordPrompt)'),
  'importFileIntoNote threads the prompt for direct calls');
check(importer.includes('importPickedFilesStandalone(uris, passwordPrompt)') &&
  importer.includes('importPickedFilesIntoNote(noteId, uris, passwordPrompt)'),
  'multi-select loops thread the prompt per file (rv5/qv5 semantics kept)');
check(importer.includes('importPdfFromBytes(bytes, fileName, passwordPrompt)') &&
  importer.includes('importPdfIntoNote(noteId, data, fileName, passwordPrompt)'),
  'both PDF paths receive the prompt; other types ignore it');

// --- UI：共享密码对话框 + 三个入口页接线 ---
check(dialog.includes('@CustomDialog') &&
  dialog.includes('export struct PdfPasswordDialog'),
  'PdfPasswordDialog is a shared CustomDialog component');
check(dialog.includes('InputType.Password') &&
  dialog.includes('showPasswordIcon(true)'),
  'dialog input uses password masking');
check(dialog.includes('this.attempt > 0') &&
  dialog.includes('import_pdf_password_wrong'),
  'attempt>0 surfaces the wrong-password retry hint (isRetry upstream)');
check(dialog.includes('this.finish(null)') &&
  dialog.includes('this.finish(this.inputText)'),
  'dialog emits null on cancel and the typed password on submit');
check(notePage.includes('pdfPasswordPrompt') &&
  notePage.includes('importFileIntoNoteFromPicker(context, this.noteId,') &&
  notePage.includes('this.pdfPasswordDialog.open()'),
  'NotePage wires the prompt into the in-note Add Files import');
check(library.includes('importFromFile(context, this.pdfPasswordPrompt,') &&
  library.includes('this.pdfPasswordDialog.open()'),
  'LibraryPage wires the prompt into the standalone import');
check(backup.includes('importFromFile(context, this.pdfPasswordPrompt)') &&
  backup.includes('this.pdfPasswordDialog.open()'),
  'BackupPage wires the prompt into the restore import');
for (const [name, src] of [['NotePage', notePage], ['LibraryPage', library],
  ['BackupPage', backup]]) {
  check(src.includes('pdfPasswordResolve !== null') &&
    src.includes('resolve(null)'),
    `${name} resolves a pending prompt with null on page dispose`);
}

// --- 字符串：base + zh_CN ---
for (const key of ['import_pdf_password_title', 'import_pdf_password_hint',
  'import_pdf_password_wrong', 'import_pdf_password_unlock']) {
  check(baseStrings.includes(`"name": "${key}"`),
    `base strings provide ${key}`);
  check(zhStrings.includes(`"name": "${key}"`),
    `zh_CN strings provide ${key}`);
}

console.log(`D05_ORIGINAL_ENCRYPTED_PDF_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
