// T-028 笔记导入器：.note ZIP → 内部模型 → 本地数据库
// 支持我方格式（完整恢复）+ 外部格式（尽力解析 + 友好提示）；损坏不崩溃
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ZipReader, ZipEntry, ZipParseResult } from './ZipArchive';
import { NoteManifest, PageData, parseManifest, parsePage } from './NotePackageSpec';
import { NoteMeta, PageInfo, PaperSize, PaperTemplate, PageOrientation } from '../core/model/NoteTypes';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { PageElementKind, PageElementRef } from '../core/model/PageElementOrder';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { paperSizeToMm } from './NoteExporter';
import {
  NotabilityMetadataParser, NotabilitySessionParser, NotabilityMetadata,
  NotabilitySession, NotabilityPageStrokes, DEFAULT_TARGET_PAGE_WIDTH_VP,
  summarizeNotabilityContentLoss,
} from './NotabilitySessionParser';

export enum ImportResult {
  SUCCESS = 0,
  UNSUPPORTED_FORMAT = 1,
  CORRUPTED = 2,
  PARTIAL = 3,       // 部分恢复
}

export interface ImportReport {
  result: ImportResult;
  noteId: string | null;    // 成功时返回新 noteId
  title: string | null;
  pageCount: number;
  missingAssets: string[];  // 未导入的内容/条目，供 UI 逐项呈现
  warnings: string[];       // 不造成内容缺失的诊断信息
  message: string;          // 用户可读的结果描述
}

export class NoteImporter {
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

  // 从文件导入（系统 picker 选择 .note 文件）
  async importFromFile(context: common.UIAbilityContext): Promise<ImportReport> {
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const selectOptions = new picker.DocumentSelectOptions();
      selectOptions.fileSuffixFilters = ['.note'];
      const uris: string[] = await documentPicker.select(selectOptions);
      if (uris.length === 0) {
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: '未选择文件' };
      }
      // 读取文件内容
      const uri: string = uris[0];
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(uri);
      const size: number = stat.size;
      if (size <= 0) {
        fileIo.closeSync(file);
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: '所选文件为空' };
      }
      const bytes: Uint8Array = readFileFully(file.fd, size);
      fileIo.closeSync(file);
      return await this.importFromData(bytes);
    } catch (e) {
      console.error(`importFromFile failed: ${JSON.stringify(e)}`);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '读取文件失败' };
    }
  }

  // 我方格式导入：先全量解析验证，再写库（事务性：验证失败不写库）
  private async importOurFormat(entries: ZipEntry[], manifest: NoteManifest,
    failedEntries: string[], encryptedEntries: string[]): Promise<ImportReport> {
    // === 阶段 1：全量解析验证 ===
    const parsedPages: PageData[] = [];
    let failedPages: number = 0;
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
      // 解析元素（跳过损坏条目，不致命）
      const elements: PersistedElement[] = [];
      for (const el of page.elements) {
        try {
          const parsed = el as PersistedElement;
          if (parsed !== null && typeof parsed === 'object' &&
            (parsed.kind === 'stroke' || parsed.kind === 'text')) {
            elements.push(parsed);
          }
        } catch (e) {
          // 跳过损坏元素
        }
      }
      parsedPages.push({ pageId: page.pageId, pageIndex: page.pageIndex,
        paperSize: page.paperSize, paperTemplate: page.paperTemplate,
        orientation: page.orientation, elements: elements });
    }
    if (parsedPages.length === 0 && manifest.pageCount > 0) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '未找到可解析的页面数据' };
    }

    // === 阶段 2：写库（创建新笔记，不覆盖已有）===
    let createdNoteId: string | null = null;
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const title: string = manifest.title !== null && manifest.title.length > 0 ? manifest.title : '导入笔记';
      const preferredId: string = manifest.noteId.length > 0 ? manifest.noteId : generateId();
      const importedAsCopy: boolean = await noteRepo.getNote(preferredId) !== null;
      const noteId: string = importedAsCopy ? preferredId + '-import-' + generateId() : preferredId;
      const now: number = Date.now();
      const createdAt: number = validTimestamp(manifest.createdAt, now);
      const updatedAt: number = validTimestamp(manifest.updatedAt, now);
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        noteId, title, createdAt, updatedAt, null);
      createdNoteId = note.id;

      let writtenPages: number = 0;
      let countStrokes: number = 0;
      let countTexts: number = 0;
      for (const page of parsedPages) {
        const mm: number[] = paperSizeToMm(page.paperSize as PaperSize);
        const landscape: boolean = page.orientation === PageOrientation.LANDSCAPE;
        const pageInfo: PageInfo = {
          pageId: importedAsCopy ? generateId() : page.pageId,
          pageIndex: page.pageIndex,
          size: page.paperSize as PaperSize,
          template: page.paperTemplate as PaperTemplate,
          orientation: page.orientation as PageOrientation,
          widthMm: landscape ? mm[1] : mm[0],
          heightMm: landscape ? mm[0] : mm[1],
        };
        await pageRepo.addPage(note.id, pageInfo);
        const pageStrokes: StrokeElementData[] = [];
        const pageTexts: TextBlockElement[] = [];
        const pageShapes: ShapeElement[] = [];
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
          }
        }
        await this.persistence.saveElements(
          note.id, pageInfo.pageId, pageStrokes, pageTexts, pageElementOrder, pageShapes);
        countStrokes += pageStrokes.length;
        countTexts += pageTexts.length;
        writtenPages++;
      }
      const partial: boolean = writtenPages < manifest.pageCount || failedPages > 0 || failedEntries.length > 0;
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
      for (const failed of failedEntries) {
        missingAssets.push(`损坏或不支持的包条目：${failed}`);
      }
      const warnings: string[] = [];
      if (importedAsCopy) {
        warnings.push('原笔记 ID 已存在，已作为副本导入，未覆盖现有数据');
      }
      console.info(`importOurFormat done: note=${note.id} pages=${writtenPages}/${manifest.pageCount} strokes=${countStrokes} texts=${countTexts}`);
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id,
        title: note.title,
        pageCount: writtenPages,
        missingAssets: missingAssets,
        warnings: warnings,
        message: partial
          ? `导入完成（部分：${writtenPages}/${manifest.pageCount} 页）${failureSummary}${encryptedSummary}${collisionSummary}`
          : `导入成功：${note.title}（${writtenPages} 页）${collisionSummary}`,
      };
    } catch (e) {
      console.error(`importOurFormat write failed: ${JSON.stringify(e)}`);
      await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '写入数据库失败，导入未完成' };
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
      try {
        const noteRepo = new NoteRepositoryImpl(this.db);
        const note: NoteMeta = await noteRepo.createNote(title, null);
        return { result: ImportResult.PARTIAL, noteId: note.id, title: note.title, pageCount: 1,
          missingAssets: ['笔记内容结构无法识别，仅恢复了标题'], warnings: [],
          message: `已导入外部包的基本信息（${note.title}），内容结构无法识别。内部文件：${fileList}` };
      } catch (e) {
        return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
          missingAssets: [], warnings: [],
          message: `外部包结构无法识别。内部文件：${fileList}` };
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
    const index: ZipEntry | null = findEntryBySuffix(entries, 'HandwritingIndex/index.plist');
    if (index !== null) {
      pageCountHint = NotabilitySessionParser.pageCountFromIndex(index.data, indexWarnings);
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
    const pages: NotabilityPageStrokes[] =
      NotabilitySessionParser.toStrokeElements(session, DEFAULT_TARGET_PAGE_WIDTH_VP);
    const scale: number = DEFAULT_TARGET_PAGE_WIDTH_VP / session.pageWidthDoc;

    // 5. 写库
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
      const importedAsCopy: boolean = await noteRepo.getNote(preferredId) !== null;
      const noteId: string = importedAsCopy ? preferredId + '-import-' + generateId() : preferredId;
      const now: number = Date.now();
      const createdAt: number = validTimestamp(meta.createdMillis, now);
      const updatedAt: number = validTimestamp(meta.modifiedMillis, now);
      const note: NoteMeta = await noteRepo.createNoteWithMeta(
        noteId, title, createdAt, updatedAt, null, meta.hasRecording);
      createdNoteId = note.id;

      const size: PaperSize = notabilityPaperSize(session.paper.paperSize);
      const template: PaperTemplate = notabilityPaperTemplate(session.paper.lineStyle);
      const orientation: PageOrientation =
        session.paper.paperOrientation.toLowerCase() === 'landscape'
          ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT;
      const mm: number[] = paperSizeToMm(size);
      let totalStrokes: number = 0;
      for (let i = 0; i < pages.length; i++) {
        const pageInfo: PageInfo = {
          pageId: generateId(), pageIndex: i, size: size, template: template, orientation: orientation,
          widthMm: orientation === PageOrientation.LANDSCAPE ? mm[1] : mm[0],
          heightMm: orientation === PageOrientation.LANDSCAPE ? mm[0] : mm[1],
        };
        await pageRepo.addPage(note.id, pageInfo);
        await this.persistence.saveElements(note.id, pageInfo.pageId, pages[i].strokes, []);
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
      if (missingAssets.length > 0) {
        message += `。未导入内容：${missingAssets.join('；')}`;
      }
      if (warnings.length > 0) {
        message += `。注意：${warnings.join('；')}`;
      }
      const partial: boolean = missingAssets.length > 0;
      console.info(`importNotability done: note=${note.id} pages=${pages.length} ` +
        `curves=${session.curves.length} shapes=${session.shapes.length} strokes=${totalStrokes}`);
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id, title: note.title, pageCount: pages.length,
        missingAssets: missingAssets, warnings: warnings, message: message,
      };
    } catch (e) {
      console.error(`importNotability write failed: ${JSON.stringify(e)}`);
      await this.removeFailedImport(createdNoteId);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        missingAssets: [], warnings: [],
        message: '写入数据库失败，导入未完成' };
    }
  }

  private async removeFailedImport(noteId: string | null): Promise<void> {
    if (noteId === null) {
      return;
    }
    try {
      await new NoteRepositoryImpl(this.db).deleteNote(noteId);
    } catch (cleanupError) {
      console.error(`failed import cleanup failed: ${JSON.stringify(cleanupError)}`);
    }
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
  const output = new Uint8Array(size);
  let total: number = 0;
  while (total < size) {
    const chunkBuffer = new ArrayBuffer(size - total);
    const read: number = fileIo.readSync(fd, chunkBuffer);
    if (read <= 0) {
      throw new Error(`文件读取不完整：${total}/${size} bytes`);
    }
    output.set(new Uint8Array(chunkBuffer, 0, read), total);
    total += read;
  }
  return output;
}
