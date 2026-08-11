import { relationalStore } from '@kit.ArkData';
import { AssetStatus } from '../core/model/AssetTypes';
import { originalAssetHashKey, originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import { mergeNoteIds, parseAssetNoteIds } from './AssetRepositoryImpl';

interface StoredOriginalAssetRow {
  assetHash: string;
  status: number;
  noteIds: string[];
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}

export enum OriginalAssetReferenceConflict {
  NONE = 0,
  METADATA = 1,
  LOCAL_PATH = 2,
}

export async function mergeOriginalAssetReference(store: relationalStore.RdbStore, noteId: string,
  metadata: OriginalAssetMetadata): Promise<OriginalAssetReferenceConflict> {
  const storageHash: string = originalAssetStorageHash(metadata.assetHashBits);
  const legacyHash: string = originalAssetHashKey(metadata.assetHashBits);
  const rows: StoredOriginalAssetRow[] = await readRows(store, storageHash, legacyHash);
  for (const row of rows) {
    if (row.fileSize !== metadata.fileSize ||
      row.mimeType.toLowerCase() !== metadata.mimeType.toLowerCase()) {
      return OriginalAssetReferenceConflict.METADATA;
    }
  }
  if (rows.length === 0) {
    await store.insert('note_asset', {
      'asset_hash': storageHash,
      'status': AssetStatus.PENDING,
      'note_ids': JSON.stringify([noteId]),
      'file_size': metadata.fileSize,
      'mime_type': metadata.mimeType,
      'local_path': null,
    });
    return OriginalAssetReferenceConflict.NONE;
  }
  if (rows.length === 1) {
    const row: StoredOriginalAssetRow = rows[0];
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', row.assetHash);
    if (await store.update({
      'note_ids': JSON.stringify(mergeNoteIds(row.noteIds, [noteId])),
    }, predicates) !== 1) {
      throw new Error('original asset reference changed concurrently');
    }
    return OriginalAssetReferenceConflict.NONE;
  }
  const canonical: StoredOriginalAssetRow = rows.find(
    (row: StoredOriginalAssetRow): boolean => row.assetHash === storageHash) as StoredOriginalAssetRow;
  const legacy: StoredOriginalAssetRow = rows.find(
    (row: StoredOriginalAssetRow): boolean => row.assetHash === legacyHash) as StoredOriginalAssetRow;
  if (canonical.localPath !== null && legacy.localPath !== null &&
    canonical.localPath !== legacy.localPath) {
    return OriginalAssetReferenceConflict.LOCAL_PATH;
  }
  const preferred: StoredOriginalAssetRow = preferredRow(canonical, legacy);
  const predicates = new relationalStore.RdbPredicates('note_asset');
  predicates.equalTo('asset_hash', storageHash);
  if (await store.update({
    'status': preferred.status,
    'note_ids': JSON.stringify(mergeNoteIds(mergeNoteIds(canonical.noteIds, legacy.noteIds), [noteId])),
    'file_size': canonical.fileSize,
    'mime_type': canonical.mimeType,
    'local_path': preferred.localPath,
  }, predicates) !== 1) {
    throw new Error('original canonical asset changed concurrently');
  }
  const legacyPredicates = new relationalStore.RdbPredicates('note_asset');
  legacyPredicates.equalTo('asset_hash', legacyHash);
  if (await store.delete(legacyPredicates) !== 1) {
    throw new Error('original legacy asset changed concurrently');
  }
  return OriginalAssetReferenceConflict.NONE;
}

async function readRows(store: relationalStore.RdbStore, storageHash: string,
  legacyHash: string): Promise<StoredOriginalAssetRow[]> {
  const rows = storageHash === legacyHash ? await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
     FROM note_asset WHERE asset_hash = ?`, [storageHash]) : await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
     FROM note_asset WHERE asset_hash = ? OR asset_hash = ?`, [storageHash, legacyHash]);
  const result: StoredOriginalAssetRow[] = [];
  try {
    while (rows.goToNextRow()) {
      const pathColumn: number = rows.getColumnIndex('local_path');
      const status: number = rows.getLong(rows.getColumnIndex('status'));
      if (status < AssetStatus.PENDING || status > AssetStatus.FAILED) {
        throw new Error('original asset has an invalid status');
      }
      result.push({
        assetHash: rows.getString(rows.getColumnIndex('asset_hash')),
        status: status,
        noteIds: parseAssetNoteIds(rows.getString(rows.getColumnIndex('note_ids'))),
        fileSize: rows.getLong(rows.getColumnIndex('file_size')),
        mimeType: rows.getString(rows.getColumnIndex('mime_type')),
        localPath: rows.isColumnNull(pathColumn) ? null : rows.getString(pathColumn),
      });
    }
    return result;
  } finally {
    rows.close();
  }
}

function preferredRow(canonical: StoredOriginalAssetRow,
  legacy: StoredOriginalAssetRow): StoredOriginalAssetRow {
  if (canonical.localPath !== null) {
    return canonical;
  }
  if (legacy.localPath !== null) {
    return legacy;
  }
  const canonicalUnavailable: boolean = canonical.status === AssetStatus.PENDING ||
    canonical.status === AssetStatus.FAILED;
  const legacyAvailable: boolean = legacy.status !== AssetStatus.PENDING &&
    legacy.status !== AssetStatus.FAILED;
  return canonicalUnavailable && legacyAvailable ? legacy : canonical;
}
