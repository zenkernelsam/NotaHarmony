import { relationalStore } from '@kit.ArkData';

// Original page entities share one note-wide identity namespace. Page/kind only locate and
// discriminate the payload; neither is part of entity identity.
export function reserveNotePageElementIds(reserved: Set<string>, pageElementIds: string[]): boolean {
  const pending: Set<string> = new Set<string>();
  for (const elementId of pageElementIds) {
    if (elementId.length === 0 || pending.has(elementId) || reserved.has(elementId)) {
      return false;
    }
    pending.add(elementId);
  }
  for (const elementId of pending) {
    reserved.add(elementId);
  }
  return true;
}

export async function assertLivePageElementIdsAvailable(store: relationalStore.RdbStore,
  noteId: string, pageId: string, pageElementIds: string[]): Promise<void> {
  if (noteId.length === 0 || pageId.length === 0) {
    throw new Error('page element identity requires note and page IDs');
  }
  const requested: Set<string> = new Set<string>();
  if (!reserveNotePageElementIds(requested, pageElementIds)) {
    throw new Error('page element identity list is invalid');
  }
  if (requested.size === 0) {
    return;
  }
  const rows = await store.querySql(
    `SELECT page_id, element_id FROM page_element_snapshot
     WHERE note_id = ? AND page_id <> ?`, [noteId, pageId]);
  try {
    while (rows.goToNextRow()) {
      const elementId: string = rows.getString(rows.getColumnIndex('element_id'));
      if (requested.has(elementId)) {
        throw new Error('page element identity already belongs to another page in this note');
      }
    }
  } finally {
    rows.close();
  }
}
