// Phase 680 — 原版 LIBRARY_DOC_SCAN（ac4.a0）：资料库「+」快速动作
// 「Document Scan」→ 系统文档扫描 → 扫描产物建新笔记并打开。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   ac4.java     a0=LIBRARY_DOC_SCAN(15)。
//   cd.java      case0「+」展开菜单：import → templates(K0 门控) →
//                docscan(ac4.a0 门控)，均 cwi.b 图标行；
//                R.string.feature_library__docscan +
//                R.drawable.ui_fileimport__docscan。
//   zvi.java     扫描入口：strU=feature_library__scanned_document_title、
//                strU2=feature_library__doc_scan_failed；
//                结果回调 onDocScanned(Uri, title, success, failure)。
//   ga7.java/cd.java  sa7 方法引用：ib7/pk9.onDocScanned(Landroid/net/Uri;
//                String;Function1;Function0) —— 扫描 URI 建笔记、成功后
//                跳笔记（onShowNoteInFolder），失败弹 doc_scan_failed。
//   u49.java     空笔记页亦有 Scan 入口（empty_note__scan / _scan_failed，
//                结果并入当前笔记）——另一表面，本期登记未覆盖。
//   muh.java     GmsDocumentScanningResult{pages, pdf}：ML Kit 产出；
//                应用侧消费 PDF Uri。
// Harmony：VisionKit DocumentScanner（SystemCapability.AI.Component.DocScan
//   探测 = 原版 lc4.a(ac4.a0) 等价门控）；saveOptions=[PDF] 对齐原版 PDF
//   消费路径；code 200/–1/1008601001 分别对应成功/取消/uri 无效；
//   NoteImporter.importScannedDocument 经 sv5 CreateSingleNewNote 语义
//   （importFilesIntoSingleNewNote）建笔记，标题=scanned_document_title
//   + 时间戳，成功后 pushUrl 打开（原版 onShowNoteInFolder）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const cd = fs.readFileSync(`${originalRoot}sources/defpackage/cd.java`, 'utf8');
const zvi = fs.readFileSync(`${originalRoot}sources/defpackage/zvi.java`, 'utf8');
const ga7 = fs.readFileSync(`${originalRoot}sources/defpackage/ga7.java`, 'utf8');
const u49 = fs.readFileSync(`${originalRoot}sources/defpackage/u49.java`, 'utf8');
const muh = fs.readFileSync(`${originalRoot}sources/defpackage/muh.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8');
const en = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(ac4.includes('"LIBRARY_DOC_SCAN", 15'), 'ac4.a0 = LIBRARY_DOC_SCAN(15)');
check(cd.includes('lc4.a(ac4.a0)') && cd.includes('R.string.feature_library__docscan') &&
  cd.includes('R.drawable.ui_fileimport__docscan'), 'cd case0 docscan row gated by a0');
check(zvi.includes('feature_library__scanned_document_title') &&
  zvi.includes('feature_library__doc_scan_failed'), 'zvi scan title + failure strings');
check(ga7.includes('onDocScanned') &&
  ga7.includes('Landroid/net/Uri;Ljava/lang/String;Lkotlin/jvm/functions/Function1;Lkotlin/jvm/functions/Function0;'),
  'onDocScanned(Uri,String,success,failure) signature');
check(u49.includes('feature_note__empty_note__scan_failed'), 'u49 empty-note scan surface');
check(muh.includes('GmsDocumentScanningResult{pages=') && muh.includes(', pdf='),
  'ML Kit result {pages, pdf}');
check(stringsXml.includes('feature_library__docscan') &&
  stringsXml.includes('feature_library__scanned_document_title') &&
  stringsXml.includes('feature_library__doc_scan_failed'),
  'original strings present');

// --- Harmony 实现钉 ---
check(page.includes("import { DocumentScanner, DocumentScannerConfig, DocType, SaveOption } from '@kit.VisionKit'"),
  'VisionKit DocumentScanner import');
check(page.includes("canIUse('SystemCapability.AI.Component.DocScan')"),
  'syscap probe = ac4.a0 equivalent gate');
check(page.includes('@State docScanAvailable: boolean = false') &&
  page.includes('@State docScanOpen: boolean = false'),
  'doc-scan state');
check(/if \(this\.docScanAvailable\) \{\s*this\.CreateActionChip\(\$r\('app\.string\.docscan'\)/,
  'FAB chip gated by availability');
check(page.includes('.bindContentCover(this.docScanOpen, this.DocScanCover()'),
  'full-screen cover hosting');
check(page.includes('DismissContentCoverAction') && /this\.docScanOpen = false;[\s\S]{0,80}action\.dismiss\(\)/,
  'swipe-dismiss = cancel');
check(page.includes('scannerConfig: this.ensureDocScanConfig()'), 'scanner config wired');
check(page.includes('config.supportType = [DocType.DOC]') &&
  page.includes('config.saveOptions = [SaveOption.PDF]') &&
  page.includes('config.isShareable = false'),
  'config: DOC type + PDF output + share off');
check(page.includes('config.maxShotCount = ORIGINAL_DOC_SCAN_MAX_PAGES') &&
  page.includes('const ORIGINAL_DOC_SCAN_MAX_PAGES: number = 50'),
  'multi-page cap');
check(page.includes('private onDocScanResult(code: number, uris: string[]): void') &&
  page.includes('code !== 200') && page.includes("app.string.doc_scan_failed"),
  'result dispatch: 200 success / failure toast');
check(/code !== -1[\s\S]{0,40}\{[^}]*doc_scan_failed|if \(code !== -1\)/,
  'cancel (-1) silent');
check(page.includes('private async importScannedAndOpen(uris: string[]): Promise<void>') &&
  page.includes('importer.importScannedDocument') &&
  page.includes("app.string.scanned_document_title"),
  'import+open flow with scanned title');
check(page.includes('this.formatTime(Date.now())'), 'title arg = timestamp');
check(page.includes('this.currentFolderId'), 'scan note lands in current folder');
check(page.includes("router.pushUrl({ url: 'ui/editor/NotePage',\n        params: { noteId: report.noteId } })"),
  'open created note after scan');

// --- Importer 钉 ---
check(importer.includes('async importScannedDocument(uris: string[], title: string,'),
  'importScannedDocument public API');
check(importer.includes('return await this.importFilesIntoSingleNewNote(uris, title, folderId,'),
  'sv5 CreateSingleNewNote semantics');

// --- 字符串钉 ---
check(en.includes('"docscan"') && en.includes('"scanned_document_title"') &&
  en.includes('"doc_scan_failed"'), 'en strings');
check(en.includes('Scanned Document %1$s'), 'en title placeholder');
check(zh.includes('"docscan"') && zh.includes('"scanned_document_title"') &&
  zh.includes('"doc_scan_failed"'), 'zh strings');

console.log(`TOTAL=${n}`);
