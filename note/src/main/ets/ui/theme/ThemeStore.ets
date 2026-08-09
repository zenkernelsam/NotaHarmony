// T-038 主题状态管理（AppStorage 存储 themeMode，持久化由调用方 Preferences 负责）
import { LightTheme, DarkTheme, ThemeTokens, ThemeMode } from './EditorTheme';

export const THEME_MODE_KEY: string = 'themeMode';
export const THEME_SYSTEM_DARK_KEY: string = 'systemDark';
export const THEME_PREFERENCES_NAME: string = 'library_prefs';
export const THEME_PREFERENCE_KEY: string = 'theme_mode';

export class ThemeStore {
  // 初始化 AppStorage（默认 system）
  static init(): void {
    if (!AppStorage.has(THEME_MODE_KEY)) {
      AppStorage.setOrCreate(THEME_MODE_KEY, 'system');
    }
    if (!AppStorage.has(THEME_SYSTEM_DARK_KEY)) {
      AppStorage.setOrCreate(THEME_SYSTEM_DARK_KEY, false);
    }
  }

  static getMode(): ThemeMode {
    const v: string | undefined = AppStorage.get<string>(THEME_MODE_KEY);
    return (v as ThemeMode) ?? 'system';
  }

  static setMode(mode: ThemeMode): void {
    AppStorage.setOrCreate(THEME_MODE_KEY, mode);
  }

  static normalizeMode(value: string): ThemeMode {
    if (value === 'light' || value === 'dark') {
      return value;
    }
    return 'system';
  }

  // 记录系统是否深色（由 NoteAbility 统一更新）
  static setSystemDark(dark: boolean): void {
    AppStorage.setOrCreate(THEME_SYSTEM_DARK_KEY, dark);
  }

  // 解析 tokens：显式模式优先，system 跟随系统
  static resolve(mode: ThemeMode, systemDark: boolean): ThemeTokens {
    if (mode === 'dark' || (mode === 'system' && systemDark)) {
      return DarkTheme;
    }
    return LightTheme;
  }
}
