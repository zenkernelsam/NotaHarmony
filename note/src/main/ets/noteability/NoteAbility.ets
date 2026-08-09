import {
  AbilityConstant, Configuration as AbilityConfiguration, ConfigurationConstant, UIAbility, Want,
} from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import {
  ThemeStore, THEME_PREFERENCES_NAME, THEME_PREFERENCE_KEY,
} from '../ui/theme/ThemeStore';

const DOMAIN = 0x0000;

export default class NoteAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    ThemeStore.init();
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onConfigurationUpdate(newConfig: AbilityConfiguration): void {
    ThemeStore.setSystemDark(newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    this.restoreThemeAndLoadContent(windowStage).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Theme initialization failed. Cause: %{public}s', JSON.stringify(err));
      this.loadMainContent(windowStage);
    });
  }

  private async restoreThemeAndLoadContent(windowStage: window.WindowStage): Promise<void> {
    ThemeStore.setSystemDark(
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    try {
      const store: preferences.Preferences =
        await preferences.getPreferences(this.context, THEME_PREFERENCES_NAME);
      const savedMode: string = store.getSync(THEME_PREFERENCE_KEY, 'system') as string;
      ThemeStore.setMode(ThemeStore.normalizeMode(savedMode));
    } catch (err) {
      ThemeStore.setMode('system');
      hilog.error(DOMAIN, 'testTag', 'Failed to restore theme. Cause: %{public}s', JSON.stringify(err));
    }
    this.loadMainContent(windowStage);
  }

  private loadMainContent(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
