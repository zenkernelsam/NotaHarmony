// T-017 PageRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { PageRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { AsyncMutex, MutexRelease } from './AsyncMutex';

export class PageRepositoryImpl implements PageRepository {
  private static mutationMutex: AsyncMutex = new AsyncMutex();
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
      try {
        while (resultSet.goToNextRow()) {
          pages.push(this.rowToPage(resultSet));
        }
      } finally {
        resultSet.close();
      }
      return pages;
    } catch (e) {
      throw new Error(`getPages failed: ${JSON.stringify(e)}`);
    }
  }

  async addPage(noteId: string, page: PageInfo): Promise<PageInfo> {
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const countSet = await store.querySql(
          'SELECT IFNULL(MAX(page_index), -1) + 1 AS next_index FROM page_info WHERE note_id = ?', [noteId]);
        let pageIndex: number = 0;
        try {
          if (!countSet.goToFirstRow()) {
            throw new Error('page index query returned no row');
          }
          pageIndex = countSet.getLong(countSet.getColumnIndex('next_index'));
        } finally {
          countSet.close();
        }
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
        await store.commit();
        return {
          pageId: page.pageId,
          pageIndex: pageIndex,
          size: page.size,
          template: page.template,
          orientation: page.orientation,
          widthMm: page.widthMm,
          heightMm: page.heightMm,
        };
      } catch (e) {
        await store.rollBack();
        throw new Error(`addPage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async deletePage(noteId: string, pageId: string): Promise<void> {
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const elementPredicates = new relationalStore.RdbPredicates('page_element_snapshot');
        elementPredicates.equalTo('note_id', noteId);
        elementPredicates.equalTo('page_id', pageId);
        await store.delete(elementPredicates);
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', pageId);
        await store.delete(predicates);
        const pages: PageInfo[] = await this.queryPages(store, noteId);
        for (let i: number = 0; i < pages.length; i++) {
          await this.updatePageIndex(store, noteId, pages[i].pageId, i);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`deletePage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
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
      'page_index': page.pageIndex,
    };
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('page_id', page.pageId);
    try {
      await store.update(bucket, predicates);
    } catch (e) {
      throw new Error(`updatePage failed: ${JSON.stringify(e)}`);
    }
  }

  async reorderPages(noteId: string, pageIds: string[]): Promise<void> {
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        // Move every row out of the unique non-negative index range before assigning final positions.
        for (let i = 0; i < pageIds.length; i++) {
          await this.updatePageIndex(store, noteId, pageIds[i], -(i + 1));
        }
        for (let i = 0; i < pageIds.length; i++) {
          await this.updatePageIndex(store, noteId, pageIds[i], i);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`reorderPages failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  private rowToPage(resultSet: relationalStore.ResultSet): PageInfo {
    try {
      return {
        pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
        pageIndex: resultSet.getLong(resultSet.getColumnIndex('page_index')),
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

  private async queryPages(store: relationalStore.RdbStore, noteId: string): Promise<PageInfo[]> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.orderByAsc('page_index');
    const resultSet = await store.query(predicates);
    const pages: PageInfo[] = [];
    try {
      while (resultSet.goToNextRow()) {
        pages.push(this.rowToPage(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return pages;
  }

  private async updatePageIndex(store: relationalStore.RdbStore, noteId: string,
    pageId: string, pageIndex: number): Promise<void> {
    const bucket: relationalStore.ValuesBucket = { 'page_index': pageIndex };
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    await store.update(bucket, predicates);
  }
}
