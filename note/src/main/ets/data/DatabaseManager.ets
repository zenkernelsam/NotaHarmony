// T-017 数据库管理器（relationalStore 初始化 + DDL 执行）
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import {
  DB_NAME, DB_VERSION, DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_EDITOR_TOOLBOX_STATE,
  DDL_PAGE_ELEMENT_SNAPSHOT, DDL_ORIGINAL_LOCAL_INK_AUTHORING_GUARD,
  DDL_ORIGINAL_LOCAL_Z_ORDER_HISTORY,
  DDL_OPERATION_LOG, DDL_NOTE_ASSET,
  DDL_ORIGINAL_ASSET_CLOUD_STATE, DDL_ORIGINAL_PDF_FIELD_STATE,
  DDL_ORIGINAL_RECORDING_STATE, DDL_ORIGINAL_RECORDING_MODIFICATION,
  DDL_ORIGINAL_SHAPE_STATE, DDL_ORIGINAL_SHAPE_MODIFICATION,
  DDL_ORIGINAL_GROUP_STATE, DDL_ORIGINAL_GROUP_MODIFICATION,
  DDL_HISTORY_CHECKPOINT, DDL_HISTORY_CHECKPOINT_ACTION, DDL_HISTORY_CHECKPOINT_OPERATION,
  DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER, DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE,
  DDL_PAGE_DELETE_CHECKPOINT, DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH,
  DDL_LOCAL_EDITOR_IDENTITY, DDL_NOTE_SYNC_METADATA,
  DDL_SYNCED_OPERATION_INBOX, DDL_DEFERRED_SYNCED_OPERATION_BUNDLE,
  DDL_ORIGINAL_APPLIED_OPERATION_TIME,
  DDL_ORIGINAL_PAGE_INSERT_GROUP, DDL_ORIGINAL_PAGE_IDENTITY,
  DDL_ORIGINAL_PAGE_POSITION_GROUP, DDL_ORIGINAL_PAGE_POSITION,
  DDL_ORIGINAL_PAGE_POSITION_WINNER, DDL_ORIGINAL_PAGE_VISIBILITY_WINNER,
  DDL_ORIGINAL_PAGE_BACKGROUND_WINNER, DDL_ORIGINAL_NOTE_BACKGROUND_WINNER,
  DDL_ORIGINAL_PAGE_IN_ASSET_WINNER,
  DDL_ORIGINAL_NOTE_TITLE_WINNER,
  DDL_ORIGINAL_ELEMENT_Z_INDEX, DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER,
  DDL_ORIGINAL_DELETED_ENTITY,
  DDL_ORIGINAL_INK_STATE, DDL_ORIGINAL_INK_PATH_APPEND, DDL_ORIGINAL_BLOCK_STATE,
  DDL_ORIGINAL_TEXT_CHARACTER, DDL_ORIGINAL_TEXT_CHECKBOX_STATE,
  DDL_ORIGINAL_DELETED_PAGE, DDL_ORIGINAL_DELETED_PAGE_ELEMENT,
  DDL_ORIGINAL_DELETED_PAGE_SEARCH,
  DDL_INDEXES, MIGRATIONS,
} from './DatabaseHelper';
import {
  backfillOriginalAppliedOperationTimes, OriginalOperationTimeDatabase,
} from './OriginalOperationAudioTimeStore';
import { repairLegacyOriginalOutboundEnvelopes } from './OriginalOutboundOperationRepair';

interface AssetReferenceRepairRow {
  hash: string;
  raw: string;
}

export class DatabaseManager implements OriginalOperationTimeDatabase {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private applicationFilesDir: string = '';

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
    this.applicationFilesDir = context.filesDir;
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
        DDL_PAGE_ELEMENT_SNAPSHOT, DDL_ORIGINAL_LOCAL_INK_AUTHORING_GUARD,
        DDL_ORIGINAL_LOCAL_Z_ORDER_HISTORY, DDL_OPERATION_LOG,
        DDL_LOCAL_EDITOR_IDENTITY, DDL_NOTE_SYNC_METADATA,
        DDL_SYNCED_OPERATION_INBOX, DDL_DEFERRED_SYNCED_OPERATION_BUNDLE,
        DDL_ORIGINAL_APPLIED_OPERATION_TIME,
        DDL_HISTORY_CHECKPOINT, DDL_HISTORY_CHECKPOINT_ACTION, DDL_HISTORY_CHECKPOINT_OPERATION,
        DDL_NOTE_ASSET, DDL_NOTE_META, DDL_PAGE_INFO, DDL_FOLDER,
        DDL_ORIGINAL_ASSET_CLOUD_STATE, DDL_ORIGINAL_PDF_FIELD_STATE,
        DDL_ORIGINAL_RECORDING_STATE, DDL_ORIGINAL_RECORDING_MODIFICATION,
        DDL_ORIGINAL_SHAPE_STATE, DDL_ORIGINAL_SHAPE_MODIFICATION,
        DDL_ORIGINAL_GROUP_STATE, DDL_ORIGINAL_GROUP_MODIFICATION,
        DDL_ORIGINAL_PAGE_INSERT_GROUP, DDL_ORIGINAL_PAGE_IDENTITY,
        DDL_ORIGINAL_PAGE_POSITION_GROUP, DDL_ORIGINAL_PAGE_POSITION,
        DDL_ORIGINAL_PAGE_POSITION_WINNER, DDL_ORIGINAL_PAGE_VISIBILITY_WINNER,
        DDL_ORIGINAL_PAGE_BACKGROUND_WINNER, DDL_ORIGINAL_NOTE_BACKGROUND_WINNER,
        DDL_ORIGINAL_PAGE_IN_ASSET_WINNER,
        DDL_ORIGINAL_NOTE_TITLE_WINNER,
        DDL_ORIGINAL_ELEMENT_Z_INDEX,
        DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER, DDL_ORIGINAL_DELETED_ENTITY,
        DDL_ORIGINAL_INK_STATE, DDL_ORIGINAL_INK_PATH_APPEND, DDL_ORIGINAL_BLOCK_STATE,
        DDL_ORIGINAL_TEXT_CHARACTER, DDL_ORIGINAL_TEXT_CHECKBOX_STATE,
        DDL_ORIGINAL_DELETED_PAGE, DDL_ORIGINAL_DELETED_PAGE_ELEMENT,
        DDL_ORIGINAL_DELETED_PAGE_SEARCH,
        DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE, DDL_PAGE_DELETE_CHECKPOINT,
        DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH];
      let oldVersion: number = store.version;
      // Releases before v3 never persisted store.version. Infer their schema safely.
      if (oldVersion === 0 && hadClientOp) {
        oldVersion = hadPageId ? 3 : 2;
      }
      if (oldVersion > 0 && oldVersion < DB_VERSION) {
        await store.executeSql('PRAGMA foreign_keys = OFF');
        try {
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
            // user_version and schema must cross the crash boundary in the same transaction.
            store.version = DB_VERSION;
            await store.commit();
          } catch (e) {
            await store.rollBack();
            throw new Error(`Migration transaction failed: ${JSON.stringify(e)}`);
          }
        } finally {
          await store.executeSql('PRAGMA foreign_keys = ON');
        }
      }
      // Creating an evolving latest-schema table before historical ALTER migrations can make
      // those migrations fail with duplicate columns. Old stores migrate first; new stores and
      // post-migration stores are then completed idempotently from the canonical DDL.
      for (const ddl of ddlList) {
        await store.executeSql(ddl);
      }
      await store.beginTransaction();
      try {
        await repairLegacyOriginalOutboundEnvelopes(store);
        await backfillOriginalAppliedOperationTimes(store);
        await this.repairAssetNoteReferences(store);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`Operation audio-time backfill failed: ${JSON.stringify(e)}`);
      }
      await store.executeSql(`INSERT OR IGNORE INTO local_editor_identity(singleton, editor_id)
        VALUES (1, lower(hex(randomblob(16))))`);
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

  private async repairAssetNoteReferences(store: relationalStore.RdbStore): Promise<void> {
    const notes = await store.querySql('SELECT id FROM note_meta');
    const valid: Set<string> = new Set<string>();
    try {
      while (notes.goToNextRow()) {
        valid.add(notes.getString(notes.getColumnIndex('id')));
      }
    } finally {
      notes.close();
    }
    const assets = await store.querySql(
      'SELECT asset_hash, note_ids FROM note_asset');
    const assetRows: AssetReferenceRepairRow[] = [];
    try {
      while (assets.goToNextRow()) {
        const row: AssetReferenceRepairRow = {
          hash: assets.getString(assets.getColumnIndex('asset_hash')),
          raw: assets.getString(assets.getColumnIndex('note_ids')),
        };
        assetRows.push(row);
      }
    } finally {
      assets.close();
    }
    for (const assetRow of assetRows) {
      const hash: string = assetRow.hash;
      const raw: string = assetRow.raw;
      let parsed: string[];
      try {
        parsed = JSON.parse(raw) as string[];
      } catch (_error) {
        await this.removeInvalidAssetReference(store, hash);
        continue;
      }
      if (!Array.isArray(parsed)) {
        await this.removeInvalidAssetReference(store, hash);
        continue;
      }
      const filtered: string[] = [];
      let invalidEntries: boolean = false;
      for (const value of parsed) {
        if (typeof value !== 'string' || value.length === 0) {
          await this.removeInvalidAssetReference(store, hash);
          invalidEntries = true;
          break;
        }
        if (valid.has(value) && filtered.indexOf(value) < 0) {
          filtered.push(value);
        }
      }
      if (invalidEntries) {
        continue;
      }
      const predicates = new relationalStore.RdbPredicates('note_asset');
      predicates.equalTo('asset_hash', hash);
      if (filtered.length === 0) {
        await store.delete(predicates);
        continue;
      }
      let unchanged: boolean = filtered.length === parsed.length;
      if (unchanged) {
        for (let index: number = 0; index < filtered.length; index++) {
          if (filtered[index] !== parsed[index]) {
            unchanged = false;
            break;
          }
        }
      }
      if (unchanged) {
        continue;
      }
      if (await store.update({ 'note_ids': JSON.stringify(filtered) }, predicates) !== 1) {
        throw new Error(`asset reference repair affected an unexpected number of rows: ${hash}`);
      }
    }
  }

  private async removeInvalidAssetReference(store: relationalStore.RdbStore,
    hash: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', hash);
    if (await store.delete(predicates) !== 1) {
      throw new Error(`invalid asset removal affected an unexpected number of rows: ${hash}`);
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

  getFilesDir(): string {
    if (this.applicationFilesDir.length === 0) {
      throw new Error('DatabaseManager is not initialized with an application context');
    }
    return this.applicationFilesDir;
  }

  isInitialized(): boolean {
    return this.rdbStore !== null;
  }
}
