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

let copiedPage: CopiedPagePayload | null = null;

export function storeCopiedPage(payload: CopiedPagePayload): void {
  copiedPage = payload;
}

export function copiedPagePayload(): CopiedPagePayload | null {
  return copiedPage;
}

export function hasCopiedPage(): boolean {
  return copiedPage !== null;
}

export function clearCopiedPage(): void {
  copiedPage = null;
}
