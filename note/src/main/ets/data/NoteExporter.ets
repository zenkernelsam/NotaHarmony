// T-027 笔记导出器：内部模型 → .note ZIP → 系统 picker 保存
// 参考 phase-4-backup-sync.md §2；依赖 T-026（ZipWriter/NotePackageSpec）
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ZipWriter } from './ZipArchive';
import {
  NoteManifest, PageData, serializeManifest, serializePage,
  NOTE_FORMAT, NOTE_FORMAT_VERSION, NOTE_SOURCE,
} from './NotePackageSpec';
import { NoteMeta, PageInfo, PaperSize } from '../core/model/NoteTypes';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { BackupSourcePackage } from './BackupBatchSpec';
import { PageElementKind } from '../core/model/PageElementOrder';

// 纸张尺寸 → 毫米（A3~TABLOID，与 Phase 3 默认一致）
export function paperSizeToMm(size: PaperSize): number[] {
  switch (size) {
    case PaperSize.A3:
      return [297.0, 420.0];
    case PaperSize.A4:
      return [210.0, 297.0];
    case PaperSize.A5:
      return [148.0, 210.0];
    case PaperSize.A6:
      return [105.0, 148.0];
    case PaperSize.A7:
      return [74.0, 105.0];
    case PaperSize.LETTER:
      return [215.9, 279.4];
    case PaperSize.LEGAL:
      return [215.9, 355.6];
    case PaperSize.TABLOID:
      return [279.4, 431.8];
    default:
      return [210.0, 297.0];
  }
}

export class NoteExporter {
  private db: DatabaseManager;
  private persistence: StrokePersistence;

  constructor(db: DatabaseManager, persistence: StrokePersistence) {
    this.db = db;
    this.persistence = persistence;
  }

  // 导出单个笔记为 .note Uint8Array；失败返回 null
  async exportNote(noteId: string): Promise<Uint8Array | null> {
    try {
      const noteRepo = new NoteRepositoryImpl(this.db);
      const note: NoteMeta | null = await noteRepo.getNote(noteId);
      if (note === null) {
        return null;
      }
      const pageRepo = new PageRepositoryImpl(this.db);
      const pages: PageInfo[] = await pageRepo.getPages(noteId);
      // manifest
      const manifest: NoteManifest = {
        format: NOTE_FORMAT,
        version: NOTE_FORMAT_VERSION,
        title: note.title,
        noteId: note.id,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        pageCount: pages.length,
        appVersion: '1.0.0',
        source: NOTE_SOURCE,
      };

      const writer = new ZipWriter();
      writer.addEntry('manifest.json', stringToBytes(serializeManifest(manifest)), true, note.updatedAt);
      writer.addDirectory('pages/', note.updatedAt);
      for (let i = 0; i < pages.length; i++) {
        const p: PageInfo = pages[i];
        const loaded = await this.persistence.loadElements(noteId, p.pageId);
        const elementObjects: PersistedElement[] = [];
        for (const element of loaded.elements) {
          if (element.kind === PageElementKind.STROKE) {
            elementObjects.push({ kind: 'stroke', data: element.data });
          } else if (element.kind === PageElementKind.TEXT) {
            elementObjects.push({ kind: 'text', data: element.data });
          } else {
            elementObjects.push({ kind: 'shape', data: element.data });
          }
        }
        const pageData: PageData = {
          pageId: p.pageId,
          pageIndex: i,
          paperSize: p.size,
          paperTemplate: p.template,
          orientation: p.orientation,
          elements: elementObjects,
        };
        writer.addEntry(`pages/page_${i}.json`, stringToBytes(serializePage(pageData)), true, note.updatedAt);
      }
      return await writer.build();
    } catch (e) {
      console.error(`exportNote failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  // 导出并保存到文件（系统 picker 保存对话框）；成功返回 true
  async exportToFile(context: common.UIAbilityContext, noteId: string, title: string): Promise<boolean> {
    let tmpPath: string = '';
    try {
      const data: Uint8Array | null = await this.exportNote(noteId);
      if (data === null) {
        return false;
      }
      // 1. 写入应用沙箱临时文件
      tmpPath = `${context.tempDir}/export_${Date.now()}.note`;
      const tmpFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(tmpFile.fd, data.buffer);
      fileIo.closeSync(tmpFile);

      // 2. 系统保存对话框
      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      // 同名笔记导出冲突规避：文件名附加时间戳
      saveOptions.newFileNames = [`${safeFileName(title)}_${Date.now()}.note`];
      saveOptions.fileSuffixChoices = ['Note 文件|.note'];
      const uris: string[] = await documentPicker.save(saveOptions);
      if (uris.length === 0) {
        console.info('exportToFile: user cancelled');
        return false;  // 用户取消
      }
      // 3. 复制到用户选择的位置
      const targetUri: string = uris[0];
      const srcFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(tmpPath);
      const size: number = stat.size;
      const bytes: Uint8Array = readFileFully(srcFile.fd, size);
      fileIo.closeSync(srcFile);
      const dstFile = fileIo.openSync(targetUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(dstFile.fd, bytes.buffer);
      fileIo.closeSync(dstFile);
      console.info(`exportToFile success: note=${noteId} bytes=${size}`);
      return true;
    } catch (e) {
      console.error(`exportToFile failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      // 4. 清理临时文件
      if (tmpPath.length > 0) {
        try {
          fileIo.unlinkSync(tmpPath);
        } catch (e) {
          // 忽略清理失败
        }
      }
    }
  }

  // 导出全部笔记；每篇导出前后复核内容 revision，变化时拒绝发布不一致批次。
  async exportAllNotes(): Promise<BackupSourcePackage[]> {
    const result: BackupSourcePackage[] = [];
    const noteRepo = new NoteRepositoryImpl(this.db);
    const notes: NoteMeta[] = await noteRepo.getAllNotes();
    for (const note of notes) {
      const revisionBefore: string = await this.persistence.getNoteRevisionSignature(note.id);
      const data: Uint8Array | null = await this.exportNote(note.id);
      if (data === null) {
        throw new Error(`exportAllNotes failed: note ${note.id} could not be exported`);
      }
      const revisionAfter: string = await this.persistence.getNoteRevisionSignature(note.id);
      const currentNote: NoteMeta | null = await noteRepo.getNote(note.id);
      if (revisionBefore !== revisionAfter || currentNote === null || currentNote.updatedAt !== note.updatedAt) {
        throw new Error(`exportAllNotes failed: note ${note.id} changed during export`);
      }
      result.push({ noteId: note.id, updatedAt: note.updatedAt, revision: revisionAfter, data: data });
    }
    return result;
  }
}

function safeFileName(title: string): string {
  const cleaned: string = title.replace(/[\\/:*?"<>|]/g, '_').trim();
  return cleaned.length > 0 ? cleaned : 'note';
}

function stringToBytes(text: string): Uint8Array {
  const encoder = new util.TextEncoder();
  return encoder.encodeInto(text);
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
