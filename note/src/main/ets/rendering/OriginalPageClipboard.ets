import { PageBackground } from '../core/model/NoteTypes';
import { PageCopyPlan } from './UndoRedoManager';

// Original ae2 case 2 (Copy) / case 3 (Cut): the content manager serializes the
// selected pages through u5j.e and stores the op stream in the process-scoped
// page clipboard mg2.b = dg2 (CopiedPagesData { ops, pageCount }).  Paste reads
// the same record and replays it through the transcode apply (m1d.c0/lg2).
// Harmony stores the materialized payload — the effective page background plus
// the element plan — instead of the wire op stream; the stored plan is replayed
// through commitOriginalDuplicatePageContent exactly like a duplicate, so every
// paste re-issues fresh original operation identities just as the original's
// transcode does.  The record is in-memory only, matching mg2 (the original
// clipboard does not survive process death).
export interface CopiedPagePayload {
  noteId: string;
  sourcePageId: string;
  // Effective nz9 of the copied page (wz9.u + l7j.c single-page PDF collapse),
  // already cloned at copy time so later edits cannot mutate the clipboard.
  background: PageBackground | null;
  bookmarked: boolean;
  plan: PageCopyPlan;
}

// 原版 dg2 = CopiedPagesData(ops: ArrayList, pageCount)：页剪贴板本就是
// 多页记录（批量 Copy/Cut 一次写入全部选中页）。Harmony 对齐为有序
// payload 列表；单页路径等价于长度为 1 的列表。
let copiedPages: CopiedPagePayload[] = [];

export function storeCopiedPage(payload: CopiedPagePayload): void {
  copiedPages = [payload];
}

export function storeCopiedPages(payloads: CopiedPagePayload[]): void {
  copiedPages = payloads.slice();
}

export function copiedPagePayload(): CopiedPagePayload | null {
  return copiedPages.length === 0 ? null : copiedPages[0];
}

export function copiedPagePayloads(): CopiedPagePayload[] {
  return copiedPages;
}

export function hasCopiedPage(): boolean {
  return copiedPages.length > 0;
}

export function clearCopiedPage(): void {
  copiedPages = [];
}
