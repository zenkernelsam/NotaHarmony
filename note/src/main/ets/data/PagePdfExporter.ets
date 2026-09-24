// Phase 643 PDF 导出器：逐页 JPEG 栅格 → 内嵌 Image XObject 的 PDF 文档 →
// 系统 picker 保存。原版分享面板 s6d.PDF（atc case4）经 y59 导出整册；
// 上游编码器未反编译，Harmony 采用「每页一张满幅 JPEG」的最小合法 PDF
// （Filter/DCTDecode 直通，无 zlib），页面物理尺寸按 mm→pt（1pt=1/72in）
// 写入 MediaBox，阅读器按页尺寸等比缩放。
import { fileIo, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { pdfService } from '@kit.PDFKit';

const FILE_WRITE_CHUNK_SIZE: number = 64 * 1024;
const FILE_READ_CHUNK_SIZE: number = 64 * 1024;
const MM_TO_PT: number = 72 / 25.4;
// PDF 栅格预算：单页 JPEG 与整册体量都设上限，防 OOM。
const MAX_PAGE_JPEG_BYTES: number = 32 * 1024 * 1024;
const MAX_TOTAL_PDF_BYTES: number = 256 * 1024 * 1024;
const MAX_PAGE_COUNT: number = 512;

// 一页的 PDF 输入：已编码 JPEG 字节 + 像素/物理尺寸。
export interface PdfPageImage {
  jpegData: Uint8Array;
  widthPx: number;
  heightPx: number;
  widthMm: number;
  heightMm: number;
}

export class PagePdfExporter {
  // 组装 PDF → 临时文件 →（可选）PdfDocument.setPdfPassword 加密 →
  // 系统保存对话框；成功 true，取消/失败 false。
  // 原版 ui_share__password_*（v6d.k + r6d.PASSWORD_ENTRY）：密码非空
  // 时对产物二次加密再交保存对话框。
  async exportPdf(context: common.UIAbilityContext, pages: PdfPageImage[],
    title: string, password?: string): Promise<boolean> {
    let tmpPath: string = '';
    let encryptedPath: string = '';
    let tmpFile: fileIo.File | null = null;
    let srcFile: fileIo.File | null = null;
    let dstFile: fileIo.File | null = null;
    try {
      const pdfBytes: Uint8Array = buildPdf(pages);
      tmpPath = `${context.tempDir}/note_export_${Date.now()}.pdf`;
      tmpFile = fileIo.openSync(tmpPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      writeFileFully(tmpFile.fd, pdfBytes, 'temporary pdf export');
      fileIo.fsyncSync(tmpFile.fd);
      fileIo.closeSync(tmpFile);
      tmpFile = null;

      let srcPath: string = tmpPath;
      const needsPassword: boolean = password !== undefined && password.length > 0;
      if (needsPassword) {
        encryptedPath = `${context.tempDir}/note_export_enc_${Date.now()}.pdf`;
        encryptPdfFile(tmpPath, encryptedPath, password as string);
        srcPath = encryptedPath;
      }

      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [`${safeFileName(title)}_${Date.now()}.pdf`];
      saveOptions.fileSuffixChoices = ['PDF 文档|.pdf'];
      const uris: string[] = await documentPicker.save(saveOptions);
      if (uris.length === 0) {
        console.info('exportPdf: user cancelled');
        return false;
      }
      const targetUri: string = uris[0];
      srcFile = fileIo.openSync(srcPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(srcPath);
      const size: number = stat.size;
      if (!Number.isSafeInteger(size) || (!needsPassword && size !== pdfBytes.byteLength)) {
        throw new Error(`temporary pdf export changed before copy: ${size}/${pdfBytes.byteLength} bytes`);
      }
      dstFile = fileIo.openSync(targetUri,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      copyFileFully(srcFile.fd, dstFile.fd, size, 'destination pdf export');
      fileIo.fsyncSync(dstFile.fd);
      fileIo.closeSync(dstFile);
      dstFile = null;
      fileIo.closeSync(srcFile);
      srcFile = null;
      console.info(`exportPdf success: pages=${pages.length} bytes=${size}`);
      return true;
    } catch (e) {
      console.error(`exportPdf failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      if (tmpFile !== null) {
        try { fileIo.closeSync(tmpFile); } catch (_) { }
      }
      if (srcFile !== null) {
        try { fileIo.closeSync(srcFile); } catch (_) { }
      }
      if (dstFile !== null) {
        try { fileIo.closeSync(dstFile); } catch (_) { }
      }
      if (tmpPath.length > 0) {
        try {
          fileIo.unlinkSync(tmpPath);
        } catch (e) {
          // 忽略清理失败
        }
      }
      if (encryptedPath.length > 0) {
        try {
          fileIo.unlinkSync(encryptedPath);
        } catch (e) {
          // 忽略清理失败
        }
      }
    }
  }
}

// 对生成的 PDF 临时文件施加打开密码：PDFKit 载入 → setPdfPassword →
// saveDocument 到第二临时文件。任一步失败抛错走上层 catch →
// export_failed toast（密码不静默降级）。
function encryptPdfFile(sourcePath: string, targetPath: string,
  password: string): void {
  const document: pdfService.PdfDocument = new pdfService.PdfDocument();
  try {
    const result: pdfService.ParseResult = document.loadDocument(sourcePath);
    if (result !== pdfService.ParseResult.PARSE_SUCCESS) {
      throw new Error(`encrypt pdf load failed: ${result}`);
    }
    if (!document.setPdfPassword(password)) {
      throw new Error('setPdfPassword returned false');
    }
    if (!document.saveDocument(targetPath)) {
      throw new Error('encrypted pdf save failed');
    }
  } finally {
    document.releaseDocument();
  }
}

// 组装最小合法 PDF 1.4：Catalog → Pages → 每页 (Page + Contents + Image)。
// 对象编号：1=Catalog，2=Pages，页 i 占 3+3i(Page)/4+3i(Contents)/5+3i(Image)。
export function buildPdf(pages: PdfPageImage[]): Uint8Array {
  if (pages.length === 0 || pages.length > MAX_PAGE_COUNT) {
    throw new Error(`invalid pdf page count: ${pages.length}`);
  }
  const out: PdfByteWriter = new PdfByteWriter();
  const objectOffsets: number[] = [];
  const objectCount: number = 2 + pages.length * 3;

  out.text('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  objectOffsets.push(out.length);
  out.text('1 0 obj\n<</Type/Catalog/Pages 2 0 R>>\nendobj\n');
  objectOffsets.push(out.length);
  out.text('2 0 obj\n<</Type/Pages/Kids[');
  for (let i = 0; i < pages.length; i++) {
    out.text(`${3 + i * 3} 0 R`);
    if (i + 1 < pages.length) {
      out.text(' ');
    }
  }
  out.text(`]/Count ${pages.length}>>\nendobj\n`);

  for (let i = 0; i < pages.length; i++) {
    const page: PdfPageImage = pages[i];
    if (page.jpegData.byteLength <= 0 || page.jpegData.byteLength > MAX_PAGE_JPEG_BYTES ||
      page.widthPx <= 0 || page.heightPx <= 0 ||
      page.widthMm <= 0 || page.heightMm <= 0) {
      throw new Error(`invalid pdf page ${i}: ${page.widthPx}x${page.heightPx}px ` +
        `${page.jpegData.byteLength}B`);
    }
    const wPt: string = formatPt(page.widthMm * MM_TO_PT);
    const hPt: string = formatPt(page.heightMm * MM_TO_PT);
    const content: string =
      `q ${wPt} 0 0 ${hPt} 0 0 cm /Im0 Do Q\n`;

    objectOffsets.push(out.length);
    out.text(`${3 + i * 3} 0 obj\n<</Type/Page/Parent 2 0 R/MediaBox[0 0 ${wPt} ${hPt}]` +
      `/Resources<</XObject<</Im0 ${5 + i * 3} 0 R>>>>` +
      `/Contents ${4 + i * 3} 0 R>>\nendobj\n`);

    objectOffsets.push(out.length);
    out.text(`${4 + i * 3} 0 obj\n<</Length ${asciiByteLength(content)}>>\nstream\n`);
    out.text(content);
    out.text('endstream\nendobj\n');

    objectOffsets.push(out.length);
    out.text(`${5 + i * 3} 0 obj\n<</Type/XObject/Subtype/Image` +
      `/Width ${page.widthPx}/Height ${page.heightPx}` +
      `/ColorSpace/DeviceRGB/BitsPerComponent 8` +
      `/Filter/DCTDecode/Length ${page.jpegData.byteLength}>>\nstream\n`);
    out.bytes(page.jpegData);
    out.text('\nendstream\nendobj\n');
  }

  if (out.length > MAX_TOTAL_PDF_BYTES) {
    throw new Error(`pdf export exceeds size budget: ${out.length} bytes`);
  }
  const xrefOffset: number = out.length;
  out.text(`xref\n0 ${objectCount + 1}\n`);
  out.text('0000000000 65535 f \n');
  for (const offset of objectOffsets) {
    out.text(`${pad10(offset)} 00000 n \n`);
  }
  out.text(`trailer\n<</Size ${objectCount + 1}/Root 1 0 R>>\n`);
  out.text(`startxref\n${xrefOffset}\n%%EOF\n`);
  return out.toBytes();
}

function formatPt(value: number): string {
  // 两位小数足以还原 mm 级精度（0.01pt ≈ 0.0035mm）。
  return value.toFixed(2);
}

function pad10(value: number): string {
  let s: string = value.toString(10);
  while (s.length < 10) {
    s = `0${s}`;
  }
  return s;
}

function asciiByteLength(text: string): number {
  return text.length;
}

class PdfByteWriter {
  private chunks: Uint8Array[] = [];
  public length: number = 0;

  text(text: string): void {
    const bytes: Uint8Array = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) {
      const code: number = text.charCodeAt(i);
      bytes[i] = code <= 0xff ? code : 0x3f;
    }
    this.bytes(bytes);
  }

  bytes(data: Uint8Array): void {
    this.chunks.push(data);
    this.length += data.byteLength;
  }

  toBytes(): Uint8Array {
    const out: Uint8Array = new Uint8Array(this.length);
    let offset: number = 0;
    for (const chunk of this.chunks) {
      out.set(chunk, offset);
      offset += chunk.byteLength;
    }
    return out;
  }
}

function safeFileName(title: string): string {
  const cleaned: string = title.replace(/[\\/:*?"<>|]/g, '_').trim();
  return cleaned.length > 0 ? cleaned : 'note';
}

function writeFileFully(fd: number, bytes: Uint8Array, label: string): void {
  let total: number = 0;
  while (total < bytes.byteLength) {
    const end: number = Math.min(bytes.byteLength, total + FILE_WRITE_CHUNK_SIZE);
    const chunk: Uint8Array = bytes.subarray(total, end);
    const buffer: ArrayBuffer = chunk.buffer.slice(chunk.byteOffset,
      chunk.byteOffset + chunk.byteLength) as ArrayBuffer;
    const written: number = fileIo.writeSync(fd, buffer);
    if (written <= 0 || written > chunk.byteLength) {
      throw new Error(`${label} write made invalid progress: ${total}/${bytes.byteLength} bytes`);
    }
    total += written;
  }
}

function copyFileFully(sourceFd: number, destinationFd: number, size: number, label: string): void {
  if (!Number.isSafeInteger(size) || size < 0) {
    throw new Error(`${label} has an invalid size: ${size}`);
  }
  let total: number = 0;
  while (total < size) {
    const requested: number = Math.min(FILE_READ_CHUNK_SIZE, size - total);
    const chunkBuffer: ArrayBuffer = new ArrayBuffer(requested);
    const read: number = fileIo.readSync(sourceFd, chunkBuffer);
    if (read <= 0 || read > requested) {
      throw new Error(`${label} read made invalid progress: ${total}/${size} bytes`);
    }
    const chunk: Uint8Array = new Uint8Array(chunkBuffer, 0, read);
    const buffer: ArrayBuffer = chunk.buffer.slice(chunk.byteOffset,
      chunk.byteOffset + chunk.byteLength) as ArrayBuffer;
    writeFileFully(destinationFd, new Uint8Array(buffer), label);
    total += read;
  }
}
