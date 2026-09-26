// Phase 855 — 分享 ZIP 契约：x59(1.0.3)/x8b(1.4.2) PDF+录音 ZIP
// 写出器登记 + Harmony exportPdfZip 实现校验。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const v103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const v142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/';

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据：x59(1.0.3) / x8b(1.4.2) 同一写出器 ---
for (const [dir, cls] of [[v103, 'x59'], [v142, 'x8b']]) {
  const s = readFileSync(dir + cls + '.java', 'utf8');
  check(s.includes('"Recordings/"'), `${cls} Recordings/ 前缀`);
  check(s.includes('".pdf"') && s.includes('".zip"'), `${cls} pdf→zip 包装`);
  check(s.includes('MimeTypeMap') && s.includes('"mp4"'),
    `${cls} MimeTypeMap 扩展名 + mp4 回退`);
  check(s.includes('putNextEntry') && s.includes('ZipEntry'),
    `${cls} ZipOutputStream 条目写入`);
  check(/string = str1?\d?3 \+ \w+ \+ " \(" \+ r?\d+ \+ "\)\." \+ \w+/
    .test(s) || s.includes('" (" +'), `${cls} 重名 " (N)" 去重`);
}
// 1.0.3 计数器初值 iconst_1（r11 = z2 为 true 折叠）
check(readFileSync(v103 + 'x59.java', 'utf8').includes('r11 = z2'),
  'x59 去重计数自 1 起');
// 空录音列表 → 返回裸 PDF（不产 zip）
check(readFileSync(v103 + 'x59.java', 'utf8')
  .includes('if (listT1.isEmpty())'), 'x59 空表早退裸 PDF');
// 文件名消毒 j0.m：[/\\:*?"<>|\x00]→_、剥前导点、空→"Note"
const j0 = readFileSync(v103 + 'j0.java', 'utf8');
check(j0.includes('Pattern.compile(') && j0.includes('\\\\x00') &&
  j0.includes('"Note"'), 'j0.m 消毒规则');

// --- Harmony 实现 ---
const pdf = readFileSync('note/src/main/ets/data/PagePdfExporter.ets', 'utf8');
check(pdf.includes('async exportPdfZip') && pdf.includes('PdfZipRecordingSource'),
  'exportPdfZip 方法存在');
check(pdf.includes('`Recordings/${baseName}.${ext}`') &&
  pdf.includes('`Recordings/${baseName} (${dup}).${ext}`'),
  'Recordings/ 命名 + " (N)" 自 1 去重');
check(/normalized === 'audio\/mp4'/.test(pdf) && pdf.includes(`'m4a'`) &&
  pdf.includes(`'mp4'`), 'mime→ext 映射 + mp4 回退');
check(pdf.includes("replace(/[/\\\\:*?\"<>|\\x00]/g, '_')") &&
  pdf.includes(`'Note'`), 'j0.m 等价消毒');
check(pdf.includes('fileIo.accessSync(recording.localPath)'),
  '缺失文件跳过（fileH.exists() 语义）');
check(pdf.includes('await writer.build()') && pdf.includes("'ZIP 压缩包|.zip'"),
  'ZipWriter 产物 + .zip 保存对话框');

const toolbar = readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');
check(/onSharePdf: \([^)]*includeRecording: boolean/.test(toolbar),
  'onSharePdf 携带 includeRecording');
check(toolbar.includes('this.shareIncludeBackground, this.shareIncludeRecording'),
  'dispatchShare 传递录音开关');

const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
check(page.includes('includeRecording: boolean): void') &&
  page.includes('listVisible(this.noteId)') &&
  page.includes('exportPdfZip'), 'shareNoteAsPdf 录音解析 + zip 分支');

const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
check(lib.includes('zipWriter.addEntry(entryName, readFileFully(rec.localPath), true)'),
  '多选分享 PDF 分支同样产 zip');

console.log(`${n}/${n} checks passed`);
