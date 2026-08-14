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
import { NoteMeta, OriginalAssetMetadata, PageBackground, PageInfo, PaperSize } from '../core/model/NoteTypes';
import { effectivePageBackground } from '../core/model/PageBackgroundModel';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { PageRepositoryImpl } from './PageRepositoryImpl';
import { StrokePersistence, PersistedElement } from './StrokePersistence';
import { BackupSourcePackage } from './BackupBatchSpec';
import { PageElementKind } from '../core/model/PageElementOrder';
import { ImageElement } from '../core/model/ElementTypes';
import { NoteAsset } from '../core/model/AssetTypes';
import { AssetRepositoryImpl } from './AssetRepositoryImpl';
import {
  originalAssetPackageEntry, readVerifiedOriginalAsset, resolveOriginalAsset,
} from './ImageAssetPackageStore';
import {
  assertStableBackupSnapshot, BackupPreparationError, BackupSnapshotChangedError, BackupSnapshotEntry,
} from './BackupSnapshotGuard';

const FILE_WRITE_CHUNK_SIZE: number = 64 * 1024;

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
      const assets: Map<string, OriginalAssetMetadata> = new Map<string, OriginalAssetMetadata>();
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
          } else if (element.kind === PageElementKind.SHAPE) {
            elementObjects.push({ kind: 'shape', data: element.data });
          } else if (element.kind === PageElementKind.IMAGE) {
            elementObjects.push({ kind: 'image', data: element.data });
            const imageElement: ImageElement = element.data as ImageElement;
            this.addAsset(assets, {
              assetHashBits: imageElement.assetHashBits,
              fileName: imageElement.fileName,
              mimeType: imageElement.mimeType,
              fileSize: imageElement.fileSize,
            });
          } else if (element.kind === PageElementKind.MATH) {
            elementObjects.push({ kind: 'math', data: element.data });
          }
        }
        const background: PageBackground | null = effectivePageBackground(p);
        if (background !== null && background.pdf !== undefined && background.pdf !== null) {
          this.addAsset(assets, background.pdf.metadata);
        }
        const pageData: PageData = {
          pageId: p.pageId,
          pageIndex: i,
          paperSize: p.size,
          paperTemplate: p.template,
          orientation: p.orientation,
          widthMm: p.widthMm,
          heightMm: p.heightMm,
          // Harmony packages have no CRDT register history. Preserve the resolved
          // appearance so a nullable original page does not lose its note fallback.
          background: background,
          originalPageInAsset: p.originalPageInAsset,
          elements: elementObjects,
        };
        writer.addEntry(`pages/page_${i}.json`, stringToBytes(serializePage(pageData)), true, note.updatedAt);
      }
      if (assets.size > 0) {
        writer.addDirectory('assets/', note.updatedAt);
        const assetRepository: AssetRepositoryImpl = new AssetRepositoryImpl(this.db);
        for (const entry of assets.entries()) {
          const packagePath: string = entry[0];
          const metadata: OriginalAssetMetadata = entry[1];
          const asset: NoteAsset | null = await resolveOriginalAsset(assetRepository, metadata);
          if (asset === null) {
            throw new Error(`asset metadata is missing for ${packagePath}`);
          }
          writer.addEntry(packagePath, readVerifiedOriginalAsset(asset, metadata), false, note.updatedAt);
        }
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
    let tmpFile: fileIo.File | null = null;
    let srcFile: fileIo.File | null = null;
    let dstFile: fileIo.File | null = null;
    try {
      const data: Uint8Array | null = await this.exportNote(noteId);
      if (data === null) {
        return false;
      }
      // 1. 写入应用沙箱临时文件
      tmpPath = `${context.tempDir}/export_${Date.now()}.note`;
      tmpFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      writeFileFully(tmpFile.fd, data, 'temporary export');
      fileIo.fsyncSync(tmpFile.fd);
      fileIo.closeSync(tmpFile);
      tmpFile = null;

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
      srcFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(tmpPath);
      const size: number = stat.size;
      const bytes: Uint8Array = readFileFully(srcFile.fd, size);
      fileIo.closeSync(srcFile);
      srcFile = null;
      dstFile = fileIo.openSync(targetUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      writeFileFully(dstFile.fd, bytes, 'destination export');
      fileIo.fsyncSync(dstFile.fd);
      fileIo.closeSync(dstFile);
      dstFile = null;
      console.info(`exportToFile success: note=${noteId} bytes=${size}`);
      return true;
    } catch (e) {
      console.error(`exportToFile failed: ${JSON.stringify(e)}`);
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

  // 导出全部笔记；逐篇校验后再原子复核整库集合，拒绝跨时刻拼接的完成批次。
  async exportAllNotes(): Promise<BackupSourcePackage[]> {
    const result: BackupSourcePackage[] = [];
    await this.persistence.flushAll();
    const saveGeneration: number = this.persistence.getSaveEnqueueGeneration();
    if (this.persistence.hasPendingSaves()) {
      throw new BackupSnapshotChangedError('editor saves are still pending before backup export');
    }
    const expectedSnapshot: BackupSnapshotEntry[] =
      await this.persistence.getBackupRevisionSnapshot();
    for (const note of expectedSnapshot) {
      const revisionBefore: string = await this.persistence.getNoteRevisionSignature(note.noteId);
      if (revisionBefore !== note.revision) {
        throw new BackupSnapshotChangedError(`note ${note.noteId} changed before export`);
      }
      const data: Uint8Array | null = await this.exportNote(note.noteId);
      if (data === null) {
        throw new BackupPreparationError(`note ${note.noteId} could not be exported`);
      }
      const revisionAfter: string = await this.persistence.getNoteRevisionSignature(note.noteId);
      if (revisionBefore !== revisionAfter) {
        throw new BackupSnapshotChangedError(`note ${note.noteId} changed during export`);
      }
      result.push({
        noteId: note.noteId, updatedAt: note.updatedAt, revision: revisionAfter, data: data,
      });
    }
    if (this.persistence.getSaveEnqueueGeneration() !== saveGeneration ||
      this.persistence.hasPendingSaves()) {
      throw new BackupSnapshotChangedError('editor content changed while backup files were exported');
    }
    const currentSnapshot: BackupSnapshotEntry[] =
      await this.persistence.getBackupRevisionSnapshot();
    if (this.persistence.getSaveEnqueueGeneration() !== saveGeneration ||
      this.persistence.hasPendingSaves()) {
      throw new BackupSnapshotChangedError('editor content changed during final backup validation');
    }
    assertStableBackupSnapshot(expectedSnapshot, currentSnapshot);
    return result;
  }

  private addAsset(assets: Map<string, OriginalAssetMetadata>, metadata: OriginalAssetMetadata): void {
    const path: string = originalAssetPackageEntry(metadata);
    const existing: OriginalAssetMetadata | undefined = assets.get(path);
    if (existing !== undefined && (existing.fileSize !== metadata.fileSize ||
      existing.mimeType.toLowerCase() !== metadata.mimeType.toLowerCase())) {
      throw new Error(`asset metadata conflicts for ${path}`);
    }
    if (existing === undefined) {
      assets.set(path, metadata);
    }
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

// Uint8Array may be a view into a larger backing buffer; file writes must use
// only the exported byte range.
function exactArrayBuffer(bytes: Uint8Array): ArrayBuffer {
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
}

function writeFileFully(fd: number, bytes: Uint8Array, label: string): void {
  let total: number = 0;
  while (total < bytes.byteLength) {
    const end: number = Math.min(bytes.byteLength, total + FILE_WRITE_CHUNK_SIZE);
    const chunk: Uint8Array = bytes.subarray(total, end);
    const written: number = fileIo.writeSync(fd, exactArrayBuffer(chunk));
    if (written <= 0 || written > chunk.byteLength) {
      throw new Error(`${label} write made invalid progress: ${total}/${bytes.byteLength} bytes`);
    }
    total += written;
  }
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
