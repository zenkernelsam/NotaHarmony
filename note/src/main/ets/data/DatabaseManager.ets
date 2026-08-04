// T-017 数据库管理器（relationalStore 初始化 + DDL 执行）
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import {
  DB_NAME, DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_CLIENT_OP, DDL_NOTE_ASSET,
  DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER, DDL_INDEXES,
} from './DatabaseHelper';

export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {
  }

  static getInstance(): DatabaseManager {
    if (DatabaseManager.instance === null) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  // 初始化（在 NoteAbility.onCreate 或首次使用时调用）
  async initialize(context: common.Context): Promise<void> {
    if (this.rdbStore !== null) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    };
    let store: relationalStore.RdbStore;
    try {
      store = await relationalStore.getRdbStore(context, config);
    } catch (e) {
      console.error(`getRdbStore failed: ${JSON.stringify(e)}`);
      return;
    }
    // 执行全部 DDL（CREATE TABLE IF NOT EXISTS）
    const ddlList: string[] = [DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_CLIENT_OP,
      DDL_NOTE_ASSET, DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER];
    for (const ddl of ddlList) {
      try {
        await store.executeSql(ddl);
      } catch (e) {
        console.error(`DDL execute failed: ${JSON.stringify(e)}`);
      }
    }
    // 执行索引
    for (const idx of DDL_INDEXES) {
      try {
        await store.executeSql(idx);
      } catch (e) {
        console.error(`DDL index failed: ${JSON.stringify(e)}`);
      }
    }
    this.rdbStore = store;
  }

  // 获取实例（未初始化则抛异常）
  getStore(): relationalStore.RdbStore {
    if (this.rdbStore === null) {
      throw new Error('DatabaseManager not initialized. Call initialize() first.');
    }
    return this.rdbStore;
  }

  isInitialized(): boolean {
    return this.rdbStore !== null;
  }
}
