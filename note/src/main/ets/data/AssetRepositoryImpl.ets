// T-017 AssetRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { NoteAsset, AssetStatus } from '../core/model/AssetTypes';
import { AssetRepository } from './RepositoryInterfaces';
import { AsyncMutex } from './AsyncMutex';
import { DatabaseManager } from './DatabaseManager';

// Shared with NoteRepository.deleteNote(), which also mutates NoteAsset reference sets directly.
export const assetMutationMutex: AsyncMutex = new AsyncMutex();

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
      try {
        if (resultSet.goToNextRow()) {
          asset = this.rowToAsset(resultSet);
        }
      } finally {
        resultSet.close();
      }
      return asset;
    } catch (e) {
      throw new Error(`getAsset failed: ${JSON.stringify(e)}`);
    }
  }

  async saveAsset(asset: NoteAsset): Promise<void> {
    await assetMutationMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const existingNoteIds: string[] = await this.queryNoteIds(store, asset.assetHash);
        const mergedNoteIds: string[] = mergeNoteIds(existingNoteIds, asset.noteIds);
        await validateNoteReferences(store, mergedNoteIds);
        const bucket: relationalStore.ValuesBucket = {
          'asset_hash': asset.assetHash,
          'status': asset.status,
          'note_ids': JSON.stringify(mergedNoteIds),
          'file_size': asset.fileSize,
          'mime_type': asset.mimeType,
          'local_path': asset.localPath,
        };
        await store.insert('note_asset', bucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`saveAsset failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getAssetsByNote(noteId: string): Promise<NoteAsset[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_asset');
    try {
      const resultSet = await store.query(predicates);
      const assets: NoteAsset[] = [];
      try {
        while (resultSet.goToNextRow()) {
          const asset: NoteAsset = this.rowToAsset(resultSet);
          if (asset.noteIds.indexOf(noteId) >= 0) {
            assets.push(asset);
          }
        }
      } finally {
        resultSet.close();
      }
      return assets;
    } catch (e) {
      throw new Error(`getAssetsByNote failed: ${JSON.stringify(e)}`);
    }
  }

  async deleteAsset(hash: string): Promise<void> {
    const localPath: string | null = await assetMutationMutex.runExclusive(
      async (): Promise<string | null> => {
        const store: relationalStore.RdbStore = this.db.getStore();
        let path: string | null = null;
        await store.beginTransaction();
        try {
          const queryPredicates = new relationalStore.RdbPredicates('note_asset');
          queryPredicates.equalTo('asset_hash', hash);
          const resultSet = await store.query(queryPredicates, ['local_path']);
          try {
            if (resultSet.goToNextRow()) {
              const pathColumn: number = resultSet.getColumnIndex('local_path');
              path = resultSet.isColumnNull(pathColumn) ? null : resultSet.getString(pathColumn);
            }
          } finally {
            resultSet.close();
          }
          const predicates = new relationalStore.RdbPredicates('note_asset');
          predicates.equalTo('asset_hash', hash);
          await store.delete(predicates);
          await store.commit();
          return path;
        } catch (e) {
          await store.rollBack();
          throw new Error(`deleteAsset failed: ${JSON.stringify(e)}`);
        }
      });
    if (localPath !== null && localPath.length > 0) {
      unlinkAssetFile(localPath, this.db.getFilesDir());
    }
  }

  private rowToAsset(resultSet: relationalStore.ResultSet): NoteAsset {
    try {
      const noteIdsRaw: string = resultSet.getString(resultSet.getColumnIndex('note_ids'));
      const localPathColumn: number = resultSet.getColumnIndex('local_path');
      return {
        assetHash: resultSet.getString(resultSet.getColumnIndex('asset_hash')),
        status: resultSet.getLong(resultSet.getColumnIndex('status')) as AssetStatus,
        noteIds: parseAssetNoteIds(noteIdsRaw),
        fileSize: resultSet.getLong(resultSet.getColumnIndex('file_size')),
        mimeType: resultSet.getString(resultSet.getColumnIndex('mime_type')),
        localPath: resultSet.isColumnNull(localPathColumn) ? null : resultSet.getString(localPathColumn),
      };
    } catch (e) {
      throw new Error('rowToAsset failed: ' + JSON.stringify(e));
    }
  }

  private async queryNoteIds(store: relationalStore.RdbStore, hash: string): Promise<string[]> {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', hash);
    const resultSet = await store.query(predicates, ['note_ids']);
    try {
      if (!resultSet.goToNextRow()) {
        return [];
      }
      return parseAssetNoteIds(resultSet.getString(resultSet.getColumnIndex('note_ids')));
    } finally {
      resultSet.close();
    }
  }

}

export async function validateNoteReferences(store: relationalStore.RdbStore,
  noteIds: string[]): Promise<void> {
  for (const noteId of noteIds) {
    if (noteId.length === 0) {
      throw new Error('note_asset.note_ids contains an empty note ID');
    }
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    const rows = await store.query(predicates, ['id']);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error(`note_asset references a missing note: ${noteId}`);
      }
    } finally {
      rows.close();
    }
  }
}

export function parseAssetNoteIds(raw: string): string[] {
  const parsed = JSON.parse(raw) as string[];
  if (!Array.isArray(parsed)) {
    throw new Error('note_asset.note_ids is not an array');
  }
  const noteIds: string[] = [];
  for (let i: number = 0; i < parsed.length; i++) {
    const noteId: string = parsed[i];
    if (typeof noteId !== 'string' || noteId.length === 0) {
      throw new Error(`note_asset.note_ids contains an invalid value at index ${i}`);
    }
    if (noteIds.indexOf(noteId) < 0) {
      noteIds.push(noteId);
    }
  }
  return noteIds;
}

export function mergeNoteIds(existing: string[], incoming: string[]): string[] {
  const merged: string[] = [];
  const sources: string[][] = [existing, incoming];
  for (let sourceIndex: number = 0; sourceIndex < sources.length; sourceIndex++) {
    const source: string[] = sources[sourceIndex];
    for (let i: number = 0; i < source.length; i++) {
      const noteId: string = source[i];
      if (noteId.length > 0 && merged.indexOf(noteId) < 0) {
        merged.push(noteId);
      }
    }
  }
  return merged;
}

export function unlinkAssetFile(path: string, filesRoot?: string): void {
  if (filesRoot !== undefined && !isPathInside(filesRoot, path)) {
    console.error(`Asset file cleanup refused outside app files dir: ${path}`);
    return;
  }
  try {
    fileIo.unlinkSync(path);
  } catch (e) {
    const error = e as BusinessError;
    if (error.code !== 13900002) {
      console.error(`Asset file cleanup failed: path=${path}, error=${JSON.stringify(e)}`);
    }
  }
}

function isPathInside(root: string, candidate: string): boolean {
  const normalizedRoot: string = root.replace(/\\/g, '/').replace(/\/+$/, '');
  const normalizedCandidate: string = candidate.replace(/\\/g, '/');
  return normalizedCandidate.startsWith(normalizedRoot + '/') &&
    normalizedCandidate.indexOf('/../') < 0 && !normalizedCandidate.endsWith('/..');
}
