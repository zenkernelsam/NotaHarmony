// T-026 .note 包 JSON 结构定义（phase-4-backup-sync.md §2.2/§2.3）
// 纯类型 + 序列化工具：不 import 平台模块
// 注意：本文件不依赖 Phase 1 契约模型，elements 保持 object[]（JSON 原始结构，由调用方映射）

// .note 格式标识
export const NOTE_FORMAT: string = 'nota.note';
export const NOTE_FORMAT_VERSION: number = 1;
export const NOTE_SOURCE: string = 'NotaHarmony';

// manifest.json 结构（§2.2）
export interface NoteManifest {
  format: string;        // "nota.note"
  version: number;       // 1
  title: string;
  noteId: string;
  createdAt: number;
  updatedAt: number;
  pageCount: number;
  appVersion: string;
  source: string;        // "NotaHarmony"
}

// pages/page_N.json 结构（§2.3）
export interface PageData {
  pageId: string;
  pageIndex: number;
  paperSize: number;
  paperTemplate: number;
  orientation: number;
  elements: object[];    // NoteElement JSON 数组
}

export function isSupportedPageElementKind(kind: string): boolean {
  return kind === 'stroke' || kind === 'text' || kind === 'shape';
}

// 序列化 manifest
export function serializeManifest(manifest: NoteManifest): string {
  return JSON.stringify(manifest);
}

// 反序列化 manifest（格式校验：format/version 必须匹配，否则返回 null）
export function parseManifest(json: string): NoteManifest | null {
  try {
    const parsed = JSON.parse(json) as NoteManifest;
    if (parsed === null || typeof parsed !== 'object') {
      return null;
    }
    if (parsed.format !== NOTE_FORMAT || typeof parsed.version !== 'number' ||
      parsed.version > NOTE_FORMAT_VERSION) {
      return null;
    }
    // Keep older package readers explicit so a future format bump does not
    // accidentally invalidate existing backups.
    switch (parsed.version) {
      case 1:
        break;
      default:
        return null;
    }
    if (typeof parsed.title !== 'string' || typeof parsed.noteId !== 'string') {
      return null;
    }
    if (typeof parsed.pageCount !== 'number' || parsed.pageCount < 0) {
      return null;
    }
    return parsed;
  } catch (e) {
    return null;
  }
}

// 序列化页面
export function serializePage(page: PageData): string {
  return JSON.stringify(page);
}

// 反序列化页面（校验 pageId/pageIndex）
export function parsePage(json: string): PageData | null {
  try {
    const parsed = JSON.parse(json) as PageData;
    if (parsed === null || typeof parsed !== 'object') {
      return null;
    }
    if (typeof parsed.pageId !== 'string' || parsed.pageId.length === 0) {
      return null;
    }
    if (typeof parsed.pageIndex !== 'number' || parsed.pageIndex < 0) {
      return null;
    }
    if (!Array.isArray(parsed.elements)) {
      return null;
    }
    return parsed;
  } catch (e) {
    return null;
  }
}
