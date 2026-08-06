// T-028 笔记导入器：.note ZIP → 内部模型 → 本地数据库
// 支持我方格式（完整恢复）+ 外部格式（尽力解析 + 友好提示）；损坏不崩溃
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ZipReader, ZipEntry } from './ZipArchive';
import { NoteManifest, PageData, parseManifest, parsePage } from './NotePackageSpec';
import { NoteMeta, PageInfo, PaperSize, PaperTemplate, PageOrientation } from '../core/model/NoteTypes';
import { StrokeElementData, StrokePathPoint } from '../core/model/StrokeTypes';
import { CubicSegment } from '../core/model/GeometryTypes';
import { TextBlockElement } from '../core/model/ElementTypes';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { paperSizeToMm } from './NoteExporter';
import {
  NotabilityMetadataParser, NotabilitySessionParser, NotabilityMetadata,
  NotabilitySession, NotabilityPageStrokes, DEFAULT_TARGET_PAGE_WIDTH_VP,
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
        message: '文件为空或无法读取' };
    }
    // 1. 解析 ZIP（损坏 → CORRUPTED，不抛异常）
    const entries: ZipEntry[] | null = await ZipReader.parse(data);
    if (entries === null || entries.length === 0) {
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        message: '文件不是有效的 .note 包或已损坏' };
    }
    // 2. 查找 manifest.json → 我方格式
    const manifestEntry: ZipEntry | null = ZipReader.findEntry(entries, 'manifest.json');
    if (manifestEntry !== null) {
      const manifest: NoteManifest | null = parseManifest(bytesToString(manifestEntry.data));
      if (manifest === null) {
        return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
          message: 'manifest.json 无法解析或格式版本不受支持' };
      }
      return await this.importOurFormat(entries, manifest);
    }
    // 3. 无 manifest → 尝试外部格式
    return await this.importExternalFormat(entries);
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
          message: '所选文件为空' };
      }
      const buffer = new ArrayBuffer(size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return await this.importFromData(new Uint8Array(buffer));
    } catch (e) {
      console.error(`importFromFile failed: ${JSON.stringify(e)}`);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        message: '读取文件失败' };
    }
  }

  // 我方格式导入：先全量解析验证，再写库（事务性：验证失败不写库）
  private async importOurFormat(entries: ZipEntry[], manifest: NoteManifest): Promise<ImportReport> {
    // === 阶段 1：全量解析验证 ===
    const parsedPages: PageData[] = [];
    for (let i = 0; i < manifest.pageCount; i++) {
      const entry: ZipEntry | null = ZipReader.findEntry(entries, `pages/page_${i}.json`);
      if (entry === null) {
        continue;  // 缺页不致命（PARTIAL 语义）
      }
      const page: PageData | null = parsePage(bytesToString(entry.data));
      if (page === null) {
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
        message: '未找到可解析的页面数据' };
    }

    // === 阶段 2：写库（创建新笔记，不覆盖已有）===
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const pageRepo = new PageRepositoryImpl(this.db);
      const title: string = manifest.title !== null && manifest.title.length > 0 ? manifest.title : '导入笔记';
      const note: NoteMeta = await noteRepo.createNote(title, null);

      let writtenPages: number = 0;
      let countStrokes: number = 0;
      let countTexts: number = 0;
      // T-040 审核修复：收集全部页元素后一次性保存
      // （原实现每页调用 saveElements 先清后写 → 多页导入只剩最后一页）
      // 注：元素暂不分页存储（页维度架构修复在 T-041 规划中）
      const allStrokes: StrokeElementData[] = [];
      const allTexts: TextBlockElement[] = [];
      for (const page of parsedPages) {
        const mm: number[] = paperSizeToMm(page.paperSize as PaperSize);
        const pageInfo: PageInfo = {
          pageId: generateId(),
          size: page.paperSize as PaperSize,
          template: page.paperTemplate as PaperTemplate,
          orientation: page.orientation as PageOrientation,
          widthMm: mm[0],
          heightMm: mm[1],
        };
        await pageRepo.addPage(note.id, pageInfo);
        // 拆分元素收集（不落库）
        for (const el of page.elements) {
          const typed = el as PersistedElement;
          if (typed.kind === 'stroke') {
            allStrokes.push(typed.data as StrokeElementData);
          } else if (typed.kind === 'text') {
            allTexts.push(typed.data as TextBlockElement);
          }
        }
        writtenPages++;
      }
      countStrokes += allStrokes.length;
      countTexts += allTexts.length;
      await this.persistence.saveElements(note.id, allStrokes, allTexts);
      const partial: boolean = writtenPages < manifest.pageCount;
      console.info(`importOurFormat done: note=${note.id} pages=${writtenPages}/${manifest.pageCount} strokes=${countStrokes} texts=${countTexts}`);
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id,
        title: note.title,
        pageCount: writtenPages,
        message: partial
          ? `导入完成（部分：${writtenPages}/${manifest.pageCount} 页）`
          : `导入成功：${note.title}（${writtenPages} 页）`,
      };
    } catch (e) {
      console.error(`importOurFormat write failed: ${JSON.stringify(e)}`);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        message: '写入数据库失败，导入未完成' };
    }
  }

  // 外部格式（尽力解析）：扫描条目，尝试识别可解析内容
  private async importExternalFormat(entries: ZipEntry[]): Promise<ImportReport> {
    // 收集内部文件列表（供调试/提示）
    let fileList: string = '';
    for (const e of entries) {
      fileList += fileList.length === 0 ? e.name : ', ' + e.name;
    }
    // T-032 原版 Notability：条目都在以笔记名命名的顶层目录下（如 OP-AMP/Session.plist），
    // 所以只能按后缀匹配（ZipReader.findEntry 是全名精确匹配）
    const metaEntry: ZipEntry | null = findEntryBySuffix(entries, 'metadata.plist');
    const sessionEntry: ZipEntry | null = findEntryBySuffix(entries, 'Session.plist');
    if (metaEntry !== null && sessionEntry !== null) {
      return await this.importNotability(entries, metaEntry, sessionEntry, fileList);
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
          message: `已导入外部包的基本信息（${note.title}），内容结构无法识别。内部文件：${fileList}` };
      } catch (e) {
        return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
          message: `外部包结构无法识别。内部文件：${fileList}` };
      }
    }
    // 完全无法识别
    return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null, title: null, pageCount: 0,
      message: `不支持的 .note 格式（可能为原版 Notability 加密/FB 格式）。内部文件：${fileList}` };
  }

  // T-032 原版 Notability .note 导入
  private async importNotability(entries: ZipEntry[], metaEntry: ZipEntry,
    sessionEntry: ZipEntry, fileList: string): Promise<ImportReport> {
    // 1. metadata.plist：标题/UUID/日期。失败不致命，Session 里还有一份 name
    const meta: NotabilityMetadata = NotabilityMetadataParser.parse(metaEntry.data);

    // 2. 两个辅助信号：缩略图宽高比推导页高；HandwritingIndex 交叉校验页数
    let thumbAspect: number = 0;
    const thumb: ZipEntry | null = findEntryBySuffix(entries, 'thumb12x.png');
    if (thumb !== null) {
      thumbAspect = NotabilitySessionParser.pngAspect(thumb.data);
    }
    let pageCountHint: number = 0;
    const index: ZipEntry | null = findEntryBySuffix(entries, 'HandwritingIndex/index.plist');
    if (index !== null) {
      pageCountHint = NotabilitySessionParser.pageCountFromIndex(index.data);
    }

    // 3. Session.plist：笔画 + 形状
    const session: NotabilitySession =
      NotabilitySessionParser.parse(sessionEntry.data, thumbAspect, pageCountHint);
    if (!session.ok) {
      return { result: ImportResult.UNSUPPORTED_FORMAT, noteId: null,
        title: meta.noteName.length > 0 ? meta.noteName : null, pageCount: 0,
        message: `Notability 笔记解析失败：${session.error}。内部文件：${fileList}` };
    }

    // 4. 转内部模型
    const pages: NotabilityPageStrokes[] =
      NotabilitySessionParser.toStrokeElements(session, DEFAULT_TARGET_PAGE_WIDTH_VP);
    const scale: number = DEFAULT_TARGET_PAGE_WIDTH_VP / session.pageWidthDoc;
    const pageHeightVp: number = session.pageHeightDoc * scale;
    const allStrokes: StrokeElementData[] = flattenPages(pages, pageHeightVp);

    // 5. 写库
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
      const note: NoteMeta = await noteRepo.createNote(title, null);

      const size: PaperSize = notabilityPaperSize(session.paper.paperSize);
      const template: PaperTemplate = notabilityPaperTemplate(session.paper.lineStyle);
      const orientation: PageOrientation =
        session.paper.paperOrientation.toLowerCase() === 'landscape'
          ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT;
      const mm: number[] = paperSizeToMm(size);
      for (let i = 0; i < pages.length; i++) {
        const pageInfo: PageInfo = {
          pageId: generateId(), size: size, template: template, orientation: orientation,
          widthMm: mm[0], heightMm: mm[1],
        };
        await pageRepo.addPage(note.id, pageInfo);
      }
      // ⚠ 必须一次性写入：saveElements 会先删除该 noteId 的全部记录，逐页调用会互相清空
      await this.persistence.saveElements(note.id, allStrokes, []);

      const caveats: string[] = [];
      if (pages.length > 1) {
        caveats.push(`${pages.length} 页已纵向拼接为一张长画布（当前存储层无页维度）`);
      }
      for (const w of session.warnings) {
        caveats.push(w);
      }
      if (session.unparsed.length > 0) {
        caveats.push(`未解析内容：${session.unparsed.join('；')}`);
      }
      let message: string = `已导入 Notability 笔记「${note.title}」：` +
        `${pages.length} 页 / ${session.curves.length} 条笔迹 / ${session.shapes.length} 个识别形状`;
      if (caveats.length > 0) {
        message += `。注意：${caveats.join('；')}`;
      }
      const partial: boolean = allStrokes.length === 0 ||
        session.warnings.length > 0 || session.unparsed.length > 0;
      console.info(`importNotability done: note=${note.id} pages=${pages.length} ` +
        `curves=${session.curves.length} shapes=${session.shapes.length} strokes=${allStrokes.length}`);
      return {
        result: partial ? ImportResult.PARTIAL : ImportResult.SUCCESS,
        noteId: note.id, title: note.title, pageCount: pages.length, message: message,
      };
    } catch (e) {
      console.error(`importNotability write failed: ${JSON.stringify(e)}`);
      return { result: ImportResult.CORRUPTED, noteId: null, title: null, pageCount: 0,
        message: '写入数据库失败，导入未完成' };
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

// StrokePersistence 按 noteId 整存整取、没有页维度（T-025 MVP），NoteCanvasView 也是
// 一次性把全部元素加载到同一张画布。所以多页笔记只能纵向排开：第 i 页整体下移 i×页高。
// 否则各页会重叠。这是既有存储模型的限制，不是解析结果的限制——解析层保留了页分组。
function flattenPages(pages: NotabilityPageStrokes[], pageHeightVp: number): StrokeElementData[] {
  const out: StrokeElementData[] = [];
  for (const page of pages) {
    const dy: number = page.pageIndex * pageHeightVp;
    for (const s of page.strokes) {
      out.push(dy === 0 ? s : offsetStroke(s, dy));
    }
  }
  return out;
}

function offsetStroke(s: StrokeElementData, dy: number): StrokeElementData {
  const pathPoints: StrokePathPoint[] = [];
  for (const p of s.pathPoints) {
    pathPoints.push({
      position: { x: p.position.x, y: p.position.y + dy },
      widthFactor: p.widthFactor,
    });
  }
  const segments: CubicSegment[] = [];
  for (const c of s.cubicSegments) {
    segments.push({
      p0: { x: c.p0.x, y: c.p0.y + dy }, p1: { x: c.p1.x, y: c.p1.y + dy },
      p2: { x: c.p2.x, y: c.p2.y + dy }, p3: { x: c.p3.x, y: c.p3.y + dy },
    });
  }
  return {
    id: s.id,
    pathPoints: pathPoints,
    cubicSegments: segments,
    splatPoints: s.splatPoints,
    renderSpec: s.renderSpec,
    transform: s.transform,
    bounds: {
      left: s.bounds.left, top: s.bounds.top + dy,
      right: s.bounds.right, bottom: s.bounds.bottom + dy,
    },
    maskPath: s.maskPath,
    isFinished: s.isFinished,
  };
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
