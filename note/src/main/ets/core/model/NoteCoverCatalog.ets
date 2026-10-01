// Phase 1405 — 原版 iw2.java 封面预设枚举等价目录。
// 原版：iw2{F=asset key, G=drawable 预览, H=名字 res, I=类目文案}，
//   资产在 covers/<F>.pdf；Harmony 无 HEIC/drawable 管线，cell 预览用
//   PDFKit 光栅化 rawfile PDF 首页（与 PaperTemplateGallery 同一路径）。
//   原版名字 res（ui_notecovers__preset_*）的值恰为类目名
//   （Simple/Stickers/Logo/Minimalist/Plain/Journal），逐 cell 渲染。
// 原版 ebn.b 预览卡 = 封面图 + 笔记标题 + 日期文本（库卡片形态预览）。
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { fileIo } from '@kit.CoreFileKit';
import { DatabaseManager } from '../../data/DatabaseManager';

const COVER_WRITE_CHUNK_SIZE: number = 65536;

// 与 BundledPaperTemplateApply.bundledTemplateWriteFully 同款分块写
// （Uint8Array.byteOffset 安全 + fsync）。
function coverWriteFully(path: string, data: Uint8Array): void {
  const file: fileIo.File = fileIo.openSync(path,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    let offset: number = 0;
    while (offset < data.length) {
      const end: number = Math.min(data.length, offset + COVER_WRITE_CHUNK_SIZE);
      const view: Uint8Array = data.subarray(offset, end);
      const chunk: ArrayBuffer = view.buffer.slice(view.byteOffset,
        view.byteOffset + view.byteLength) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, chunk);
      if (written <= 0 || written > view.byteLength) {
        throw new Error(`cover staging write is incomplete: ${offset}/${data.length}`);
      }
      offset += written;
    }
    fileIo.fsyncSync(file.fd);
  } finally {
    fileIo.closeSync(file);
  }
}

export interface NoteCoverPreset {
  // 原版 iw2.F —— covers/<key>.pdf asset 键（同时作持久化 preset 键）。
  key: string;
  // 原版 iw2.H —— 本地化预设名（值为类目文案）。
  nameRes: Resource;
  // rawfile 路径。
  rawfilePath: string;
}

// 原版 iw2.K 枚举序。
export const NOTE_COVER_PRESETS: NoteCoverPreset[] = [
  { key: 'orange', nameRes: $r('app.string.note_cover_preset_orange'),
    rawfilePath: 'covers/orange.pdf' },
  { key: 'sage', nameRes: $r('app.string.note_cover_preset_sage'),
    rawfilePath: 'covers/sage.pdf' },
  { key: 'stickers', nameRes: $r('app.string.note_cover_preset_stickers'),
    rawfilePath: 'covers/stickers.pdf' },
  { key: 'logo-pattern', nameRes: $r('app.string.note_cover_preset_logo_pattern'),
    rawfilePath: 'covers/logo-pattern.pdf' },
  { key: 'brown', nameRes: $r('app.string.note_cover_preset_brown'),
    rawfilePath: 'covers/brown.pdf' },
  { key: 'maroon', nameRes: $r('app.string.note_cover_preset_maroon'),
    rawfilePath: 'covers/maroon.pdf' },
  { key: 'blue', nameRes: $r('app.string.note_cover_preset_blue'),
    rawfilePath: 'covers/blue.pdf' },
  { key: 'yellow', nameRes: $r('app.string.note_cover_preset_yellow'),
    rawfilePath: 'covers/yellow.pdf' },
  { key: 'purple-journal', nameRes: $r('app.string.note_cover_preset_purple_journal'),
    rawfilePath: 'covers/purple-journal.pdf' },
  { key: 'blue-journal', nameRes: $r('app.string.note_cover_preset_blue_journal'),
    rawfilePath: 'covers/blue-journal.pdf' },
];

export function findNoteCoverPreset(key: string | null | undefined):
  NoteCoverPreset | null {
  if (key === null || key === undefined) {
    return null;
  }
  for (const preset of NOTE_COVER_PRESETS) {
    if (preset.key === key) {
      return preset;
    }
  }
  return null;
}

// 原版 d7b.b → lw2.b.b(bpj, "covers/<F>.pdf") 读取 + rs case6 SHA-512 摘要：
// 原版把封面 PDF 导入 CAS；Harmony preset 面直接以 rawfile 光栅渲染/持久化
// preset 键（自定义上传 ew2 面 fail-closed，见 ADR-1341）。
export async function loadNoteCoverThumb(
  context: common.UIAbilityContext, database: DatabaseManager,
  preset: NoteCoverPreset): Promise<image.PixelMap | null> {
  const pendingDirectory: string = database.getFilesDir() + '/assets/pending';
  const stagingPath: string = pendingDirectory +
    `/cover_thumb_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.pdf`;
  const document: pdfService.PdfDocument = new pdfService.PdfDocument();
  let page: pdfService.PdfPage | null = null;
  let documentReleased: boolean = false;
  try {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent(
      preset.rawfilePath);
    fileIo.mkdirSync(pendingDirectory, true);
    coverWriteFully(stagingPath, bytes);
    const parsed: pdfService.ParseResult = document.loadDocument(stagingPath);
    if (parsed !== pdfService.ParseResult.PARSE_SUCCESS) {
      return null;
    }
    if (document.getPageCount() < 1) {
      return null;
    }
    page = document.getPage(0);
    const pixelMap: image.PixelMap = page.getPagePixelMap();
    const releasedPage: pdfService.PdfPage = page;
    page = null;
    try {
      releasedPage.release();
    } catch (pageError) {
      console.warn(`note cover thumb page release failed: ${JSON.stringify(pageError)}`);
    }
    try {
      document.releaseDocument();
      documentReleased = true;
    } catch (docError) {
      console.warn(`note cover thumb document release failed: ${JSON.stringify(docError)}`);
    }
    return pixelMap;
  } catch (error) {
    console.warn(`note cover thumb load failed: ${JSON.stringify(error)}`);
    return null;
  } finally {
    if (page !== null) {
      try {
        page.release();
      } catch (_pageError) {
      }
    }
    if (!documentReleased) {
      try {
        document.releaseDocument();
      } catch (_docError) {
      }
    }
    try {
      fileIo.unlink(stagingPath);
    } catch (_unlinkError) {
    }
  }
}
