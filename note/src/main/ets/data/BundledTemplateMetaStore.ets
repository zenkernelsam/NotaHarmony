// Phase 1402 捆绑模板收藏/最近使用/用量存储（原版 1.4.2 gaf/qsh Room 表）：
//   FavoritePaperTemplate(pdfAssetPath PK, favoritedAt)
//     —— 查询 ORDER BY favoritedAt DESC；
//   RecentPaperTemplate(pdfAssetPath PK, usedAt)
//     —— 查询 ORDER BY usedAt DESC，并经
//     DELETE … NOT IN (… ORDER BY usedAt DESC LIMIT 36) 裁剪至 36 条；
//   PaperTemplateUsage(templateUuid PK, useCount) —— 应用计数；
//   RecentGalleryTemplate —— 云端模板表，Harmony 无云端图库，fail-closed 不落库。
// 原版键为 pdfAssetPath（chc.e）；Harmony 以 rawfile 路径作等价键。
// pth.t(chc) → qc0 在应用成功后写 recents + usage；pth.o(chc,z) → yb6 写 favorites。
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AsyncMutex } from './AsyncMutex';

const STORE_NAME: string = 'bundledPaperTemplateMeta';
const FAVORITES_KEY: string = 'favoritePaperTemplates';
const RECENTS_KEY: string = 'recentPaperTemplates';
const USAGE_KEY: string = 'paperTemplateUsage';
// 原版 nsh case 110/120：RecentPaperTemplate / RecentGalleryTemplate 裁剪上限 36。
export const BUNDLED_TEMPLATE_RECENTS_LIMIT: number = 36;

export class BundledTemplateMetaStore {
  private static mutex: AsyncMutex = new AsyncMutex();
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  // ORDER BY favoritedAt DESC —— 数组首项即最近收藏。
  async getFavoritePaths(): Promise<string[]> {
    return this.getPathList(FAVORITES_KEY, 'getFavoritePaths');
  }

  // ORDER BY usedAt DESC —— 数组首项即最近应用。
  async getRecentPaths(): Promise<string[]> {
    return this.getPathList(RECENTS_KEY, 'getRecentPaths');
  }

  async getUsageCounts(): Promise<Map<string, number>> {
    return BundledTemplateMetaStore.mutex.runExclusive(
      async (): Promise<Map<string, number>> => {
        const counts: Map<string, number> = new Map();
        try {
          const store: preferences.Preferences =
            await preferences.getPreferences(this.context, STORE_NAME);
          const raw: preferences.ValueType = store.getSync(USAGE_KEY, '');
          if (typeof raw !== 'string' || raw.length === 0) {
            return counts;
          }
          const decoded: Object = JSON.parse(raw) as Object;
          if (decoded === null || typeof decoded !== 'object' ||
            Array.isArray(decoded)) {
            return counts;
          }
          const record = decoded as Record<string, number>;
          for (const key of Object.keys(record)) {
            const count: number = record[key];
            if (Number.isSafeInteger(count) && count > 0) {
              counts.set(key, count);
            }
          }
          return counts;
        } catch (e) {
          throw new Error(`getUsageCounts failed: ${JSON.stringify(e)}`);
        }
      });
  }

  // 原版 e83 INSERT OR REPLACE + favoritedAt=now；集合序即 favoritedAt DESC。
  async setFavorite(pdfAssetPath: string, favorite: boolean): Promise<void> {
    return BundledTemplateMetaStore.mutex.runExclusive(async (): Promise<void> => {
      const paths: string[] = await this.readPathList(FAVORITES_KEY);
      const index: number = paths.indexOf(pdfAssetPath);
      if (favorite && index < 0) {
        paths.unshift(pdfAssetPath);
      } else if (!favorite && index >= 0) {
        paths.splice(index, 1);
      } else {
        return;
      }
      await this.writePathList(FAVORITES_KEY, paths, 'setFavorite');
    });
  }

  // 原版 qc0：应用成功 → RecentPaperTemplate 上移 + 36 条裁剪 +
  // PaperTemplateUsage useCount+1（pth.t(chc) 携带 uuid）。
  async recordUsed(pdfAssetPath: string, templateUuid: string): Promise<void> {
    return BundledTemplateMetaStore.mutex.runExclusive(async (): Promise<void> => {
      const recents: string[] = await this.readPathList(RECENTS_KEY);
      const index: number = recents.indexOf(pdfAssetPath);
      if (index >= 0) {
        recents.splice(index, 1);
      }
      recents.unshift(pdfAssetPath);
      if (recents.length > BUNDLED_TEMPLATE_RECENTS_LIMIT) {
        recents.length = BUNDLED_TEMPLATE_RECENTS_LIMIT;
      }
      await this.writePathList(RECENTS_KEY, recents, 'recordUsed recents');

      const usage: Record<string, number> = await this.readUsageRecord();
      usage[templateUuid] = (Number.isSafeInteger(usage[templateUuid])
        ? usage[templateUuid] : 0) + 1;
      await this.writeUsageRecord(usage);
    });
  }

  private async getPathList(key: string, tag: string): Promise<string[]> {
    return BundledTemplateMetaStore.mutex.runExclusive(
      async (): Promise<string[]> => {
        return this.readPathList(key).catch((e: Object): string[] => {
          throw new Error(`${tag} failed: ${JSON.stringify(e)}`);
        });
      });
  }

  private async readPathList(key: string): Promise<string[]> {
    const store: preferences.Preferences =
      await preferences.getPreferences(this.context, STORE_NAME);
    const raw: preferences.ValueType = store.getSync(key, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return [];
    }
    const decoded: Object = JSON.parse(raw) as Object;
    if (!Array.isArray(decoded)) {
      return [];
    }
    const items: Object[] = decoded as Object[];
    const paths: string[] = [];
    for (const entry of items) {
      if (typeof entry === 'string' && entry.length > 0 &&
        paths.indexOf(entry as string) < 0) {
        paths.push(entry as string);
      }
    }
    return paths;
  }

  private async writePathList(key: string, paths: string[], tag: string): Promise<void> {
    const store: preferences.Preferences =
      await preferences.getPreferences(this.context, STORE_NAME);
    const hadPrevious: boolean = store.hasSync(key);
    const previous: preferences.ValueType = store.getSync(key, '');
    store.putSync(key, JSON.stringify(paths));
    try {
      await store.flush();
    } catch (e) {
      if (hadPrevious) {
        store.putSync(key, previous);
      } else {
        store.deleteSync(key);
      }
      try {
        await store.flush();
      } catch (rollbackError) {
        throw new Error(`${tag} commit and rollback failed: ${JSON.stringify(e)}; ` +
          `${JSON.stringify(rollbackError)}`);
      }
      throw new Error(`${tag} failed: ${JSON.stringify(e)}`);
    }
  }

  private async readUsageRecord(): Promise<Record<string, number>> {
    const store: preferences.Preferences =
      await preferences.getPreferences(this.context, STORE_NAME);
    const raw: preferences.ValueType = store.getSync(USAGE_KEY, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return {};
    }
    try {
      const decoded: Object = JSON.parse(raw) as Object;
      return (decoded !== null && typeof decoded === 'object' && !Array.isArray(decoded))
        ? decoded as Record<string, number> : {};
    } catch (_e) {
      return {};
    }
  }

  private async writeUsageRecord(usage: Record<string, number>): Promise<void> {
    const store: preferences.Preferences =
      await preferences.getPreferences(this.context, STORE_NAME);
    const hadPrevious: boolean = store.hasSync(USAGE_KEY);
    const previous: preferences.ValueType = store.getSync(USAGE_KEY, '');
    store.putSync(USAGE_KEY, JSON.stringify(usage));
    try {
      await store.flush();
    } catch (e) {
      if (hadPrevious) {
        store.putSync(USAGE_KEY, previous);
      } else {
        store.deleteSync(USAGE_KEY);
      }
      try {
        await store.flush();
      } catch (rollbackError) {
        throw new Error(`recordUsed usage commit and rollback failed: ` +
          `${JSON.stringify(e)}; ${JSON.stringify(rollbackError)}`);
      }
      throw new Error(`recordUsed usage failed: ${JSON.stringify(e)}`);
    }
  }
}
