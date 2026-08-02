// T-017 AssetRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { NoteAsset, AssetStatus } from '../core/model/AssetTypes';
import { AssetRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';

export class AssetRepositoryImpl implements AssetRepository {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async getAsset(hash: string): Promise<NoteAsset | null> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', hash);
    try {
      const resultSet = await store.query(predicates);
      let asset: NoteAsset | null = null;
      if (resultSet.goToNextRow()) {
        asset = this.rowToAsset(resultSet);
      }
      resultSet.close();
      return asset;
    } catch (e) {
      console.error(`getAsset failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  async saveAsset(asset: NoteAsset): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'asset_hash': asset.assetHash,
      'status': asset.status,
      'note_ids': JSON.stringify(asset.noteIds),
      'file_size': asset.fileSize,
      'mime_type': asset.mimeType,
      'local_path': asset.localPath,
    };
    try {
      await store.insert('note_asset', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      console.error(`saveAsset failed: ${JSON.stringify(e)}`);
    }
  }

  async getAssetsByNote(noteId: string): Promise<NoteAsset[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.like('note_ids', '%' + noteId + '%');
    try {
      const resultSet = await store.query(predicates);
      const assets: NoteAsset[] = [];
      while (resultSet.goToNextRow()) {
        assets.push(this.rowToAsset(resultSet));
      }
      resultSet.close();
      return assets;
    } catch (e) {
      console.error(`getAssetsByNote failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  async deleteAsset(hash: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      const predicates = new relationalStore.RdbPredicates('note_asset');
      predicates.equalTo('asset_hash', hash);
      await store.delete(predicates);
    } catch (e) {
      console.error(`deleteAsset failed: ${JSON.stringify(e)}`);
    }
  }

  private rowToAsset(resultSet: relationalStore.ResultSet): NoteAsset {
    try {
      const noteIdsRaw: string = resultSet.getString(resultSet.getColumnIndex('note_ids'));
      let noteIds: string[] = [];
      try {
        const parsed = JSON.parse(noteIdsRaw) as string[];
        noteIds = parsed;
      } catch (e) {
        noteIds = [];
      }
      const localPathRaw: string = resultSet.getString(resultSet.getColumnIndex('local_path'));
      return {
        assetHash: resultSet.getString(resultSet.getColumnIndex('asset_hash')),
        status: resultSet.getLong(resultSet.getColumnIndex('status')) as AssetStatus,
        noteIds: noteIds,
        fileSize: resultSet.getLong(resultSet.getColumnIndex('file_size')),
        mimeType: resultSet.getString(resultSet.getColumnIndex('mime_type')),
        localPath: localPathRaw.length > 0 ? localPathRaw : null,
      };
    } catch (e) {
      throw new Error('rowToAsset failed: ' + JSON.stringify(e));
    }
  }
}
