// T-017 PageRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { PageRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';

export class PageRepositoryImpl implements PageRepository {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async getPages(noteId: string): Promise<PageInfo[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.orderByAsc('page_index');
    try {
      const resultSet = await store.query(predicates);
      const pages: PageInfo[] = [];
      while (resultSet.goToNextRow()) {
        pages.push(this.rowToPage(resultSet));
      }
      resultSet.close();
      return pages;
    } catch (e) {
      console.error(`getPages failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  async addPage(noteId: string, page: PageInfo): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      // page_index 由现有页数决定（PageInfo 契约无 pageIndex 字段）
      // T-040 审核修复：用 max(page_index)+1，避免删除中间页后 rowCount 与既有 index 冲突
      const countPred = new relationalStore.RdbPredicates('page_info');
      countPred.equalTo('note_id', noteId);
      const countSet = await store.query(countPred);
      let pageIndex: number = 0;
      while (countSet.goToNextRow()) {
        const idx: number = countSet.getLong(countSet.getColumnIndex('page_index'));
        if (idx >= pageIndex) {
          pageIndex = idx + 1;
        }
      }
      countSet.close();
      const bucket: relationalStore.ValuesBucket = {
        'page_id': page.pageId,
        'note_id': noteId,
        'page_index': pageIndex,
        'size': page.size,
        'template': page.template,
        'orientation': page.orientation,
        'width_mm': page.widthMm,
        'height_mm': page.heightMm,
      };
      await store.insert('page_info', bucket);
    } catch (e) {
      console.error(`addPage failed: ${JSON.stringify(e)}`);
    }
  }

  async deletePage(noteId: string, pageId: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      const predicates = new relationalStore.RdbPredicates('page_info');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_id', pageId);
      await store.delete(predicates);
    } catch (e) {
      console.error(`deletePage failed: ${JSON.stringify(e)}`);
    }
  }

  async updatePage(page: PageInfo): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'size': page.size,
      'template': page.template,
      'orientation': page.orientation,
      'width_mm': page.widthMm,
      'height_mm': page.heightMm,
    };
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('page_id', page.pageId);
    try {
      await store.update(bucket, predicates);
    } catch (e) {
      console.error(`updatePage failed: ${JSON.stringify(e)}`);
    }
  }

  async reorderPages(noteId: string, pageIds: string[]): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      for (let i = 0; i < pageIds.length; i++) {
        const bucket: relationalStore.ValuesBucket = {
          'page_index': i,
        };
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', pageIds[i]);
        await store.update(bucket, predicates);
      }
    } catch (e) {
      console.error(`reorderPages failed: ${JSON.stringify(e)}`);
    }
  }

  private rowToPage(resultSet: relationalStore.ResultSet): PageInfo {
    try {
      return {
        pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
        size: resultSet.getLong(resultSet.getColumnIndex('size')),
        template: resultSet.getLong(resultSet.getColumnIndex('template')),
        orientation: resultSet.getLong(resultSet.getColumnIndex('orientation')),
        widthMm: resultSet.getDouble(resultSet.getColumnIndex('width_mm')),
        heightMm: resultSet.getDouble(resultSet.getColumnIndex('height_mm')),
      };
    } catch (e) {
      throw new Error('rowToPage failed: ' + JSON.stringify(e));
    }
  }
}
