// T-028 笔记导入器：.note ZIP → 内部模型 → 本地数据库
// 支持我方格式（完整恢复）+ 外部格式（尽力解析 + 友好提示）；损坏不崩溃
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { pdfService } from '@kit.PDFKit';
import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';
import { ZipReader, ZipEntry, ZipParseResult, ZIP_MAX_ARCHIVE_BYTES } from './ZipArchive';
import {
  NOTE_RECORDINGS_ENTRY, NoteManifest, PackagedRecording, PackagedRecordingSegment, PageData,
  parseManifest, parsePackagedRecordings, parsePage, parsePageElement,
} from './NotePackageSpec';
import {
  NoteMeta, OriginalAssetMetadata, PageBackground, PageInfo, PaperSize, PaperTemplate,
  PageOrientation, PdfCropBoxSize, PdfLayoutBehavior,
} from '../core/model/NoteTypes';
import {
  clonePageBackground, originalDefaultNoteBackground, PAGE_BACKGROUND_SCHEMA_VERSION,
  POINTS_TO_MM,
} from '../core/model/PageBackgroundModel';
import { pagePixelSize } from '../core/model/PageCoordinateSpace';
import {
  originalImageDecodedDimensionsAreConsistent, originalImageOrientedDimensions,
  OriginalImagePixelDimensions, ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE,
  planOriginalImageDownscale,
} from '../core/model/OriginalImageInsertPlan';
import { imageBlockWorldBounds, originalAssetHashKey } from '../core/model/ImageBlockGeometry';
import { textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { StrokeElementData } from '../core/model/StrokeTypes';
import {
  ElementType, ImageElement, MathElement, ShapeElement, TextBlockElement,
} from '../core/model/ElementTypes';
import { PageElementKind, PageElementRef } from '../core/model/PageElementOrder';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { ORIGINAL_BLANK_NOTE_PAGE_COUNT } from './OriginalBlankNoteBootstrapPersistence';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { paperSizeToMm } from './NoteExporter';
import { AsyncMutex, MutexRelease } from './AsyncMutex';
import { importedLegacyNoteId, importedPageNeedsRemap } from './ImportIdentity';
import { originalAssetPackageEntry, storeImportedOriginalAsset } from './ImageAssetPackageStore';
import { persistCapturedOriginalRecording } from './OriginalRecordingPersistence';
import { OriginalRecordingCaptureResult } from '../core/adaptation/OriginalRecordingCaptureController';
import { originalAssetHashBitsFromSha512, sha512Digest } from './AssetDigest';
import { inferPaperSize } from './OriginalPageBackgroundOperation';
import {
  NotabilityMetadataParser, NotabilitySessionParser, NotabilityMetadata,
  NotabilitySession, NotabilityPageElements, NotabilityHandwritingIndexPage,
  DEFAULT_TARGET_PAGE_WIDTH_VP,
  summarizeNotabilityContentLoss,
} from './NotabilitySessionParser';
import { reserveNotePageElementIds } from './PageElementIdentity';
import {
  ImportedOriginalRecording, insertImportedOriginalRecordings, OriginalRecordingSegment,
} from './OriginalRecordingOperation';

const FILE_READ_CHUNK_SIZE: number = 64 * 1024;
// 原版 sw9 cropBoxes flatbuffer vector 上限（readInlineVectorBytes(5, 8, 10000)）。
const PDF_IMPORT_MAX_PAGES: number = 10000;
// 原版 m09.b = a79.N = apb.h(612f, 792f)：导入图片的 Letter 页尺寸（pt）。
const IMAGE_IMPORT_PAGE_WIDTH_PT: number = 612;
const IMAGE_IMPORT_PAGE_HEIGHT_PT: number = 792;
// 原版 bvh.a 的 0.8 页占比与 vuh.b 的 WEBP_LOSSY 质量参数。
const IMAGE_IMPORT_PAGE_FRACTION: number = 0.8;
const IMAGE_IMPORT_WEBP_LOSSY_QUALITY: number = 85;
const IMPORTED_IMAGE_SUFFIXES: string[] = ['.png', '.jpg', '.jpeg', '.webp',
  '.gif', '.heif', '.heic', '.tif', '.tiff'];
// 原版 nj3.txt 是导入类型表中的唯一纯文本类型（dv5 默认分支 → tu5）。
const IMPORTED_TEXT_SUFFIXES: string[] = ['.txt'];
// 原版 nj3 音频类型表（cv5 音频分支 → pu5）：后缀 → nj3 MIME。
const IMPORTED_AUDIO_SUFFIX_MIME: Record<string, string> = {
  '.mp3': 'audio/mpeg', '.mp4': 'audio/mp4', '.aac': 'audio/aac',
  '.wav': 'audio/wav', '.aiff': 'audio/aiff', '.m4a': 'audio/mp4',
};
// 原版 te0/kci.b 文本导入的默认 BlockCommon 边距与字号（cde 默认寄存器）。
const TEXT_IMPORT_LEFT_INSET: number = 5;
const TEXT_IMPORT_TOP_INSET: number = 3;
const TEXT_IMPORT_RIGHT_INSET: number = 5;
const TEXT_IMPORT_BOTTOM_INSET: number = 10;
const TEXT_IMPORT_FONT_SIZE: number = 17;
const TEXT_IMPORT_FONT_COLOR: number = -16777216;

export enum ImportResult {
  SUCCESS = 0,
  UNSUPPORTED_FORMAT = 1,
  CORRUPTED = 2,
  PARTIAL = 3,       // 部分恢复
  CANCELLED = 4,     // picker 取消（无文件被选中）
}

export interface ImportReport {
  result: ImportResult;
  // SUCCESS/PARTIAL returns the new noteId. A failed import returns a non-null ID only when its
  // own cleanup could not remove the partially created note, allowing a batch owner to retry it.
  noteId: string | null;
  title: string | null;
  pageCount: number;
  missingAssets: string[];  // 未导入的内容/条目，供 UI 逐项呈现
  warnings: string[];       // 不造成内容缺失的诊断信息
  message: string;          // 用户可读的结果描述
}

interface PackagedOriginalAsset {
  metadata: OriginalAssetMetadata;
  data: Uint8Array;
}

export class NoteImporter {
  private static importMutex: AsyncMutex = new AsyncMutex();
  private db: DatabaseManager;
  private persistence: StrokePersistence;

  constructor(db: DatabaseManager, persistence: StrokePersistence) {
    this.db = db;
    this.persistence = persistence;
  }

  // 从 Uint8Array 导入（WebDAV 下载后调用）
  async importFromData(data: Uint8Array): Promise<ImportReport> {
    if (data === null || data.length === 0) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '文件为空或无法读取' };
    }
    // 1. 解析 ZIP（损坏 → CORRUPTED，不抛异常）
    const archive: ZipParseResult | null = await ZipReader.parse(data);
    if (archive === null || (archive.entries.length === 0 && archive.failed.length === 0)) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '文件不是有效的 .note 包或已损坏' };
    }
    const entries: ZipEntry[] = archive.entries;
    if (entries.length === 0 && archive.encrypted.length > 0) {
      return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: `文件受密码保护，当前版本无法导入：${archive.encrypted.join('、')}` };
    }
    if (archive.failed.indexOf('manifest.json') >= 0) {
      const protectedManifest: boolean = archive.encrypted.indexOf('manifest.json') >= 0;
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: protectedManifest ? 'manifest.json 受密码保护，当前版本无法导入'
          : `关键条目损坏，无法导入：${archive.failed.join('、')}` };
    }
    // 2. 查找 manifest.json → 我方格式
    const manifestEntry: ZipEntry | null = ZipReader.findEntry(entries, 'manifest.json');
    if (manifestEntry !== null) {
      const manifest: NoteManifest | null = parseManifest(bytesToString(manifestEntry.data));
      if (manifest === null) {
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: 'manifest.json 无法解析或格式版本不受支持' };
      }
      return await this.importOurFormat(entries, manifest, archive.failed, archive.encrypted);
    }
    if (hasFailedSuffix(archive.failed, 'Session.plist')) {
      const protectedSession: boolean = hasFailedSuffix(archive.encrypted, 'Session.plist');
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: protectedSession ? 'Notability 会话数据受密码保护，当前版本无法导入'
          : `Notability 会话数据损坏，无法导入：${archive.failed.join('、')}` };
    }
    // 3. 无 manifest → 尝试外部格式
    return await this.importExternalFormat(entries, archive.failed, archive.encrypted);
  }

  // 从文件导入（系统 picker）。原版 i58 选择器为 */*、由 jv5/dv5 按 MIME
  // 与内容嗅探分发；Harmony DocumentViewPicker 只能按后缀过滤，收缩到可
  // 物化的 .note/.pdf/图片/.txt，进入后用 %PDF- magic 对齐原版的类型嗅探。
  async importFromFile(context: common.UIAbilityContext): Promise<ImportReport> {
    let file: fileIo.File | null = null;
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const selectOptions = new picker.DocumentSelectOptions();
      selectOptions.fileSuffixFilters = ['.note', '.pdf', '.png', '.jpg', '.jpeg',
        '.webp', '.gif', '.heif', '.heic', '.tif', '.tiff', '.txt',
        '.mp3', '.mp4', '.aac', '.wav', '.aiff', '.m4a'];
      const uris: string[] = await documentPicker.select(selectOptions);
      if (uris.length === 0) {
        return { result: ImportResult.CANCELLED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: '未选择文件' };
      }
      // 读取文件内容
      const uri: string = uris[0];
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(uri);
      const size: number = stat.size;
      if (!Number.isSafeInteger(size) || size > ZIP_MAX_ARCHIVE_BYTES) {
        fileIo.closeSync(file);
        file = null;
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: `文件超过导入大小上限 ${ZIP_MAX_ARCHIVE_BYTES} bytes` };
      }
      if (size <= 0) {
        fileIo.closeSync(file);
        file = null;
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: '所选文件为空' };
      }
      const bytes: Uint8Array = readFileFully(file.fd, size);
      fileIo.closeSync(file);
      file = null;
      const fileName: string = pickedFileName(uri);
      if (startsWithPdfMagic(bytes) || fileName.toLowerCase().endsWith('.pdf')) {
        return await this.importPdfFromBytes(bytes, fileName);
      }
      if (isImportedImageFileName(fileName)) {
        return await this.importImageFromBytes(bytes, fileName);
      }
      if (isImportedTextFileName(fileName)) {
        return await this.importTextFromBytes(bytes, fileName);
      }
      if (isImportedAudioFileName(fileName)) {
        return await this.importAudioFromBytes(bytes, fileName);
      }
      return await this.importFromData(bytes);
    } catch (e) {
      console.error(`importFromFile failed: ${JSON.stringify(e)}`);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '读取文件失败' };
    } finally {
      if (file !== null) {
        try { fileIo.closeSync(file); } catch (_closeError) { }
      }
    }
  }

  // 原版 jv5 PDF 分支：o88(nj3.pdf) 描述符 → fca.f PDFTron 解析 → su5(doc+页列表) → nv5。
  // Harmony：PDFKit 解析（loadDocument 仅接受沙箱路径，先落到 assets/pending 暂存），
  // 全页尺寸校验通过后一次性写库：createNoteWithMeta（无默认空白页）+ 整文档共享的
  // sw9 寄存器（pagesConsumed=总页数、pageOffset=0、cropBoxes=全页表），每页 pageInAsset=i。
  private async importPdfFromBytes(data: Uint8Array, fileName: string): Promise<ImportReport> {
    if (!startsWithPdfMagic(data)) {
      return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '所选文件不是有效的 PDF 文档' };
    }
    const title: string = pdfImportTitle(fileName);
    const digestBytes: Uint8Array = await sha512Digest(data);
    const metadata: OriginalAssetMetadata = {
      assetHashBits: originalAssetHashBitsFromSha512(digestBytes),
      fileName: fileName,
      mimeType: 'application/pdf',
      fileSize: data.length,
    };
    const pendingDirectory: string = this.db.getFilesDir() + '/assets/pending';
    const stagingPath: string = pendingDirectory +
      `/pdf_import_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.tmp`;
    let pageSizes: number[][];
    try {
      fileIo.mkdirSync(pendingDirectory, true);
      writeFileFully(stagingPath, data);
      pageSizes = parseImportedPdfPageSizes(stagingPath);
    } catch (e) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: `PDF 文档解析失败：${JSON.stringify(e)}` };
    } finally {
      if (fileIo.accessSync(stagingPath)) {
        try { fileIo.unlinkSync(stagingPath); } catch (_unlinkError) { }
      }
    }
    let createdNoteId: string | null = null;
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const now: number = Date.now();
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        generateId(), title, now, now, null, false);
      createdNoteId = note.id;
      await storeImportedOriginalAsset(this.db, metadata, data, note.id);
      const cropBoxes: PdfCropBoxSize[] = [];
      for (const size of pageSizes) {
        cropBoxes.push({ widthPt: size[0], heightPt: size[1] });
      }
      for (let index = 0; index < pageSizes.length; index++) {
        const widthPt: number = pageSizes[index][0];
        const heightPt: number = pageSizes[index][1];
        const widthMm: number = widthPt * POINTS_TO_MM;
        const heightMm: number = heightPt * POINTS_TO_MM;
        const background: PageBackground = {
          schemaVersion: PAGE_BACKGROUND_SCHEMA_VERSION,
          paper: null,
          pdf: {
            metadata: metadata,
            layoutBehavior: PdfLayoutBehavior.FIT_AND_CROP_BOX,
            totalPageCount: pageSizes.length,
            pagesConsumed: pageSizes.length,
            pageOffset: 0,
            cropBoxes: cropBoxes,
            pageInAsset: index,
          },
          rotationRadians: 0,
          sourceWidthPt: widthPt,
          sourceHeightPt: heightPt,
          margins: null,
        };
        const pageInfo: PageInfo = {
          pageId: generateId(),
          pageIndex: index,
          size: inferPaperSize(widthMm, heightMm),
          template: PaperTemplate.PLAIN,
          orientation: widthMm > heightMm ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT,
          widthMm: widthMm,
          heightMm: heightMm,
          background: background,
          originalPageInAsset: index,
          bookmarked: false,
        };
        await pageRepo.addImportedPage(note.id, pageInfo);
      }
      return { result: ImportResult.SUCCESS, noteId: note.id, title: note.title,
        pageCount: pageSizes.length, missingAssets: [], warnings: [],
        message: `已导入 PDF「${note.title}」（${pageSizes.length} 页）` };
    } catch (e) {
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0, missingAssets: [], warnings: [],
        message: `PDF 导入失败：${JSON.stringify(e)}` };
    } finally {
      release();
    }
  }

  // 原版 cv5 图片分支 + dhj.S：vuh.b 解码（≤3000 保留原字节与解码 mime；
  // >3000 幂二次采样 + 等比缩放 → WEBP_LOSSY q85 重写），bvh.a 按
  // 0.8·Letter(612×792pt) 适配，ip5 居中偏移 + 等比 scale=fitW/srcW，
  // kp5/baj.a 在新建 Letter 页上落一个 cz0.IMAGE/ty0.SQUARE 元素
  // （PIXEL_ALIGN，blockWidth/Height=本征尺寸，transform=[s,0,x,0,s,y]）。
  private async importImageFromBytes(data: Uint8Array, fileName: string): Promise<ImportReport> {
    let prepared: ImportedImagePreparation;
    try {
      prepared = await prepareImportedImageBytes(data);
    } catch (e) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: `图片解码失败：${JSON.stringify(e)}` };
    }
    const title: string = importedFileStemTitle(fileName);
    const digestBytes: Uint8Array = await sha512Digest(prepared.bytes);
    const metadata: OriginalAssetMetadata = {
      assetHashBits: originalAssetHashBitsFromSha512(digestBytes),
      fileName: fileName,
      mimeType: prepared.mimeType,
      fileSize: prepared.bytes.length,
    };
    const imageElement: ImageElement = buildImportedImageElement(prepared, metadata);
    let createdNoteId: string | null = null;
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const now: number = Date.now();
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        generateId(), title, now, now, null, false);
      createdNoteId = note.id;
      await storeImportedOriginalAsset(this.db, metadata, prepared.bytes, note.id);
      const pageInfo: PageInfo = {
        pageId: generateId(),
        pageIndex: 0,
        size: PaperSize.LETTER,
        template: PaperTemplate.PLAIN,
        orientation: PageOrientation.PORTRAIT,
        widthMm: IMAGE_IMPORT_PAGE_WIDTH_PT * POINTS_TO_MM,
        heightMm: IMAGE_IMPORT_PAGE_HEIGHT_PT * POINTS_TO_MM,
        background: originalDefaultNoteBackground(),
        bookmarked: false,
      };
      const added: PageInfo = await pageRepo.addImportedPage(note.id, pageInfo);
      await this.persistence.saveElements(note.id, added.pageId, [], [],
        [{ kind: PageElementKind.IMAGE, elementId: imageElement.id, zIndex: 0 }],
        [], [imageElement], []);
      return { result: ImportResult.SUCCESS, noteId: note.id, title: note.title,
        pageCount: 1, missingAssets: [], warnings: [],
        message: `已导入图片「${note.title}」` };
    } catch (e) {
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0, missingAssets: [], warnings: [],
        message: `图片导入失败：${JSON.stringify(e)}` };
    } finally {
      release();
    }
  }

  // 原版 dv5 默认分支 + dhj.p0：tf4.x0(file, UTF-8) 读纯文本为 tu5，
  // 空文本记日志后跳过（dca.c 无 op）；非空 te0 = haj.a 建 Letter 页 +
  // kci.b(null, text, null) 生成 INSERT_STRING 实体（haa.INSERT_STRING，
  // nti.g(qo5,0) 落在 richtext 寄存器位 0）。Harmony 物化为
  // Letter 页上的默认样式 TextBlockElement。
  private async importTextFromBytes(data: Uint8Array, fileName: string): Promise<ImportReport> {
    const text: string = bytesToString(data);
    if (text.length === 0) {
      // 原版：Empty text file, skipping import —— 不建笔记。
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [], message: '空文本文件，未导入' };
    }
    const title: string = importedFileStemTitle(fileName);
    const textElement: TextBlockElement = buildImportedTextElement(text);
    let createdNoteId: string | null = null;
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const now: number = Date.now();
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        generateId(), title, now, now, null, false);
      createdNoteId = note.id;
      const pageInfo: PageInfo = {
        pageId: generateId(),
        pageIndex: 0,
        size: PaperSize.LETTER,
        template: PaperTemplate.PLAIN,
        orientation: PageOrientation.PORTRAIT,
        widthMm: IMAGE_IMPORT_PAGE_WIDTH_PT * POINTS_TO_MM,
        heightMm: IMAGE_IMPORT_PAGE_HEIGHT_PT * POINTS_TO_MM,
        background: originalDefaultNoteBackground(),
        bookmarked: false,
      };
      const added: PageInfo = await pageRepo.addImportedPage(note.id, pageInfo);
      await this.persistence.saveElements(note.id, added.pageId, [], [textElement],
        [{ kind: PageElementKind.TEXT, elementId: textElement.id, zIndex: 0 }],
        [], [], []);
      return { result: ImportResult.SUCCESS, noteId: note.id, title: note.title,
        pageCount: 1, missingAssets: [], warnings: [],
        message: `已导入文本「${note.title}」` };
    } catch (e) {
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0, missingAssets: [], warnings: [],
        message: `文本导入失败：${JSON.stringify(e)}` };
    } finally {
      release();
    }
  }

  // 原版 cv5 音频分支 + izi.M：jv5.f 复制临时文件 → MediaMetadataRetriever
  // extractMetadata(9) 取时长（失败兜底 j=0）→ pu5(file, duration, mime)；
  // izi.M 在 IO 线程经 re0 建录音资产 akb，再 iaj.a(null, stem, akb, 0,
  // duration, xgb) 造 yn2 CREATE_RECORDING 实体（haa.CREATE_RECORDING，
  // te0 variant 0 单 op、不建页；o88 页数=0）。
  // Harmony：nj3 后缀→MIME 映射（回退 'audio/*'）→ assets/pending 暂存
  // → AVMetadataExtractor 取时长（失败 0）→ createNoteWithMeta +
  // persistCapturedOriginalRecording（同一资产管线 + CREATE_RECORDING op）。
  // 原版 startTime=0L；Harmony 本地录音写者要求 startTime>0，记为导入时刻。
  private async importAudioFromBytes(data: Uint8Array, fileName: string): Promise<ImportReport> {
    const mimeType: string = audioMimeForFileName(fileName);
    const title: string = importedFileStemTitle(fileName);
    const pendingDirectory: string = this.db.getFilesDir() + '/assets/pending';
    const stagingPath: string = pendingDirectory +
      `/audio_import_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.tmp`;
    try {
      fileIo.mkdirSync(pendingDirectory, true);
      writeFileFully(stagingPath, data);
    } catch (e) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: `音频暂存失败：${JSON.stringify(e)}` };
    }
    const durationMs: number = await extractImportedAudioDuration(stagingPath);
    let createdNoteId: string | null = null;
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const now: number = Date.now();
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        generateId(), title, now, now, null, true);
      createdNoteId = note.id;
      const capture: OriginalRecordingCaptureResult = {
        temporaryPath: stagingPath,
        mimeType: mimeType,
        fileSize: data.length,
        mediaDurationMs: durationMs,
        startTime: now,
        endTime: now + durationMs,
        durationMs: durationMs,
      };
      // persist 的 finally 会删除 stagingPath（无论成败）。
      await persistCapturedOriginalRecording(this.db, note.id, capture);
      return { result: ImportResult.SUCCESS, noteId: note.id, title: note.title,
        pageCount: 0, missingAssets: [], warnings: [],
        message: `已导入音频「${note.title}」` };
    } catch (e) {
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0, missingAssets: [], warnings: [],
        message: `音频导入失败：${JSON.stringify(e)}` };
    } finally {
      release();
      if (fileIo.accessSync(stagingPath)) {
        try { fileIo.unlinkSync(stagingPath); } catch (_unlinkError) { }
      }
    }
  }

  // 我方格式导入：先全量解析验证，再写库（事务性：验证失败不写库）
  private async importOurFormat(entries: ZipEntry[], manifest: NoteManifest,
    failedEntries: string[], encryptedEntries: string[]): Promise<ImportReport> {
    // === 阶段 1：全量解析验证 ===
    const parsedPages: PageData[] = [];
    let failedPages: number = 0;
    let failedElements: number = 0;
    const pageIds: Set<string> = new Set<string>();
    const noteElementIds: Set<string> = new Set<string>();
    for (let i = 0; i < manifest.pageCount; i++) {
      const entry: ZipEntry | null = ZipReader.findEntry(entries, `pages/page_${i}.json`);
      if (entry === null) {
        failedPages++;
        continue;  // 缺页不致命（PARTIAL 语义）
      }
      const page: PageData | null = parsePage(bytesToString(entry.data));
      if (page === null) {
        failedPages++;
        continue;
      }
      if (page.pageIndex !== i || pageIds.has(page.pageId)) {
        failedPages++;
        continue;
      }
      pageIds.add(page.pageId);
      // 解析元素（跳过损坏条目，不致命）
      const elements: PersistedElement[] = [];
      const elementIds: Set<string> = new Set<string>();
      const pageElementIds: string[] = [];
      for (const el of page.elements) {
        const parsedElement: object | null = parsePageElement(el);
        if (parsedElement !== null) {
          const typed = parsedElement as PersistedElement;
          if (elementIds.has(typed.data.id)) {
            failedElements++;
          } else {
            elementIds.add(typed.data.id);
            pageElementIds.push(typed.data.id);
            elements.push(typed);
          }
        } else {
          failedElements++;
        }
      }
      if (!reserveNotePageElementIds(noteElementIds, pageElementIds)) {
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: ['同一元素 ID 被多个页面复用'], warnings: [],
          message: '页面元素身份跨页冲突，导入未完成' };
      }
      parsedPages.push({ pageId: page.pageId, pageIndex: page.pageIndex,
        paperSize: page.paperSize, paperTemplate: page.paperTemplate,
        orientation: page.orientation, widthMm: page.widthMm, heightMm: page.heightMm,
        background: clonePageBackground(page.background),
        originalPageInAsset: packagePageInAsset(page), bookmarked: page.bookmarked,
        elements: elements });
    }
    if (parsedPages.length === 0 && manifest.pageCount > 0) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '未找到可解析的页面数据' };
    }
    const packagedAssets: Map<string, PackagedOriginalAsset> = new Map<string, PackagedOriginalAsset>();
    const declaredAssets: Map<string, OriginalAssetMetadata> = new Map<string, OriginalAssetMetadata>();
    const missingAssetPaths: Set<string> = new Set<string>();
    for (const page of parsedPages) {
      for (const sourceElement of page.elements) {
        const persisted: PersistedElement = sourceElement as PersistedElement;
        if (persisted.kind !== 'image') {
          continue;
        }
        const element: ImageElement = persisted.data as ImageElement;
        const metadata: OriginalAssetMetadata = {
          assetHashBits: element.assetHashBits,
          fileName: element.fileName,
          mimeType: element.mimeType,
          fileSize: element.fileSize,
        };
        const packagePath: string = originalAssetPackageEntry(metadata);
        const declared: OriginalAssetMetadata | undefined = declaredAssets.get(packagePath);
        if (declared !== undefined && !sameAssetMetadata(declared, metadata)) {
          return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
            missingAssets: [`资产 ${packagePath} 的元数据互相冲突`], warnings: [],
            message: '资产元数据冲突，导入未完成' };
        }
        if (declared === undefined) {
          declaredAssets.set(packagePath, metadata);
        }
        if (packagedAssets.has(packagePath) || missingAssetPaths.has(packagePath)) {
          continue;
        }
        const assetEntry: ZipEntry | null = ZipReader.findEntry(entries, packagePath);
        if (assetEntry === null || assetEntry.data.length !== metadata.fileSize) {
          missingAssetPaths.add(packagePath);
          continue;
        }
        packagedAssets.set(packagePath, { metadata: metadata, data: assetEntry.data });
      }
      if (page.background !== undefined && page.background !== null &&
        page.background.pdf !== undefined && page.background.pdf !== null) {
        const metadata: OriginalAssetMetadata = page.background.pdf.metadata;
        const packagePath: string = originalAssetPackageEntry(metadata);
        const declared: OriginalAssetMetadata | undefined = declaredAssets.get(packagePath);
        if (declared !== undefined && !sameAssetMetadata(declared, metadata)) {
          return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
            missingAssets: [`PDF 资产 ${packagePath} 的元数据互相冲突`], warnings: [],
            message: 'PDF 资产元数据冲突，导入未完成' };
        }
        declaredAssets.set(packagePath, metadata);
        if (!packagedAssets.has(packagePath) && !missingAssetPaths.has(packagePath)) {
          const assetEntry: ZipEntry | null = ZipReader.findEntry(entries, packagePath);
          if (assetEntry === null || assetEntry.data.length !== metadata.fileSize) {
            missingAssetPaths.add(packagePath);
          } else {
            packagedAssets.set(packagePath, { metadata: metadata, data: assetEntry.data });
          }
        }
      }
    }
    // recordings.json（§2.4）：原版 .note 经同步 ops 携带 CREATE_RECORDING；
    // Harmony 包以清单落盘，音频资产与页面资产共用 assets/ 内容寻址集合。
    const recordingsEntry: ZipEntry | null = ZipReader.findEntry(entries, NOTE_RECORDINGS_ENTRY);
    const packagedRecordings: PackagedRecording[] = [];
    if (recordingsEntry !== null) {
      const parsedRecordings: PackagedRecording[] | null =
        parsePackagedRecordings(bytesToString(recordingsEntry.data));
      if (parsedRecordings === null) {
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: ['录音清单 recordings.json 损坏或不受支持'], warnings: [],
          message: '录音清单损坏，导入未完成' };
      }
      for (const recording of parsedRecordings) {
        const recordingMetadata: OriginalAssetMetadata = {
          assetHashBits: recording.assetHashBits,
          fileName: recording.assetFileName,
          mimeType: recording.assetMimeType,
          fileSize: recording.assetFileSize,
        };
        const recordingPath: string = originalAssetPackageEntry(recordingMetadata);
        const declaredRecording: OriginalAssetMetadata | undefined =
          declaredAssets.get(recordingPath);
        if (declaredRecording !== undefined &&
          !sameAssetMetadata(declaredRecording, recordingMetadata)) {
          return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
            missingAssets: [`录音资产 ${recordingPath} 的元数据互相冲突`], warnings: [],
            message: '资产元数据冲突，导入未完成' };
        }
        if (declaredRecording === undefined) {
          declaredAssets.set(recordingPath, recordingMetadata);
        }
        if (!packagedAssets.has(recordingPath) && !missingAssetPaths.has(recordingPath)) {
          const recordingAssetEntry: ZipEntry | null = ZipReader.findEntry(entries, recordingPath);
          if (recordingAssetEntry === null ||
            recordingAssetEntry.data.length !== recordingMetadata.fileSize) {
            missingAssetPaths.add(recordingPath);
          } else {
            packagedAssets.set(recordingPath,
              { metadata: recordingMetadata, data: recordingAssetEntry.data });
          }
        }
        packagedRecordings.push(recording);
      }
    }
    const missingPackageAssets: number = missingAssetPaths.size;

    // === 阶段 2：写库（创建新笔记，不覆盖已有）===
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    let createdNoteId: string | null = null;
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const title: string = manifest.title !== null && manifest.title.length > 0 ? manifest.title : '导入笔记';
      const preferredId: string = manifest.noteId.length > 0 ? manifest.noteId : generateId();
      const importedAsCopy: boolean = await this.noteIdExists(preferredId);
      const noteId: string = await this.allocateImportedNoteId(preferredId, importedAsCopy);
      const assignedPageIds: Map<string, string> = await this.mapImportedPageIds(parsedPages, importedAsCopy);
      const now: number = Date.now();
      const createdAt: number = validTimestamp(manifest.createdAt, now);
      const updatedAt: number = validTimestamp(manifest.updatedAt, now);
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        noteId, title, createdAt, updatedAt, null, packagedRecordings.length > 0,
        importedLegacyNoteId(preferredId, noteId));
      createdNoteId = note.id;

      if (packagedRecordings.length > 0) {
        const importedRecordings: ImportedOriginalRecording[] = [];
        for (const recording of packagedRecordings) {
          importedRecordings.push({
            timestamp: recording.timestamp,
            siteId: recording.siteId,
            name: recording.name,
            startTime: recording.startTime,
            endTime: recording.endTime,
            segments: recording.segments.map(
              (segment: PackagedRecordingSegment): OriginalRecordingSegment =>
                ({ startTime: segment.startTime, endTime: segment.endTime })),
            zIndex: recording.zIndex,
            metadata: {
              assetHashBits: recording.assetHashBits,
              fileName: recording.assetFileName,
              mimeType: recording.assetMimeType,
              fileSize: recording.assetFileSize,
            },
          });
        }
        await insertImportedOriginalRecordings(this.db, note.id, importedRecordings);
      }

      for (const packaged of packagedAssets.values()) {
        await storeImportedOriginalAsset(this.db, packaged.metadata, packaged.data, note.id);
      }

      let writtenPages: number = 0;
      let countStrokes: number = 0;
      let countTexts: number = 0;
      for (const page of parsedPages) {
        const mm: number[] = paperSizeToMm(page.paperSize as PaperSize);
        const landscape: boolean = page.orientation === PageOrientation.LANDSCAPE;
        const pageInfo: PageInfo = {
          pageId: assignedPageIds.get(page.pageId) as string,
          pageIndex: page.pageIndex,
          size: page.paperSize as PaperSize,
          template: page.paperTemplate as PaperTemplate,
          orientation: page.orientation as PageOrientation,
          widthMm: page.widthMm === undefined ? (landscape ? mm[1] : mm[0]) : page.widthMm,
          heightMm: page.heightMm === undefined ? (landscape ? mm[0] : mm[1]) : page.heightMm,
          background: clonePageBackground(page.background),
          originalPageInAsset: page.originalPageInAsset,
          bookmarked: page.bookmarked,
        };
        await pageRepo.addImportedPage(note.id, pageInfo);
        const pageStrokes: StrokeElementData[] = [];
        const pageTexts: TextBlockElement[] = [];
        const pageShapes: ShapeElement[] = [];
        const pageImages: ImageElement[] = [];
        const pageMathBlocks: MathElement[] = [];
        const pageElementOrder: PageElementRef[] = [];
        for (const el of page.elements) {
          const typed = el as PersistedElement;
          if (typed.kind === 'stroke') {
            const stroke: StrokeElementData = typed.data as StrokeElementData;
            pageStrokes.push(stroke);
            pageElementOrder.push({ kind: PageElementKind.STROKE,
              elementId: stroke.id, zIndex: pageElementOrder.length });
          } else if (typed.kind === 'text') {
            const text: TextBlockElement = typed.data as TextBlockElement;
            pageTexts.push(text);
            pageElementOrder.push({ kind: PageElementKind.TEXT,
              elementId: text.id, zIndex: pageElementOrder.length });
          } else if (typed.kind === 'shape') {
            const shape: ShapeElement = typed.data as ShapeElement;
            pageShapes.push(shape);
            pageElementOrder.push({ kind: PageElementKind.SHAPE,
              elementId: shape.id, zIndex: pageElementOrder.length });
          } else if (typed.kind === 'image') {
            const image: ImageElement = typed.data as ImageElement;
            pageImages.push(image);
            pageElementOrder.push({ kind: PageElementKind.IMAGE,
              elementId: image.id, zIndex: pageElementOrder.length });
          } else if (typed.kind === 'math') {
            const math: MathElement = typed.data as MathElement;
            pageMathBlocks.push(math);
            pageElementOrder.push({ kind: PageElementKind.MATH,
              elementId: math.id, zIndex: pageElementOrder.length });
          }
        }
        await this.persistence.saveElements(
          note.id, pageInfo.pageId, pageStrokes, pageTexts, pageElementOrder, pageShapes, pageImages,
          pageMathBlocks);
        countStrokes += pageStrokes.length;
        countTexts += pageTexts.length;
        writtenPages++;
      }
      const partial: boolean = writtenPages < manifest.pageCount || failedPages > 0 ||
        failedElements > 0 || failedEntries.length > 0 || missingPackageAssets > 0;
      const failureSummary: string = failedEntries.length > 0
        ? `；跳过损坏条目：${failedEntries.join('、')}` : '';
      const encryptedSummary: string = encryptedEntries.length > 0
        ? `；其中受密码保护：${encryptedEntries.join('、')}` : '';
      const collisionSummary: string = importedAsCopy
        ? '；原笔记 ID 已存在，已作为副本导入，未覆盖现有数据' : '';
      const missingAssets: string[] = [];
      if (failedPages > 0) {
        missingAssets.push(`${failedPages} 个页面损坏或缺失`);
      }
      if (failedElements > 0) {
        missingAssets.push(`${failedElements} 个页面元素损坏或不受支持`);
      }
      if (missingPackageAssets > 0) {
        missingAssets.push(`${missingPackageAssets} 个图片/PDF/录音资产缺失或长度不符`);
      }
      for (const failed of failedEntries) {
        missingAssets.push(`损坏或不支持的包条目：${failed}`);
      }
      const warnings: string[] = [];
      if (importedAsCopy) {
        warnings.push('原笔记 ID 已存在，已作为副本导入，未覆盖现有数据');
      }
      console.info(`importOurFormat done: note=${note.id} pages=${writtenPages}/${manifest.pageCount} strokes=${countStrokes} texts=${countTexts}`);
      let message: string = partial
        ? `导入完成（部分：${writtenPages}/${manifest.pageCount} 页）${failureSummary}${encryptedSummary}${collisionSummary}`
        : `导入成功：${note.title}（${writtenPages} 页）${collisionSummary}`;
      if (missingAssets.length > 0) {
        message += `。未导入内容：${missingAssets.join('；')}`;
      }
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id,
        title: note.title,
        pageCount: writtenPages,
        missingAssets: missingAssets,
        warnings: warnings,
        message: message,
      };
    } catch (e) {
      console.error(`importOurFormat write failed: ${JSON.stringify(e)}`);
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: cleaned ? '写入数据库失败，导入未完成' :
          '写入数据库失败，且自动清理未完成' };
    } finally {
      release();
    }
  }

  // 外部格式（尽力解析）：扫描条目，尝试识别可解析内容
  private async importExternalFormat(entries: ZipEntry[], failedEntries: string[],
    encryptedEntries: string[]): Promise<ImportReport> {
    // 收集内部文件列表（供调试/提示）
    let fileList: string = '';
    for (const e of entries) {
      fileList += fileList.length === 0 ? e.name : ', ' + e.name;
    }
    // T-032 原版 Notability：条目都在以笔记名命名的顶层目录下（如 OP-AMP/Session.plist），
    // 所以只能按后缀匹配（ZipReader.findEntry 是全名精确匹配）
    const metaEntry: ZipEntry | null = findEntryBySuffix(entries, 'metadata.plist');
    const sessionEntry: ZipEntry | null = findEntryBySuffix(entries, 'Session.plist');
    if (sessionEntry !== null) {
      return await this.importNotability(
        entries, metaEntry, sessionEntry, fileList, failedEntries, encryptedEntries);
    }
    // 尝试常见 JSON 元数据（title 等）
    let title: string | null = null;
    for (const candidate of ['metadata.json', 'info.json', 'note.json']) {
      const entry: ZipEntry | null = ZipReader.findEntry(entries, candidate);
      if (entry === null) {
        continue;
      }
      try {
        const parsed = JSON.parse(bytesToString(entry.data)) as Record<string, Object>;
        if (parsed !== null && typeof parsed === 'object') {
          const t = parsed['title'];
          if (typeof t === 'string' && t.length > 0) {
            title = t;
          }
        }
      } catch (e) {
        // 解析失败继续
      }
    }
    if (title !== null) {
      // 有标题但无标准结构 → PARTIAL（仅创建空白笔记）
      const release: MutexRelease = await NoteImporter.importMutex.lock();
      try {
        const noteRepo = new NoteRepositoryImpl(this.db);
        const note: NoteMeta = await noteRepo.createNote(title, null);
        return { result: ImportResult.PARTIAL, noteId: note.id, title: note.title,
          pageCount: ORIGINAL_BLANK_NOTE_PAGE_COUNT,
          missingAssets: ['笔记内容结构无法识别，仅恢复了标题'], warnings: [],
          message: `已导入外部包的基本信息（${note.title}），内容结构无法识别。内部文件：${fileList}` };
      } catch (e) {
        return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: `外部包结构无法识别。内部文件：${fileList}` };
      } finally {
        release();
      }
    }
    // 完全无法识别
    return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
      missingAssets: [], warnings: [],
      message: `不支持的 .note 格式（可能为原版 Notability 加密/FB 格式）。内部文件：${fileList}` };
  }

  // T-032 原版 Notability .note 导入
  private async importNotability(entries: ZipEntry[], metaEntry: ZipEntry | null,
    sessionEntry: ZipEntry, fileList: string, failedEntries: string[],
    encryptedEntries: string[]): Promise<ImportReport> {
    // 1. metadata.plist：标题/UUID/日期。失败不致命，Session 里还有一份 name
    const meta: NotabilityMetadata = metaEntry === null ? {
      ok: false, error: 'metadata.plist 缺失或损坏', noteName: '', uuid: '',
      createdMillis: 0, modifiedMillis: 0, hasRecording: false, subject: '',
      fieldsFound: 0, fieldsRecovered: 0, warnings: [],
    } : NotabilityMetadataParser.parse(metaEntry.data);

    // 2. 两个辅助信号：缩略图宽高比推导页高；HandwritingIndex 交叉校验页数
    let thumbAspect: number = 0;
    const thumb: ZipEntry | null = findEntryBySuffix(entries, 'thumb12x.png');
    if (thumb !== null) {
      thumbAspect = NotabilitySessionParser.pngAspect(thumb.data);
    }
    let pageCountHint: number = 0;
    const indexWarnings: string[] = [];
    let handwritingIndexPages: NotabilityHandwritingIndexPage[] = [];
    const index: ZipEntry | null = findEntryBySuffix(entries, 'HandwritingIndex/index.plist');
    if (index !== null) {
      handwritingIndexPages =
        NotabilitySessionParser.handwritingTextFromIndex(index.data, indexWarnings);
      pageCountHint = handwritingIndexPages.length;
    }

    // 3. Session.plist：笔画 + 形状
    const session: NotabilitySession =
      NotabilitySessionParser.parse(sessionEntry.data, thumbAspect, pageCountHint);
    if (!session.ok) {
      return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null,
        title: meta.noteName.length > 0 ? meta.noteName : null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: `Notability 笔记解析失败：${session.error}。内部文件：${fileList}` };
    }
    for (let i: number = 0; i < indexWarnings.length; i++) {
      appendUnique(session.warnings, indexWarnings[i]);
    }
    const recordingEntryCount: number = countRecordingEntries(entries);
    session.inventory.audio.found = Math.max(meta.hasRecording ? 1 : 0, recordingEntryCount);

    // 4. 转内部模型
    const pages: NotabilityPageElements[] =
      NotabilitySessionParser.toPageElements(session, DEFAULT_TARGET_PAGE_WIDTH_VP);
    const noteElementIds: Set<string> = new Set<string>();
    for (const page of pages) {
      const pageElementIds: string[] = [];
      for (const ref of page.elementOrder) {
        pageElementIds.push(ref.elementId);
      }
      if (!reserveNotePageElementIds(noteElementIds, pageElementIds)) {
        return { result: ImportResult.CORRUPTED, noteId: null,
          title: meta.noteName.length > 0 ? meta.noteName : null, pageCount: 0,
          missingAssets: ['同一元素 ID 被多个页面复用'], warnings: session.warnings.slice(),
          message: 'Notability 页面元素身份跨页冲突，导入未完成' };
      }
    }

    // 5. 写库
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    let createdNoteId: string | null = null;
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      let title: string = meta.noteName;
      if (title.length === 0) {
        title = session.noteName;
      }
      if (title.length === 0) {
        title = '导入笔记';
      }
      const preferredId: string = meta.uuid.length > 0 ? meta.uuid : generateId();
      const importedAsCopy: boolean = await this.noteIdExists(preferredId);
      const noteId: string = await this.allocateImportedNoteId(preferredId, importedAsCopy);
      const now: number = Date.now();
      const createdAt: number = validTimestamp(meta.createdMillis, now);
      const updatedAt: number = validTimestamp(meta.modifiedMillis, now);
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        noteId, title, createdAt, updatedAt, null, meta.hasRecording,
        importedLegacyNoteId(preferredId, noteId));
      createdNoteId = note.id;

      const size: PaperSize = notabilityPaperSize(session.paper.paperSize);
      const template: PaperTemplate = notabilityPaperTemplate(session.paper.lineStyle);
      const orientation: PageOrientation =
        session.paper.paperOrientation.toLowerCase() === 'landscape'
          ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT;
      const mm: number[] = paperSizeToMm(size);
      const sourcePageIds: Set<string> = new Set<string>();
      const assignedPageIds: Set<string> = new Set<string>();
      let totalStrokes: number = 0;
      let indexedHandwritingPages: number = 0;
      for (let i = 0; i < pages.length; i++) {
        const pageId: string = await this.allocateFreshPageId(sourcePageIds, assignedPageIds);
        assignedPageIds.add(pageId);
        const pageInfo: PageInfo = {
          pageId: pageId, pageIndex: i, size: size, template: template, orientation: orientation,
          widthMm: orientation === PageOrientation.LANDSCAPE ? mm[1] : mm[0],
          heightMm: orientation === PageOrientation.LANDSCAPE ? mm[0] : mm[1],
        };
        await pageRepo.addImportedPage(note.id, pageInfo);
        await this.persistence.saveElements(note.id, pageInfo.pageId, pages[i].strokes, [],
          pages[i].elementOrder, pages[i].shapes);
        if (i < handwritingIndexPages.length && handwritingIndexPages[i].text.trim().length > 0) {
          await this.persistence.replaceImportedHandwritingText(
            note.id, pageInfo.pageId, handwritingIndexPages[i].text);
          indexedHandwritingPages++;
        }
        totalStrokes += pages[i].strokes.length;
      }

      const warnings: string[] = [];
      for (const warning of meta.warnings) {
        appendUnique(warnings, `metadata.plist：${warning}`);
      }
      if (!meta.ok) {
        appendUnique(warnings, meta.error.length > 0 ? meta.error : 'metadata.plist 无法解析');
      }
      for (const w of session.warnings) {
        appendUnique(warnings, w);
      }
      const missingAssets: string[] = summarizeNotabilityContentLoss(session.inventory);
      if (!meta.ok) {
        missingAssets.push('metadata.plist：关键元数据未恢复，已使用 Session/默认值补偿');
      } else if (meta.fieldsRecovered < meta.fieldsFound) {
        missingAssets.push(`metadata.plist：发现 ${meta.fieldsFound} 个字段，恢复 ${meta.fieldsRecovered} 个，` +
          `丢失 ${meta.fieldsFound - meta.fieldsRecovered} 个`);
      }
      if (session.unparsed.length > 0) {
        appendUnique(warnings, `未解析但不确认造成内容缺失：${session.unparsed.join('；')}`);
      }
      if (failedEntries.length > 0) {
        for (const failed of failedEntries) {
          missingAssets.push(`损坏或不支持的包条目：${failed}`);
        }
      }
      if (encryptedEntries.length > 0) {
        appendUnique(warnings, `受密码保护的条目：${encryptedEntries.join('、')}`);
      }
      if (importedAsCopy) {
        appendUnique(warnings, '原笔记 ID 已存在，已作为副本导入，未覆盖现有数据');
      }
      let message: string = `已导入 Notability 笔记「${note.title}」：` +
        `${pages.length} 页 / ${session.curves.length} 条笔迹 / ${session.shapes.length} 个识别形状`;
      if (indexedHandwritingPages > 0) {
        message += ` / ${indexedHandwritingPages} 页手写内容可搜索`;
      }
      if (missingAssets.length > 0) {
        message += `。未导入内容：${missingAssets.join('；')}`;
      }
      if (warnings.length > 0) {
        message += `。注意：${warnings.join('；')}`;
      }
      const partial: boolean = missingAssets.length > 0;
      console.info(`importNotability done: note=${note.id} pages=${pages.length} ` +
        `curves=${session.curves.length} shapes=${session.shapes.length} strokes=${totalStrokes} ` +
        `searchableHandwritingPages=${indexedHandwritingPages}`);
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id, title: note.title, pageCount: pages.length,
        missingAssets: missingAssets, warnings: warnings, message: message,
      };
    } catch (e) {
      console.error(`importNotability write failed: ${JSON.stringify(e)}`);
      const cleaned: boolean = await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: cleaned ? null : createdNoteId,
        title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: cleaned ? '写入数据库失败，导入未完成' :
          '写入数据库失败，且自动清理未完成' };
    } finally {
      release();
    }
  }

  private async mapImportedPageIds(pages: PageData[], forceRemap: boolean): Promise<Map<string, string>> {
    const sourceIds: Set<string> = new Set<string>();
    const assignedIds: Set<string> = new Set<string>();
    const mapping: Map<string, string> = new Map<string, string>();
    for (const page of pages) {
      sourceIds.add(page.pageId);
    }
    for (const page of pages) {
      const occupied: boolean = await this.pageIdExists(page.pageId);
      let targetId: string = page.pageId;
      if (importedPageNeedsRemap(forceRemap, occupied, assignedIds.has(targetId))) {
        targetId = await this.allocateFreshPageId(sourceIds, assignedIds);
      }
      mapping.set(page.pageId, targetId);
      assignedIds.add(targetId);
    }
    return mapping;
  }

  private async allocateImportedNoteId(preferredId: string, sourceExists: boolean): Promise<string> {
    if (!sourceExists) {
      return preferredId;
    }
    for (let attempt: number = 0; attempt < 64; attempt++) {
      const candidate: string = preferredId + '-import-' + generateId();
      if (!await this.noteIdExists(candidate)) {
        return candidate;
      }
    }
    throw new Error('failed to allocate a unique imported note identity');
  }

  private async allocateFreshPageId(sourceIds: Set<string>, assignedIds: Set<string>): Promise<string> {
    for (let attempt: number = 0; attempt < 64; attempt++) {
      const candidate: string = generateId();
      if (!sourceIds.has(candidate) && !assignedIds.has(candidate) && !await this.pageIdExists(candidate)) {
        return candidate;
      }
    }
    throw new Error('failed to allocate a unique imported page identity');
  }

  private async pageIdExists(pageId: string): Promise<boolean> {
    const rows = await this.db.getStore().querySql(
      'SELECT 1 FROM page_info WHERE page_id = ? LIMIT 1', [pageId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async noteIdExists(noteId: string): Promise<boolean> {
    // A permanently deleted id stays occupied forever (PermanentlyDeletedNote
    // tombstone): re-importing its package allocates a fresh id instead of
    // resurrecting the deleted note.
    const rows = await this.db.getStore().querySql(
      `SELECT 1 FROM note_meta WHERE id = ? LIMIT 1
       UNION ALL SELECT 1 FROM permanently_deleted_note WHERE note_id = ? LIMIT 1`,
      [noteId, noteId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  async removeImportedNote(noteId: string): Promise<boolean> {
    const release: MutexRelease = await NoteImporter.importMutex.lock();
    try {
      return await this.removeImportedNoteLocked(noteId);
    } finally {
      release();
    }
  }

  private async removeImportedNoteLocked(noteId: string): Promise<boolean> {
    try {
      // Rollback of a note that never became user-visible: no tombstone.
      await new NoteRepositoryImpl(this.db).deleteNote(noteId, false);
      return true;
    } catch (cleanupError) {
      console.error(`imported note cleanup failed: ${JSON.stringify(cleanupError)}`);
      try {
        if (!await this.noteIdExists(noteId)) {
          return true;
        }
      } catch (verifyError) {
        console.error(`imported note cleanup verification failed: ${JSON.stringify(verifyError)}`);
      }
      return false;
    }
  }

  private async removeFailedImport(noteId: string | null): Promise<boolean> {
    if (noteId === null) {
      return true;
    }
    // Both import writers call this while they already own importMutex.
    return await this.removeImportedNoteLocked(noteId);
  }
}

function generateId(): string {
  const timePart: string = Date.now().toString(36);
  const randPart: string = Math.random().toString(36).slice(2, 8);
  return timePart + randPart;
}

// 按后缀查条目：原版 Notability 把所有文件放在以笔记名命名的顶层目录下
function findEntryBySuffix(entries: ZipEntry[], suffix: string): ZipEntry | null {
  for (const e of entries) {
    if (e.name === suffix || e.name.endsWith('/' + suffix)) {
      return e;
    }
  }
  return null;
}

function validTimestamp(value: number, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : fallback;
}

function hasFailedSuffix(entries: string[], suffix: string): boolean {
  for (const name of entries) {
    if (name === suffix || name.endsWith('/' + suffix)) {
      return true;
    }
  }
  return false;
}

function appendUnique(values: string[], value: string): void {
  if (value.length > 0 && values.indexOf(value) < 0) {
    values.push(value);
  }
}

function sameAssetMetadata(left: OriginalAssetMetadata, right: OriginalAssetMetadata): boolean {
  if (left.assetHashBits.length !== right.assetHashBits.length ||
    left.fileSize !== right.fileSize || left.mimeType.toLowerCase() !== right.mimeType.toLowerCase()) {
    return false;
  }
  for (let index: number = 0; index < left.assetHashBits.length; index++) {
    if (left.assetHashBits[index] !== right.assetHashBits[index]) {
      return false;
    }
  }
  return true;
}

function packagePageInAsset(page: PageData): number | undefined {
  if (page.originalPageInAsset !== undefined) {
    return page.originalPageInAsset;
  }
  const background = page.background;
  return background !== undefined && background !== null &&
    background.pdf !== undefined && background.pdf !== null
    ? background.pdf.pageInAsset : undefined;
}

function countRecordingEntries(entries: ZipEntry[]): number {
  let count: number = 0;
  for (const entry of entries) {
    const lower: string = entry.name.toLowerCase();
    const isAudioExtension: boolean = lower.endsWith('.m4a') || lower.endsWith('.aac') ||
      lower.endsWith('.caf') || lower.endsWith('.wav') || lower.endsWith('.mp3');
    if (isAudioExtension &&
      (lower.indexOf('/recording') >= 0 || lower.indexOf('/audio') >= 0)) {
      count++;
    }
  }
  return count;
}

// Notability paperSize 字符串 → 内部枚举。未知值退化为 LETTER（实测样本为 letter）
function notabilityPaperSize(name: string): PaperSize {
  switch (name.toLowerCase()) {
    case 'a3':
      return PaperSize.A3;
    case 'a4':
      return PaperSize.A4;
    case 'a5':
      return PaperSize.A5;
    case 'a6':
      return PaperSize.A6;
    case 'a7':
      return PaperSize.A7;
    case 'legal':
      return PaperSize.LEGAL;
    case 'tabloid':
      return PaperSize.TABLOID;
    default:
      return PaperSize.LETTER;
  }
}

// lineStyle2 形如 "Lines:false:true:0.393701"，取冒号前的类型名。
// ⚠ 仅 "Lines" 经实测确认，其余取值按字面推测，未知一律退化为无格线
function notabilityPaperTemplate(lineStyle: string): PaperTemplate {
  const head: string = lineStyle.split(':')[0].toLowerCase();
  if (head === 'lines') {
    return PaperTemplate.LINES;
  }
  if (head === 'grid' || head === 'graph') {
    return PaperTemplate.GRID;
  }
  if (head === 'dots') {
    return PaperTemplate.DOTS;
  }
  return PaperTemplate.PLAIN;
}

function bytesToString(bytes: Uint8Array): string {
  const decoder = util.TextDecoder.create('utf-8');
  return decoder.decodeToString(bytes);
}

function readFileFully(fd: number, size: number): Uint8Array {
  if (!Number.isSafeInteger(size) || size < 0) {
    throw new Error(`无效文件长度：${size}`);
  }
  const output = new Uint8Array(size);
  let total: number = 0;
  while (total < size) {
    const requested: number = Math.min(FILE_READ_CHUNK_SIZE, size - total);
    const chunkBuffer = new ArrayBuffer(requested);
    const read: number = fileIo.readSync(fd, chunkBuffer);
    if (read <= 0 || read > requested) {
      throw new Error(`文件读取不完整：${total}/${size} bytes`);
    }
    output.set(new Uint8Array(chunkBuffer, 0, read), total);
    total += read;
  }
  return output;
}

function writeFileFully(path: string, data: Uint8Array): void {
  const file: fileIo.File = fileIo.openSync(path,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    let offset: number = 0;
    while (offset < data.length) {
      const end: number = Math.min(data.length, offset + FILE_READ_CHUNK_SIZE);
      const view: Uint8Array = data.subarray(offset, end);
      const chunk: ArrayBuffer = view.buffer.slice(view.byteOffset,
        view.byteOffset + view.byteLength) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, chunk);
      if (written <= 0 || written > view.byteLength) {
        throw new Error(`PDF staging write is incomplete: ${offset}/${data.length}`);
      }
      offset += written;
    }
    fileIo.fsyncSync(file.fd);
  } finally {
    fileIo.closeSync(file);
  }
}

function startsWithPdfMagic(data: Uint8Array): boolean {
  return data.length >= 5 && data[0] === 0x25 && data[1] === 0x50 &&
    data[2] === 0x44 && data[3] === 0x46 && data[4] === 0x2D;
}

function pickedFileName(uri: string): string {
  const tail: string = uri.substring(uri.lastIndexOf('/') + 1);
  try {
    const decoded: string = decodeURIComponent(tail);
    return decoded.length > 0 ? decoded : 'document.pdf';
  } catch (_e) {
    return tail.length > 0 ? tail : 'document.pdf';
  }
}

function pdfImportTitle(fileName: string): string {
  const base: string = fileName.toLowerCase().endsWith('.pdf') ?
    fileName.substring(0, fileName.length - 4) : fileName;
  return base.length > 0 ? base : '导入笔记';
}

// PDFKit 页尺寸读取 + Harmony 页面像素预算校验。原版 jv5 经 PDFTron 逐页取
// CropBox；PDFKit getWidth/getHeight 返回应用页内 /Rotate 后的可视尺寸，
// 与渲染侧 getPagePixelMap 同源，保持寄存器自洽。
function parseImportedPdfPageSizes(path: string): number[][] {
  const document: pdfService.PdfDocument = new pdfService.PdfDocument();
  try {
    const parsed: pdfService.ParseResult = document.loadDocument(path);
    if (parsed !== pdfService.ParseResult.PARSE_SUCCESS) {
      throw new Error(`PDFKit parse failed with result ${parsed}`);
    }
    const pageCount: number = document.getPageCount();
    if (!Number.isSafeInteger(pageCount) || pageCount <= 0 ||
      pageCount > PDF_IMPORT_MAX_PAGES) {
      throw new Error(`PDF page count is out of bounds: ${pageCount}`);
    }
    const sizes: number[][] = [];
    for (let index = 0; index < pageCount; index++) {
      const page: pdfService.PdfPage = document.getPage(index);
      const widthPt: number = page.getWidth();
      const heightPt: number = page.getHeight();
      if (!Number.isFinite(widthPt) || !Number.isFinite(heightPt) ||
        widthPt <= 0 || heightPt <= 0) {
        throw new Error(`PDF page ${index} reports invalid dimensions`);
      }
      pagePixelSize(widthPt * POINTS_TO_MM, heightPt * POINTS_TO_MM);
      sizes.push([widthPt, heightPt]);
    }
    return sizes;
  } finally {
    document.releaseDocument();
  }
}

interface ImportedImagePreparation {
  bytes: Uint8Array;
  mimeType: string;
  intrinsicWidth: number;
  intrinsicHeight: number;
}

function isImportedImageFileName(fileName: string): boolean {
  const lower: string = fileName.toLowerCase();
  for (const suffix of IMPORTED_IMAGE_SUFFIXES) {
    if (lower.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

function importedFileStemTitle(fileName: string): string {
  const dot: number = fileName.lastIndexOf('.');
  const base: string = dot > 0 ? fileName.substring(0, dot) : fileName;
  return base.length > 0 ? base : '导入笔记';
}

async function readImportedImageOrientation(source: image.ImageSource): Promise<string> {
  try {
    return await source.getImageProperty(image.PropertyKey.ORIENTATION, {
      index: 0, defaultValue: '1',
    });
  } catch (_error) {
    return '1';
  }
}

// 原版 vuh.b 等价物：先读编码尺寸（EXIF 方向换轴 → 本征尺寸），≤3000 直接
// 保留原字节与解码 mime；>3000 走幂二次采样 + 等比缩放 + WEBP_LOSSY q85
// 重写（重写后 EXIF 随容器丢失，本征尺寸取重写产物的实际像素域，与
// ep5「重写文件自身尺寸」语义一致）。
async function prepareImportedImageBytes(data: Uint8Array): Promise<ImportedImagePreparation> {
  const buffer: ArrayBuffer = data.buffer.slice(data.byteOffset,
    data.byteOffset + data.byteLength) as ArrayBuffer;
  const source: image.ImageSource = image.createImageSource(buffer);
  let pixelMap: image.PixelMap | null = null;
  let scaled: image.PixelMap | null = null;
  let packer: image.ImagePacker | null = null;
  try {
    const encodedInfo: image.ImageInfo = await source.getImageInfo();
    const encodedWidth: number = encodedInfo.size.width;
    const encodedHeight: number = encodedInfo.size.height;
    if (!Number.isSafeInteger(encodedWidth) || !Number.isSafeInteger(encodedHeight) ||
      encodedWidth <= 0 || encodedHeight <= 0 || encodedInfo.mimeType.length <= 6 ||
      !encodedInfo.mimeType.toLowerCase().startsWith('image/')) {
      throw new Error('imported image header is not a decodable image');
    }
    const orientation: string = await readImportedImageOrientation(source);
    const oriented: OriginalImagePixelDimensions | null = originalImageOrientedDimensions(
      encodedWidth, encodedHeight, orientation);
    if (oriented === null) {
      throw new Error('imported image orientation is invalid');
    }
    if (encodedWidth <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE &&
      encodedHeight <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE) {
      return { bytes: data, mimeType: encodedInfo.mimeType,
        intrinsicWidth: oriented.width, intrinsicHeight: oriented.height };
    }
    const plan = planOriginalImageDownscale(encodedWidth, encodedHeight);
    if (plan === null) {
      throw new Error('imported image exceeds the original normalization boundary');
    }
    pixelMap = await source.createPixelMap({ editable: false });
    const decodedInfo: image.ImageInfo = await pixelMap.getImageInfo();
    if (!originalImageDecodedDimensionsAreConsistent(encodedWidth, encodedHeight,
      orientation, decodedInfo.size.width, decodedInfo.size.height)) {
      throw new Error('imported image decode produced inconsistent dimensions');
    }
    const factor: number = plan.width / encodedWidth;
    scaled = await pixelMap.createScaledPixelMap(factor, factor);
    const scaledInfo: image.ImageInfo = await scaled.getImageInfo();
    packer = image.createImagePacker();
    const packed: ArrayBuffer = await packer.packToData(scaled, {
      format: 'image/webp', quality: IMAGE_IMPORT_WEBP_LOSSY_QUALITY,
      bufferSize: data.byteLength + 1,
    });
    const rewritten: Uint8Array = new Uint8Array(packed);
    if (rewritten.byteLength <= 0) {
      throw new Error('imported image normalization produced empty output');
    }
    return { bytes: rewritten, mimeType: 'image/webp',
      intrinsicWidth: scaledInfo.size.width, intrinsicHeight: scaledInfo.size.height };
  } finally {
    if (scaled !== null) {
      try { await scaled.release(); } catch (_e) { }
    }
    if (pixelMap !== null) {
      try { await pixelMap.release(); } catch (_e) { }
    }
    if (packer !== null) {
      try { await packer.release(); } catch (_e) { }
    }
    try { await source.release(); } catch (_e) { }
  }
}

// 原版 bvh.a + ip5 + kp5 等价物：fMin=min(1, 0.8·612/w, 0.8·792/h)，
// 位置居中、等比 scale=fitW/srcW；Java float 边界处按 Math.fround 逐步对齐。
function buildImportedImageElement(prepared: ImportedImagePreparation,
  metadata: OriginalAssetMetadata): ImageElement {
  const srcW: number = Math.fround(prepared.intrinsicWidth);
  const srcH: number = Math.fround(prepared.intrinsicHeight);
  const limitW: number = Math.fround(
    Math.fround(IMAGE_IMPORT_PAGE_WIDTH_PT) * Math.fround(IMAGE_IMPORT_PAGE_FRACTION));
  const limitH: number = Math.fround(
    Math.fround(IMAGE_IMPORT_PAGE_HEIGHT_PT) * Math.fround(IMAGE_IMPORT_PAGE_FRACTION));
  const fitMin: number = Math.fround(Math.min(1,
    Math.min(Math.fround(limitW / srcW), Math.fround(limitH / srcH))));
  const fitW: number = Math.fround(srcW * fitMin);
  const fitH: number = Math.fround(srcH * fitMin);
  const originX: number = Math.fround(
    Math.fround(IMAGE_IMPORT_PAGE_WIDTH_PT - fitW) / Math.fround(2));
  const originY: number = Math.fround(
    Math.fround(IMAGE_IMPORT_PAGE_HEIGHT_PT - fitH) / Math.fround(2));
  const scale: number = Math.fround(fitW / srcW);
  const element: ImageElement = {
    id: `imported-image-${generateId()}`,
    type: ElementType.IMAGE,
    transform: [
      scale, 0, originX,
      0, scale, originY,
      0, 0, 1,
    ],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    assetHash: originalAssetHashKey(metadata.assetHashBits),
    assetHashBits: metadata.assetHashBits.slice(),
    fileName: metadata.fileName,
    mimeType: metadata.mimeType,
    fileSize: metadata.fileSize,
    intrinsicWidth: prepared.intrinsicWidth,
    intrinsicHeight: prepared.intrinsicHeight,
    cropRect: null,
    blockWidth: prepared.intrinsicWidth,
    blockHeight: prepared.intrinsicHeight,
    rotationRadians: 0,
    corner: 0,
    textWrap: 0,
    enableCaption: false,
    webUrl: null,
    imageFlippedHorizontally: false,
    imageFlippedVertically: false,
    positionLocked: false,
  };
  element.bounds = imageBlockWorldBounds(element);
  return element;
}

function isImportedTextFileName(fileName: string): boolean {
  const lower: string = fileName.toLowerCase();
  for (const suffix of IMPORTED_TEXT_SUFFIXES) {
    if (lower.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

// 原版 te0/kci.b 文本导入的落块近似：INSERT_STRING 进页 richtext 寄存器
// 位 0 后由 cde 默认块承载 —— Harmony 以 Letter 页顶端、页宽的默认样式
// TextBlockElement 物化；块高沿用 TextBlockTool.updateText 的行高规则
// （lines*(fontSize+8)+上下内边距，最小 40），块宽 = 页宽。
function buildImportedTextElement(text: string): TextBlockElement {
  const lines: number = text.split('\n').length;
  const height: number = Math.fround(Math.max(40,
    lines * Math.fround(TEXT_IMPORT_FONT_SIZE + 8) +
    TEXT_IMPORT_TOP_INSET + TEXT_IMPORT_BOTTOM_INSET));
  const width: number = Math.fround(IMAGE_IMPORT_PAGE_WIDTH_PT);
  const element: TextBlockElement = {
    id: `imported-text-${generateId()}`,
    type: ElementType.TEXT,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    richText: text,
    characterStyleRuns: [],
    paragraphStyleRuns: [],
    textOrigin: { x: 0, y: 0 },
    blockWidth: width,
    blockHeight: height,
    rotationRadians: 0,
    contentLeftInset: TEXT_IMPORT_LEFT_INSET,
    contentTopInset: TEXT_IMPORT_TOP_INSET,
    contentRightInset: TEXT_IMPORT_RIGHT_INSET,
    contentBottomInset: TEXT_IMPORT_BOTTOM_INSET,
    fontSize: TEXT_IMPORT_FONT_SIZE,
    fontColor: TEXT_IMPORT_FONT_COLOR,
    corner: 0,
    textWrap: 0,
    enableCaption: false,
    paper: null,
    resizesWidthToFitText: false,
    positionLocked: false,
  };
  element.bounds = textBlockWorldBounds(element);
  return element;
}

function isImportedAudioFileName(fileName: string): boolean {
  const lower: string = fileName.toLowerCase();
  for (const suffix of Object.keys(IMPORTED_AUDIO_SUFFIX_MIME)) {
    if (lower.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

// 原版 nj3 MIME 映射；nj3Var.I 为空时回退 fsi.I(uri)，再退 'audio/*'
// —— Harmony 后缀未命中时直接回退 'audio/*'。
function audioMimeForFileName(fileName: string): string {
  const lower: string = fileName.toLowerCase();
  for (const suffix of Object.keys(IMPORTED_AUDIO_SUFFIX_MIME)) {
    if (lower.endsWith(suffix)) {
      return IMPORTED_AUDIO_SUFFIX_MIME[suffix];
    }
  }
  return 'audio/*';
}

// 原版 MediaMetadataRetriever.extractMetadata(9) 等价物：duration 毫秒，
// 任何失败兜底 0（与 cv5 的 j=0 一致）。
async function extractImportedAudioDuration(path: string): Promise<number> {
  let file: fileIo.File | null = null;
  let extractor: media.AVMetadataExtractor | null = null;
  try {
    file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    const size: number = fileIo.statSync(path).size;
    extractor = await media.createAVMetadataExtractor();
    extractor.fdSrc = { fd: file.fd, offset: 0, length: size };
    const metadata: media.AVMetadata = await extractor.fetchMetadata();
    const raw: string | undefined = metadata.duration;
    if (raw === undefined || !/^[0-9]+$/.test(raw)) {
      return 0;
    }
    const duration: number = Number(raw);
    return Number.isSafeInteger(duration) && duration >= 0 ? duration : 0;
  } catch (_error) {
    return 0;
  } finally {
    if (extractor !== null) {
      try { await extractor.release(); } catch (_e) { }
    }
    if (file !== null) {
      try { fileIo.closeSync(file); } catch (_e) { }
    }
  }
}
