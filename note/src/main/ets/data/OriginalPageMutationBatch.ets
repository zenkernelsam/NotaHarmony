import { relationalStore } from '@kit.ArkData';
import { OriginalSequenceIdentity } from './OperationIdentity';
import { SearchItemType } from './SearchItemType';
import { PageElementKind } from '../core/model/PageElementOrder';

export interface OriginalMutationPageTarget {
  page: OriginalSequenceIdentity;
  pageId: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface OriginalMutationPageEntry {
  target: OriginalMutationPageTarget;
  inkChanged: boolean;
  textChanged: boolean;
}

export class OriginalPageMutationBatch {
  private entries: Map<string, OriginalMutationPageEntry> =
    new Map<string, OriginalMutationPageEntry>();

  recordInk(target: OriginalMutationPageTarget): void {
    this.record(target, true, false);
  }

  /** Record visibility of an existing original entity without advancing yet. */
  recordEntity(target: OriginalMutationPageTarget, kind: number): void {
    // Search keeps Ink and Text Block indexes separately.  Shapes/groups do
    // not have a dedicated page text index, so they conservatively invalidate
    // the Ink side used by the original page search rebuild.
    if (!Number.isSafeInteger(kind) || kind < PageElementKind.STROKE ||
      kind > PageElementKind.MATH) {
      throw new Error('original batched entity kind is invalid');
    }
    this.record(target, kind !== PageElementKind.TEXT, kind === PageElementKind.TEXT);
  }

  recordBlock(target: OriginalMutationPageTarget, textChanged: boolean): void {
    this.record(target, false, textChanged);
  }

  async flush(store: relationalStore.RdbStore, noteId: string): Promise<void> {
    for (const entry of this.entries.values()) {
      const target: OriginalMutationPageTarget = entry.target;
      const predicates = new relationalStore.RdbPredicates(target.revisionTable);
      predicates.equalTo('note_id', noteId);
      if (target.archived) {
        predicates.equalTo('page_timestamp', target.page.timestamp);
        predicates.equalTo('page_site_id', target.page.siteId);
        predicates.equalTo('page_index', target.page.index);
      } else {
        predicates.equalTo('page_id', target.pageId);
      }
      predicates.equalTo('content_revision', target.revision);
      const values: relationalStore.ValuesBucket = {
        'content_revision': target.revision + 1,
      };
      if (target.archived && (entry.inkChanged || entry.textChanged)) {
        values['indexed_revision'] = null;
      }
      if (await store.update(values, predicates) !== 1) {
        throw new Error('original batched page revision changed concurrently');
      }
      await this.invalidateSearch(store, noteId, entry);
    }
  }

  private record(target: OriginalMutationPageTarget, inkChanged: boolean,
    textChanged: boolean): void {
    const key: string = pageKey(target);
    const existing: OriginalMutationPageEntry | undefined = this.entries.get(key);
    if (existing === undefined) {
      this.entries.set(key, {
        target: target, inkChanged: inkChanged, textChanged: textChanged,
      });
      return;
    }
    if (existing.target.pageId !== target.pageId ||
      existing.target.revisionTable !== target.revisionTable ||
      existing.target.revision !== target.revision ||
      existing.target.archived !== target.archived) {
      throw new Error('original batched page target changed during planning');
    }
    existing.inkChanged = existing.inkChanged || inkChanged;
    existing.textChanged = existing.textChanged || textChanged;
  }

  private async invalidateSearch(store: relationalStore.RdbStore, noteId: string,
    entry: OriginalMutationPageEntry): Promise<void> {
    const target: OriginalMutationPageTarget = entry.target;
    if (target.archived) {
      if (entry.inkChanged) {
        await store.executeSql(
          `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
           AND page_site_id = ? AND page_index = ? AND type = ?`,
          [noteId, target.page.timestamp, target.page.siteId, target.page.index,
            SearchItemType.INK]);
      }
      if (entry.textChanged) {
        await store.executeSql(
          `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
           AND page_site_id = ? AND page_index = ? AND type = ?`,
          [noteId, target.page.timestamp, target.page.siteId, target.page.index,
            SearchItemType.TEXT_BLOCK]);
      }
      return;
    }
    await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
      [noteId, target.pageId]);
    if (entry.inkChanged) {
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.INK]);
    }
    if (entry.textChanged) {
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.TEXT_BLOCK]);
    }
  }
}

function pageKey(target: OriginalMutationPageTarget): string {
  return `${target.page.timestamp}:${target.page.siteId}:${target.page.index}`;
}
