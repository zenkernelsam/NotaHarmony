import { relationalStore } from '@kit.ArkData';
import { PageOrientation } from '../core/model/NoteTypes';
import {
  defaultOriginalBackgroundInfo, OriginalBackgroundInfo, OriginalPaperBackground,
  normalizeOriginalPaperSpacingInches, OriginalPaperLineType, originalPackedPaperSize,
  originalPaperLineTypes,
  originalPaperSizeFromPacked, sameOriginalPaperBackground, validateOriginalBackgroundInfo,
  validateOriginalPaperBackground,
} from '../core/model/OriginalPaperSettings';
import { DatabaseManager } from './DatabaseManager';
import { databaseWriteMutex } from './DatabaseWriteMutex';

export class OriginalPaperSettingsStore {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async listBackgroundInfos(): Promise<OriginalBackgroundInfo[]> {
    const stored: OriginalBackgroundInfo[] = await readAllBackgroundInfos(this.db.getStore());
    const result: OriginalBackgroundInfo[] = [];
    for (const paperLineType of originalPaperLineTypes()) {
      let resolved: OriginalBackgroundInfo | null = null;
      for (const info of stored) {
        if (info.paperLineType === paperLineType) {
          resolved = info;
          break;
        }
      }
      result.push(resolved === null ? defaultOriginalBackgroundInfo(paperLineType) : resolved);
    }
    return result;
  }

  async getBackgroundInfo(
    paperLineType: OriginalPaperLineType): Promise<OriginalBackgroundInfo> {
    // This also performs strict enum validation without exposing a second validator API.
    defaultOriginalBackgroundInfo(paperLineType);
    const stored: OriginalBackgroundInfo | null = await readBackgroundInfo(
      this.db.getStore(), paperLineType);
    return stored === null ? defaultOriginalBackgroundInfo(paperLineType) : stored;
  }

  // Mirrors rs0.f/ks0: Plain updates are a no-op. Other line types insert-or-update while
  // preserving the existing hasOptions bit; a missing row starts from gq0(type) = 0.5in/true.
  async saveSpacing(paperLineType: OriginalPaperLineType,
    spacingInches: number): Promise<OriginalBackgroundInfo> {
    defaultOriginalBackgroundInfo(paperLineType);
    if (paperLineType === OriginalPaperLineType.PLAIN) {
      return defaultOriginalBackgroundInfo(OriginalPaperLineType.PLAIN);
    }
    const requested: OriginalBackgroundInfo = validateOriginalBackgroundInfo({
      paperLineType: paperLineType,
      spacingInches: normalizeOriginalPaperSpacingInches(spacingInches),
      hasOptions: true,
    });
    return databaseWriteMutex.runExclusive(async (): Promise<OriginalBackgroundInfo> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const current: OriginalBackgroundInfo | null = await readBackgroundInfo(
          store, paperLineType);
        const updated: OriginalBackgroundInfo = {
          paperLineType: paperLineType,
          spacingInches: requested.spacingInches,
          hasOptions: current === null ? true : current.hasOptions,
        };
        if (current === null) {
          await store.insert('BackgroundInfo', backgroundInfoBucket(updated));
        } else {
          const predicates = new relationalStore.RdbPredicates('BackgroundInfo');
          predicates.equalTo('paperLineType', paperLineType);
          if (await store.update(backgroundInfoBucket(updated), predicates) !== 1) {
            throw new Error('original background spacing update affected an unexpected row count');
          }
        }
        await store.commit();
        return updated;
      } catch (error) {
        await store.rollBack();
        throw new Error(`save original background spacing failed: ${JSON.stringify(error)}`);
      }
    });
  }

  async listFavorites(): Promise<OriginalPaperBackground[]> {
    return readAllFavorites(this.db.getStore());
  }

  // Mirrors hge(add): compare complete l3a semantics and insert only when no equal row exists.
  async addFavorite(value: OriginalPaperBackground): Promise<OriginalPaperBackground> {
    const requested: OriginalPaperBackground = validateOriginalPaperBackground(value);
    return databaseWriteMutex.runExclusive(async (): Promise<OriginalPaperBackground> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const favorites: OriginalPaperBackground[] = await readAllFavorites(store);
        for (const favorite of favorites) {
          if (sameOriginalPaperBackground(favorite, requested)) {
            await store.commit();
            return favorite;
          }
        }
        const inserted: OriginalPaperBackground = favoriteWithId(requested, 0);
        const rowId: number = await store.insert('PaperBackground', favoriteBucket(inserted));
        if (!Number.isSafeInteger(rowId) || rowId <= 0 || rowId > 2147483647) {
          throw new Error('original paper favorite insert returned an invalid id');
        }
        const result: OriginalPaperBackground = favoriteWithId(inserted, rowId);
        await store.commit();
        return result;
      } catch (error) {
        await store.rollBack();
        throw new Error(`add original paper favorite failed: ${JSON.stringify(error)}`);
      }
    });
  }

  // Room exposes the update adapter as well. Require a persisted id and never reinterpret a
  // missing row as an insert, so callers cannot accidentally fork collection identity.
  async updateFavorite(value: OriginalPaperBackground): Promise<OriginalPaperBackground> {
    const requested: OriginalPaperBackground = validateOriginalPaperBackground(value);
    if (requested.id === 0) {
      throw new Error('original paper favorite update requires a persisted id');
    }
    return databaseWriteMutex.runExclusive(async (): Promise<OriginalPaperBackground> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const predicates = new relationalStore.RdbPredicates('PaperBackground');
        predicates.equalTo('id', requested.id);
        if (await store.update(favoriteBucket(requested), predicates) !== 1) {
          throw new Error('original paper favorite update affected an unexpected row count');
        }
        await store.commit();
        return requested;
      } catch (error) {
        await store.rollBack();
        throw new Error(`update original paper favorite failed: ${JSON.stringify(error)}`);
      }
    });
  }

  // Mirrors hge(remove): locate the semantically equal stored object first, then delete with
  // its Room-assigned id. Deleting the caller's transient id=0 would never remove the row.
  async removeFavorite(value: OriginalPaperBackground): Promise<boolean> {
    const requested: OriginalPaperBackground = validateOriginalPaperBackground(value);
    return databaseWriteMutex.runExclusive(async (): Promise<boolean> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const favorites: OriginalPaperBackground[] = await readAllFavorites(store);
        let stored: OriginalPaperBackground | null = null;
        for (const favorite of favorites) {
          if (sameOriginalPaperBackground(favorite, requested)) {
            stored = favorite;
            break;
          }
        }
        if (stored === null) {
          await store.commit();
          return false;
        }
        const predicates = new relationalStore.RdbPredicates('PaperBackground');
        predicates.equalTo('id', stored.id);
        if (await store.delete(predicates) !== 1) {
          throw new Error('original paper favorite delete affected an unexpected row count');
        }
        await store.commit();
        return true;
      } catch (error) {
        await store.rollBack();
        throw new Error(`remove original paper favorite failed: ${JSON.stringify(error)}`);
      }
    });
  }
}

async function readAllBackgroundInfos(
  store: relationalStore.RdbStore): Promise<OriginalBackgroundInfo[]> {
  const rows = await store.querySql(
    'SELECT paperLineType, spacing, hasOptions FROM BackgroundInfo');
  const result: OriginalBackgroundInfo[] = [];
  try {
    while (rows.goToNextRow()) {
      result.push(backgroundInfoFromRow(rows));
    }
    return result;
  } finally {
    rows.close();
  }
}

async function readBackgroundInfo(store: relationalStore.RdbStore,
  paperLineType: OriginalPaperLineType): Promise<OriginalBackgroundInfo | null> {
  const rows = await store.querySql(
    'SELECT paperLineType, spacing, hasOptions FROM BackgroundInfo WHERE paperLineType = ?',
    [paperLineType]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const result: OriginalBackgroundInfo = backgroundInfoFromRow(rows);
    if (rows.goToNextRow()) {
      throw new Error('stored original background info is not unique');
    }
    return result;
  } finally {
    rows.close();
  }
}

function backgroundInfoFromRow(rows: relationalStore.ResultSet): OriginalBackgroundInfo {
  const lineColumn: number = rows.getColumnIndex('paperLineType');
  const spacingColumn: number = rows.getColumnIndex('spacing');
  const optionsColumn: number = rows.getColumnIndex('hasOptions');
  const options: number = rows.getLong(optionsColumn);
  if (options !== 0 && options !== 1) {
    throw new Error('stored original background options flag is invalid');
  }
  return validateOriginalBackgroundInfo({
    paperLineType: parsePaperLineType(rows.getString(lineColumn)),
    spacingInches: rows.isColumnNull(spacingColumn) ? null : rows.getDouble(spacingColumn),
    hasOptions: options === 1,
  });
}

async function readAllFavorites(
  store: relationalStore.RdbStore): Promise<OriginalPaperBackground[]> {
  // CAST is essential: getLong() rounds these packed uint32-pair values in JS.
  const rows = await store.querySql(
    `SELECT id, CAST(paperSize AS TEXT) AS paperSizeText, paperOrientation,
            backgroundColor, legacyPaperIndex, paperLineType, spacing, hasOptions
       FROM PaperBackground ORDER BY id ASC`);
  const result: OriginalPaperBackground[] = [];
  try {
    while (rows.goToNextRow()) {
      const options: number = rows.getLong(rows.getColumnIndex('hasOptions'));
      if (options !== 0 && options !== 1) {
        throw new Error('stored original paper favorite options flag is invalid');
      }
      result.push(validateOriginalPaperBackground({
        id: rows.getLong(rows.getColumnIndex('id')),
        paperSize: originalPaperSizeFromPacked(
          rows.getString(rows.getColumnIndex('paperSizeText'))),
        paperOrientation: parsePaperOrientation(
          rows.getString(rows.getColumnIndex('paperOrientation'))),
        backgroundColor: nullableLong(rows, 'backgroundColor'),
        legacyPaperIndex: nullableLong(rows, 'legacyPaperIndex'),
        paperLineType: parsePaperLineType(rows.getString(rows.getColumnIndex('paperLineType'))),
        spacingInches: nullableDouble(rows, 'spacing'),
        hasOptions: options === 1,
      }));
    }
    return result;
  } finally {
    rows.close();
  }
}

function backgroundInfoBucket(
  value: OriginalBackgroundInfo): relationalStore.ValuesBucket {
  const normalized: OriginalBackgroundInfo = validateOriginalBackgroundInfo(value);
  return {
    'paperLineType': normalized.paperLineType,
    'spacing': normalized.spacingInches,
    'hasOptions': normalized.hasOptions ? 1 : 0,
  };
}

function favoriteBucket(value: OriginalPaperBackground): relationalStore.ValuesBucket {
  const normalized: OriginalPaperBackground = validateOriginalPaperBackground(value);
  const bucket: relationalStore.ValuesBucket = {
    // SQLite INTEGER affinity converts this exact decimal string without an ArkTS precision loss.
    'paperSize': originalPackedPaperSize(normalized.paperSize),
    'paperOrientation': normalized.paperOrientation === PageOrientation.PORTRAIT
      ? 'PORTRAIT' : 'LANDSCAPE',
    'backgroundColor': normalized.backgroundColor,
    'legacyPaperIndex': normalized.legacyPaperIndex,
    'paperLineType': normalized.paperLineType,
    'spacing': normalized.spacingInches,
    'hasOptions': normalized.hasOptions ? 1 : 0,
  };
  if (normalized.id > 0) {
    bucket['id'] = normalized.id;
  }
  return bucket;
}

function favoriteWithId(value: OriginalPaperBackground, id: number): OriginalPaperBackground {
  return validateOriginalPaperBackground({
    id: id,
    paperSize: value.paperSize,
    paperOrientation: value.paperOrientation,
    backgroundColor: value.backgroundColor,
    legacyPaperIndex: value.legacyPaperIndex,
    paperLineType: value.paperLineType,
    spacingInches: value.spacingInches,
    hasOptions: value.hasOptions,
  });
}

function parsePaperLineType(value: string): OriginalPaperLineType {
  switch (value) {
    case 'PLAIN':
      return OriginalPaperLineType.PLAIN;
    case 'LINES':
      return OriginalPaperLineType.LINES;
    case 'GRID':
      return OriginalPaperLineType.GRID;
    case 'DOTS':
      return OriginalPaperLineType.DOTS;
    default:
      throw new Error(`stored original paper line type is unknown: ${value}`);
  }
}

function parsePaperOrientation(value: string): PageOrientation {
  if (value === 'PORTRAIT') {
    return PageOrientation.PORTRAIT;
  }
  if (value === 'LANDSCAPE') {
    return PageOrientation.LANDSCAPE;
  }
  throw new Error(`stored original paper orientation is unknown: ${value}`);
}

function nullableLong(rows: relationalStore.ResultSet, name: string): number | null {
  const column: number = rows.getColumnIndex(name);
  return rows.isColumnNull(column) ? null : rows.getLong(column);
}

function nullableDouble(rows: relationalStore.ResultSet, name: string): number | null {
  const column: number = rows.getColumnIndex(name);
  return rows.isColumnNull(column) ? null : rows.getDouble(column);
}
