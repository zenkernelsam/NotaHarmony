// T-028 笔记导入器：.note ZIP → 内部模型 → 本地数据库
// 支持我方格式（完整恢复）+ 外部格式（尽力解析 + 友好提示）；损坏不崩溃
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ZipReader, ZipEntry } from './ZipArchive';
import { NoteManifest, PageData, parseManifest, parsePage } from './NotePackageSpec';
import { NoteMeta, PageInfo, PaperSize, PaperTemplate, PageOrientation } from '../core/model/NoteTypes';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { TextBlockElement } from '../core/model/ElementTypes';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { paperSizeToMm } from './NoteExporter';

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
        // 拆分元素写入 client_op
        const strokes: StrokeElementData[] = [];
        const textBlocks: TextBlockElement[] = [];
        for (const el of page.elements) {
          const typed = el as PersistedElement;
          if (typed.kind === 'stroke') {
            strokes.push(typed.data as StrokeElementData);
          } else if (typed.kind === 'text') {
            textBlocks.push(typed.data as TextBlockElement);
          }
        }
        countStrokes += strokes.length;
        countTexts += textBlocks.length;
        await this.persistence.saveElements(note.id, strokes, textBlocks);
        writtenPages++;
      }
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
}

function generateId(): string {
  const timePart: string = Date.now().toString(36);
  const randPart: string = Math.random().toString(36).slice(2, 8);
  return timePart + randPart;
}

function bytesToString(bytes: Uint8Array): string {
  const decoder = util.TextDecoder.create('utf-8');
  return decoder.decodeToString(bytes);
}
