// T-017 数据库管理器（relationalStore 初始化 + DDL 执行）
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import {
  DB_NAME, DB_VERSION, DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_EDITOR_TOOLBOX_STATE,
  DDL_PAGE_ELEMENT_SNAPSHOT, DDL_OPERATION_LOG, DDL_NOTE_ASSET,
  DDL_HISTORY_CHECKPOINT, DDL_HISTORY_CHECKPOINT_ACTION, DDL_HISTORY_CHECKPOINT_OPERATION,
  DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER, DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE,
  DDL_PAGE_DELETE_CHECKPOINT, DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH,
  DDL_INDEXES, MIGRATIONS,
} from './DatabaseHelper';

export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

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
    if (this.initPromise !== null) {
      return this.initPromise;
    }
    this.initPromise = this.openAndMigrate(context);
    try {
      await this.initPromise;
    } finally {
      this.initPromise = null;
    }
  }

  private async openAndMigrate(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    };
    let store: relationalStore.RdbStore;
    try {
      store = await relationalStore.getRdbStore(context, config);
    } catch (e) {
      throw new Error(`getRdbStore failed: ${JSON.stringify(e)}`);
    }
    const hadClientOp: boolean = await this.hasTable(store, 'client_op');
    const hadPageId: boolean = hadClientOp && await this.hasColumn(store, 'client_op', 'page_id');
    try {
      const ddlList: string[] = [DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_EDITOR_TOOLBOX_STATE,
        DDL_PAGE_ELEMENT_SNAPSHOT, DDL_OPERATION_LOG,
        DDL_HISTORY_CHECKPOINT, DDL_HISTORY_CHECKPOINT_ACTION, DDL_HISTORY_CHECKPOINT_OPERATION,
        DDL_NOTE_ASSET, DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER,
        DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE, DDL_PAGE_DELETE_CHECKPOINT,
        DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH];
      for (const ddl of ddlList) {
        await store.executeSql(ddl);
      }
      let oldVersion: number = store.version;
      // Releases before v3 never persisted store.version. Infer their schema safely.
      if (oldVersion === 0 && hadClientOp) {
        oldVersion = hadPageId ? 3 : 2;
      }
      if (oldVersion > 0 && oldVersion < DB_VERSION) {
        await store.beginTransaction();
        try {
          for (let target: number = oldVersion + 1; target <= DB_VERSION; target++) {
            const statements: string[] | undefined = MIGRATIONS[target];
            if (statements === undefined) {
              continue;
            }
            for (const sql of statements) {
              await store.executeSql(sql);
            }
          }
          await store.commit();
        } catch (e) {
          await store.rollBack();
          throw new Error(`Migration transaction failed: ${JSON.stringify(e)}`);
        }
      }
      for (const idx of DDL_INDEXES) {
        await store.executeSql(idx);
      }
      await store.executeSql('PRAGMA foreign_keys = ON');
      await this.verifyForeignKeys(store);
      store.version = DB_VERSION;
      this.rdbStore = store;
    } catch (e) {
      this.rdbStore = null;
      throw new Error(`Database migration failed: ${JSON.stringify(e)}`);
    }
  }

  private async hasTable(store: relationalStore.RdbStore, tableName: string): Promise<boolean> {
    const resultSet = await store.querySql(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?", [tableName]);
    const found: boolean = resultSet.goToFirstRow();
    resultSet.close();
    return found;
  }

  private async hasColumn(store: relationalStore.RdbStore, tableName: string, columnName: string): Promise<boolean> {
    const resultSet = await store.querySql(`PRAGMA table_info(${tableName})`);
    let found: boolean = false;
    while (resultSet.goToNextRow()) {
      if (resultSet.getString(resultSet.getColumnIndex('name')) === columnName) {
        found = true;
        break;
      }
    }
    resultSet.close();
    return found;
  }

  private async verifyForeignKeys(store: relationalStore.RdbStore): Promise<void> {
    const enabledSet = await store.querySql('PRAGMA foreign_keys');
    try {
      if (!enabledSet.goToFirstRow() || enabledSet.getLong(0) !== 1) {
        throw new Error('SQLite foreign key enforcement is disabled');
      }
    } finally {
      enabledSet.close();
    }
    const violations = await store.querySql('PRAGMA foreign_key_check');
    try {
      if (violations.goToFirstRow()) {
        const table: string = violations.getString(violations.getColumnIndex('table'));
        const rowId: number = violations.getLong(violations.getColumnIndex('rowid'));
        throw new Error(`foreign key violation in ${table} row ${rowId}`);
      }
    } finally {
      violations.close();
    }
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
