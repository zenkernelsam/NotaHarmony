import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets'), 'utf8');
const pageCountReads = source.match(/document\.getPageCount\(\)/g) ?? [];
const checks = [
  ['page metadata uses positive safe integer bounds',
    source.includes('Number.isSafeInteger(pdf.totalPageCount)') &&
      source.includes('pdf.totalPageCount <= 0') &&
      source.includes('Number.isSafeInteger(pdf.pageInAsset)') &&
      source.includes('pdf.pageInAsset < 0') &&
      source.includes('pdf.pageInAsset >= pdf.totalPageCount')],
  ['metadata file size is positive safe integer',
    source.includes('Number.isSafeInteger(pdf.metadata.fileSize)') &&
      source.includes('pdf.metadata.fileSize <= 0')],
  ['local PDF is a matching regular file',
    source.includes('fileIo.statSync(path)') && source.includes('!stat.isFile()') &&
      source.includes('stat.size !== pdf.metadata.fileSize')],
  ['PDFKit page count is read exactly once', pageCountReads.length === 1],
  ['parsed page count is positive, safe, and exact',
    source.includes('Number.isSafeInteger(pageCount)') && source.includes('pageCount <= 0') &&
      source.includes('pageCount !== pdf.totalPageCount') && source.includes('pdf.pageInAsset >= pageCount')],
  ['validation precedes native page access',
    source.indexOf('Number.isSafeInteger(pageCount)') < source.indexOf('document.getPage(pdf.pageInAsset)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
