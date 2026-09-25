import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AsyncMutex } from './AsyncMutex';

const STORE_NAME: string = 'onboardingTooltipPreferences';
// 原版 hq9.j：datastore 键名逐位对齐，值为 pq9 枚举名的 Set<String>；
// Harmony preferences 以逗号连接串等价承载。
export const ONBOARDING_TOOLTIP_SEEN_KEY: string = 'onboardingTooltipSeen';

// 原版 pq9.java：引导气泡枚举。FIRST_TRANSCRIPT(pq9.M) 隶属 feature_learn
// 转写边界（ADR-0661 fail-closed），不在本链中。
export enum OnboardingTooltipKind {
  NEW_NOTE = 'NEW_NOTE',
  FIRST_TRAY_OPENED = 'FIRST_TRAY_OPENED',
  FIRST_INK_INSERT = 'FIRST_INK_INSERT',
  FIRST_IMAGE = 'FIRST_IMAGE',
  FIRST_RECORDING = 'FIRST_RECORDING',
  FIRST_TEXT = 'FIRST_TEXT',
  FIRST_IMPORT = 'FIRST_IMPORT',
  FIRST_UNDO_REDO = 'FIRST_UNDO_REDO',
  FIRST_HIGHLIGHTER = 'FIRST_HIGHLIGHTER',
  FIRST_NOTE_COMPLETED = 'FIRST_NOTE_COMPLETED',
  COMPACT_ORGANIZE = 'COMPACT_ORGANIZE',
}

// 原版 hq9.c：读取 Set<String> 后经 pq9.valueOf 容错映射（未知串仅记录并跳过）。
export function isOnboardingTooltipKind(kind: string): boolean {
  switch (kind) {
    case OnboardingTooltipKind.NEW_NOTE:
    case OnboardingTooltipKind.FIRST_TRAY_OPENED:
    case OnboardingTooltipKind.FIRST_INK_INSERT:
    case OnboardingTooltipKind.FIRST_IMAGE:
    case OnboardingTooltipKind.FIRST_RECORDING:
    case OnboardingTooltipKind.FIRST_TEXT:
    case OnboardingTooltipKind.FIRST_IMPORT:
    case OnboardingTooltipKind.FIRST_UNDO_REDO:
    case OnboardingTooltipKind.FIRST_HIGHLIGHTER:
    case OnboardingTooltipKind.FIRST_NOTE_COMPLETED:
    case OnboardingTooltipKind.COMPACT_ORGANIZE:
      return true;
    default:
      return false;
  }
}

export class OnboardingTooltipStore {
  private static mutex: AsyncMutex = new AsyncMutex();
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async getSeenKinds(): Promise<string[]> {
    try {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const value = store.getSync(ONBOARDING_TOOLTIP_SEEN_KEY, '');
      if (typeof value !== 'string' || value.length === 0) {
        return [];
      }
      const kinds: string[] = value.split(',');
      return kinds.filter((kind: string): boolean =>
        isOnboardingTooltipKind(kind));
    } catch (e) {
      throw new Error(`getSeenKinds failed: ${JSON.stringify(e)}`);
    }
  }

  async isSeen(kind: OnboardingTooltipKind): Promise<boolean> {
    const seen: string[] = await this.getSeenKinds();
    return seen.indexOf(kind) !== -1;
  }

  // 原版 js7："Got it" 关闭后将对应 pq9 写入 seen 集合并 flush。
  async markSeen(kind: OnboardingTooltipKind): Promise<void> {
    return OnboardingTooltipStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const seen: string[] = await this.getSeenKinds();
      if (seen.indexOf(kind) === -1) {
        seen.push(kind);
      }
      store.putSync(ONBOARDING_TOOLTIP_SEEN_KEY, seen.join(','));
      try {
        await store.flush();
      } catch (e) {
        throw new Error(`markSeen flush failed: ${JSON.stringify(e)}`);
      }
    });
  }
}
